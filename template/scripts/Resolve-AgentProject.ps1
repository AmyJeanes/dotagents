[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Path = (Get-Location).Path,

    [switch] $Ensure,
    [switch] $Json,

    [string] $ProjectId,
    [switch] $RegisterAlias,

    [string] $ProjectsRoot,
    [string] $TasksRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectsRoot)) {
    $agentHome = Split-Path -Parent $PSScriptRoot
    $ProjectsRoot = Join-Path $agentHome 'projects'
}

if ([string]::IsNullOrWhiteSpace($TasksRoot)) {
    $agentHome = Split-Path -Parent $PSScriptRoot
    $TasksRoot = Join-Path $agentHome 'tasks'
}

if ($RegisterAlias -and -not $Ensure) {
    throw '-RegisterAlias requires -Ensure.'
}

if ($RegisterAlias -and [string]::IsNullOrWhiteSpace($ProjectId)) {
    throw '-RegisterAlias requires -ProjectId.'
}

function Get-CanonicalDirectory {
    param([string] $InputPath)

    $item = Get-Item -LiteralPath $InputPath -ErrorAction Stop
    if (-not $item.PSIsContainer) {
        $item = $item.Directory
    }

    $fullPath = [IO.Path]::GetFullPath($item.FullName)
    $root = [IO.Path]::GetPathRoot($fullPath)
    if (-not $fullPath.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
        $fullPath = $fullPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    }

    return $fullPath
}

function Get-NormalizedPath {
    param([string] $CanonicalPath)

    return $CanonicalPath.Replace([IO.Path]::AltDirectorySeparatorChar, [IO.Path]::DirectorySeparatorChar).ToLowerInvariant()
}

function Test-AbsolutePathValue {
    param([string] $PathValue)

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }
    if ([IO.Path]::IsPathRooted($PathValue)) {
        return $true
    }

    # A Windows drive ("D:\") or UNC ("\\host") path is not "rooted" under Linux .NET, yet a task
    # participant stored from a Windows session must still resolve when a WSL session reads it.
    return ($PathValue -match '^[A-Za-z]:[\\/]') -or ($PathValue -match '^\\\\')
}

function Get-NormalizedFullPath {
    param([string] $InputPath)

    if (-not (Test-AbsolutePathValue -PathValue $InputPath)) {
        throw "Task participant paths must be absolute: '$InputPath'"
    }

    if (-not [IO.Path]::IsPathRooted($InputPath)) {
        # Foreign-style absolute (a Windows path seen from Linux): normalize by string to the same
        # shape the other OS stored, without GetFullPath, which would prepend this session's CWD.
        return $InputPath.TrimEnd('\', '/').Replace('/', '\').ToLowerInvariant()
    }

    $fullPath = [IO.Path]::GetFullPath($InputPath)
    $root = [IO.Path]::GetPathRoot($fullPath)
    if (-not $fullPath.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
        $fullPath = $fullPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    }

    return Get-NormalizedPath -CanonicalPath $fullPath
}

function Find-GitWorktreeBoundary {
    param([string] $Directory)

    $current = Get-CanonicalDirectory -InputPath $Directory
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current '.git')) {
            return $current
        }

        $parent = [IO.Directory]::GetParent($current)
        if ($null -eq $parent) {
            return $null
        }
        $current = $parent.FullName
    }
}

function Get-GitValue {
    param(
        [string] $Directory,
        [string[]] $Arguments,
        [string] $SafeDirectory
    )

    if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }

    $gitArguments = @()
    if (-not [string]::IsNullOrWhiteSpace($SafeDirectory)) {
        $gitArguments += @('-c', "safe.directory=$SafeDirectory")
    }
    $gitArguments += @('-C', $Directory)
    $gitArguments += $Arguments

    $value = & git @gitArguments 2>$null
    if ($LASTEXITCODE -ne 0 -or $null -eq $value) {
        return $null
    }

    $text = ($value | Select-Object -First 1).ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text
}

function Remove-RemoteCredentials {
    param([string] $RemoteUrl)

    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
        return $null
    }

    return $RemoteUrl -replace '^(https?://)[^/@]+@', '$1'
}

function Get-ProjectSlug {
    param([string] $NormalizedPath)

    $rawParts = @($NormalizedPath -split '[:\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $parts = @()
    foreach ($part in $rawParts) {
        $clean = ($part -replace '[^a-z0-9]+', '-').Trim('-')
        if (-not [string]::IsNullOrWhiteSpace($clean)) {
            $parts += $clean
        }
    }

    if ($parts.Count -eq 0) {
        return 'project'
    }

    $fullSlug = ($parts -join '-')
    if ($fullSlug.Length -le 72) {
        return $fullSlug
    }

    $selected = [Collections.Generic.List[string]]::new()
    $prefix = $parts[0]
    for ($index = $parts.Count - 1; $index -ge 1; $index--) {
        $candidateParts = @($prefix) + @($parts[$index]) + @($selected)
        $candidate = $candidateParts -join '-'
        if ($candidate.Length -gt 72 -and $selected.Count -gt 0) {
            break
        }

        $selected.Insert(0, $parts[$index])
        if (($(@($prefix) + @($selected)) -join '-').Length -ge 72) {
            break
        }
    }

    $slug = (@($prefix) + @($selected)) -join '-'
    if ($slug.Length -gt 72) {
        $slug = $slug.Substring(0, 72).TrimEnd('-')
    }

    return $slug
}

function Get-ShortHash {
    param([string] $Value)

    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    $hash = [Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($hash).Substring(0, 12).ToLowerInvariant()
}

function Read-ProjectManifest {
    param([string] $ManifestPath)

    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1) {
        throw "Unsupported project manifest schema in $ManifestPath"
    }

    if ([string]::IsNullOrWhiteSpace($manifest.projectId) -or [string]::IsNullOrWhiteSpace($manifest.normalizedPath)) {
        throw "Invalid project manifest in $ManifestPath"
    }

    return $manifest
}

function Get-ManifestPaths {
    param([pscustomobject] $Manifest)

    $paths = @($Manifest.normalizedPath)
    $aliasesProperty = $Manifest.PSObject.Properties['pathAliases']
    if ($null -ne $aliasesProperty -and $null -ne $aliasesProperty.Value) {
        $paths += @($aliasesProperty.Value)
    }

    return @($paths | ForEach-Object { $_.ToString().ToLowerInvariant() } | Select-Object -Unique)
}

function Get-TaskEntrypointPath {
    param(
        [string] $TaskHome,
        [string] $Entrypoint,
        [string] $ManifestPath
    )

    if ([string]::IsNullOrWhiteSpace($Entrypoint) -or [IO.Path]::IsPathRooted($Entrypoint)) {
        throw "Task entrypoint must be a relative path in $ManifestPath"
    }

    $taskHomePath = [IO.Path]::GetFullPath($TaskHome).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $entrypointPath = [IO.Path]::GetFullPath((Join-Path $taskHomePath $Entrypoint))
    $taskPrefix = $taskHomePath + [IO.Path]::DirectorySeparatorChar
    if (-not $entrypointPath.StartsWith($taskPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Task entrypoint escapes its task directory in $ManifestPath"
    }

    if (-not (Test-Path -LiteralPath $entrypointPath -PathType Leaf)) {
        throw "Task entrypoint does not exist: $entrypointPath"
    }

    return $entrypointPath
}

function Get-RelatedTasks {
    param(
        [string] $RegistryRoot,
        [string[]] $ProjectPaths
    )

    if (-not (Test-Path -LiteralPath $RegistryRoot -PathType Container)) {
        return
    }

    foreach ($directory in Get-ChildItem -LiteralPath $RegistryRoot -Directory | Sort-Object Name) {
        $taskManifestPath = Join-Path $directory.FullName 'task.json'
        if (-not (Test-Path -LiteralPath $taskManifestPath -PathType Leaf)) {
            continue
        }

        $task = Get-Content -Raw -LiteralPath $taskManifestPath | ConvertFrom-Json
        if ($task.schemaVersion -ne 1) {
            throw "Unsupported task manifest schema in $taskManifestPath"
        }
        if ([string]::IsNullOrWhiteSpace($task.id) -or $task.id -cnotmatch '^[a-z0-9][a-z0-9-]*$') {
            throw "Invalid task ID in $taskManifestPath"
        }
        if ($task.id -cne $directory.Name) {
            throw "Task ID does not match its directory in $taskManifestPath"
        }
        if ([string]::IsNullOrWhiteSpace($task.title)) {
            throw "Task title is required in $taskManifestPath"
        }
        if ($task.status -cnotin @('active', 'paused', 'blocked')) {
            throw "Task status must be active, paused, or blocked in $taskManifestPath"
        }

        $entrypointPath = Get-TaskEntrypointPath -TaskHome $directory.FullName -Entrypoint $task.entrypoint -ManifestPath $taskManifestPath
        $participants = @($task.participants)
        if ($participants.Count -eq 0) {
            throw "At least one participant is required in $taskManifestPath"
        }

        $matchedParticipant = $null
        foreach ($participant in $participants) {
            if ($null -eq $participant -or [string]::IsNullOrWhiteSpace($participant.path)) {
                throw "Every task participant requires an absolute path in $taskManifestPath"
            }

            $participantPath = Get-NormalizedFullPath -InputPath $participant.path
            if ($participantPath -in $ProjectPaths) {
                if ($null -ne $matchedParticipant) {
                    throw "Task contains duplicate participants for this project in $taskManifestPath"
                }
                $matchedParticipant = $participant
            }
        }

        if ($null -eq $matchedParticipant) {
            continue
        }

        $role = $null
        $roleProperty = $matchedParticipant.PSObject.Properties['role']
        if ($null -ne $roleProperty -and -not [string]::IsNullOrWhiteSpace($roleProperty.Value)) {
            $role = $roleProperty.Value.ToString()
        }

        [pscustomobject][ordered]@{
            id = $task.id
            title = $task.title
            status = $task.status
            path = $directory.FullName
            entrypointPath = $entrypointPath
            role = $role
        }
    }
}

function Write-NewUtf8File {
    param(
        [string] $FilePath,
        [string] $Content
    )

    if (Test-Path -LiteralPath $FilePath) {
        return
    }

    $tempPath = "$FilePath.$PID.$([guid]::NewGuid().ToString('N')).tmp"
    [IO.File]::WriteAllText($tempPath, $Content, [Text.UTF8Encoding]::new($false))
    try {
        [IO.File]::Move($tempPath, $FilePath, $false)
    }
    catch [IO.IOException] {
        if (-not (Test-Path -LiteralPath $FilePath)) {
            throw
        }
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

function Write-ReplacedUtf8File {
    param(
        [string] $FilePath,
        [string] $Content
    )

    $tempPath = "$FilePath.$PID.$([guid]::NewGuid().ToString('N')).tmp"
    [IO.File]::WriteAllText($tempPath, $Content, [Text.UTF8Encoding]::new($false))
    try {
        [IO.File]::Move($tempPath, $FilePath, $true)
    }
    finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }
    }
}

$inputDirectory = Get-CanonicalDirectory -InputPath $Path
$gitBoundary = Find-GitWorktreeBoundary -Directory $inputDirectory
$gitRootValue = Get-GitValue -Directory $inputDirectory -Arguments @('rev-parse', '--show-toplevel') -SafeDirectory $gitBoundary
$isGitWorktree = -not [string]::IsNullOrWhiteSpace($gitRootValue)
$canonicalPath = if ($isGitWorktree) { Get-CanonicalDirectory -InputPath $gitRootValue } else { $inputDirectory }
$normalizedPath = Get-NormalizedPath -CanonicalPath $canonicalPath

$originUrl = $null
if ($isGitWorktree) {
    $originUrl = Remove-RemoteCredentials -RemoteUrl (Get-GitValue -Directory $canonicalPath -Arguments @('remote', 'get-url', 'origin') -SafeDirectory $canonicalPath)
}

$ProjectsRoot = [IO.Path]::GetFullPath($ProjectsRoot)
$TasksRoot = [IO.Path]::GetFullPath($TasksRoot)
$matchedManifests = @()
if (Test-Path -LiteralPath $ProjectsRoot) {
    foreach ($directory in Get-ChildItem -LiteralPath $ProjectsRoot -Directory) {
        $candidateManifestPath = Join-Path $directory.FullName 'project.json'
        if (-not (Test-Path -LiteralPath $candidateManifestPath)) {
            continue
        }

        $candidateManifest = Read-ProjectManifest -ManifestPath $candidateManifestPath
        if ($normalizedPath -in (Get-ManifestPaths -Manifest $candidateManifest)) {
            $matchedManifests += [pscustomobject]@{
                Home = $directory.FullName
                Path = $candidateManifestPath
                Data = $candidateManifest
            }
        }
    }
}

if ($matchedManifests.Count -gt 1) {
    throw "Multiple project manifests claim $canonicalPath"
}

$manifestRecord = $null
if (-not [string]::IsNullOrWhiteSpace($ProjectId)) {
    if ($ProjectId -notmatch '^[a-z0-9][a-z0-9-]*$') {
        throw 'ProjectId may contain only lowercase letters, digits, and hyphens.'
    }

    $explicitHome = Join-Path $ProjectsRoot $ProjectId
    $explicitManifestPath = Join-Path $explicitHome 'project.json'
    if (-not (Test-Path -LiteralPath $explicitManifestPath)) {
        throw "ProjectId '$ProjectId' does not identify an existing project manifest."
    }

    $explicitManifest = Read-ProjectManifest -ManifestPath $explicitManifestPath
    if ($explicitManifest.projectId -cne $ProjectId) {
        throw "ProjectId does not match the manifest in $explicitManifestPath"
    }

    $manifestRecord = [pscustomobject]@{ Home = $explicitHome; Path = $explicitManifestPath; Data = $explicitManifest }
}
elseif ($matchedManifests.Count -eq 1) {
    $manifestRecord = $matchedManifests[0]
    $ProjectId = $manifestRecord.Data.projectId
}
else {
    $slug = Get-ProjectSlug -NormalizedPath $normalizedPath
    $ProjectId = "$slug-$(Get-ShortHash -Value $normalizedPath)"
}

$projectHome = Join-Path $ProjectsRoot $ProjectId
$manifestPath = Join-Path $projectHome 'project.json'
$scratchPath = Join-Path $projectHome 'scratch'
$privatePath = Join-Path $projectHome 'private'
$indexPath = Join-Path $scratchPath 'INDEX.md'
$created = $false

if ($null -eq $manifestRecord -and (Test-Path -LiteralPath $manifestPath)) {
    $collidingManifest = Read-ProjectManifest -ManifestPath $manifestPath
    if ($normalizedPath -notin (Get-ManifestPaths -Manifest $collidingManifest)) {
        throw "Project home collision: $manifestPath does not claim $canonicalPath"
    }
    $manifestRecord = [pscustomobject]@{ Home = $projectHome; Path = $manifestPath; Data = $collidingManifest }
}

if ($null -ne $manifestRecord) {
    $knownPaths = Get-ManifestPaths -Manifest $manifestRecord.Data
    if ($normalizedPath -notin $knownPaths) {
        if (-not $RegisterAlias) {
            throw "The current path is not registered for '$ProjectId'. Use -ProjectId '$ProjectId' -RegisterAlias -Ensure to add it explicitly."
        }

        $aliases = @()
        $aliasesProperty = $manifestRecord.Data.PSObject.Properties['pathAliases']
        if ($null -ne $aliasesProperty -and $null -ne $aliasesProperty.Value) {
            $aliases = @($aliasesProperty.Value)
        }
        $aliases = @($aliases + $normalizedPath | ForEach-Object { $_.ToString().ToLowerInvariant() } | Select-Object -Unique)

        if ($null -eq $aliasesProperty) {
            $manifestRecord.Data | Add-Member -NotePropertyName pathAliases -NotePropertyValue $aliases
        }
        else {
            $manifestRecord.Data.pathAliases = $aliases
        }

        $updatedJson = $manifestRecord.Data | ConvertTo-Json -Depth 10
        Write-ReplacedUtf8File -FilePath $manifestRecord.Path -Content ($updatedJson + [Environment]::NewLine)
    }

    $projectHome = $manifestRecord.Home
    $manifestPath = $manifestRecord.Path
    $scratchPath = Join-Path $projectHome 'scratch'
    $privatePath = Join-Path $projectHome 'private'
    $indexPath = Join-Path $scratchPath 'INDEX.md'
}

if ($Ensure) {
    New-Item -ItemType Directory -Path $ProjectsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $projectHome -Force | Out-Null
    New-Item -ItemType Directory -Path $scratchPath -Force | Out-Null
    New-Item -ItemType Directory -Path $privatePath -Force | Out-Null

    if (-not (Test-Path -LiteralPath $manifestPath)) {
        $displayName = Split-Path -Leaf $canonicalPath
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = $canonicalPath
        }

        $gitInfo = $null
        if ($isGitWorktree) {
            $gitInfo = [ordered]@{
                worktreeRoot = $canonicalPath
                originUrl = $originUrl
            }
        }

        $manifest = [ordered]@{
            schemaVersion = 1
            projectId = $ProjectId
            displayName = $displayName
            canonicalPath = $canonicalPath
            normalizedPath = $normalizedPath
            pathAliases = @()
            git = $gitInfo
            createdAt = [DateTime]::UtcNow.ToString('o')
        }
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Write-NewUtf8File -FilePath $manifestPath -Content ($manifestJson + [Environment]::NewLine)
        $created = $true
    }

    $index = @'
# Active Handovers

| Task | Agent/session | Branch/worktree | Status | Updated (UTC) |
| --- | --- | --- | --- | --- |
'@
    Write-NewUtf8File -FilePath $indexPath -Content ($index + [Environment]::NewLine)
}

$relatedTaskProjectPaths = @($normalizedPath)
if ($null -ne $manifestRecord) {
    $relatedTaskProjectPaths += Get-ManifestPaths -Manifest $manifestRecord.Data
}
$relatedTaskProjectPaths = @($relatedTaskProjectPaths | Select-Object -Unique)

$result = [ordered]@{
    projectId = $ProjectId
    projectHome = $projectHome
    scratchPath = $scratchPath
    privatePath = $privatePath
    manifestPath = $manifestPath
    indexPath = $indexPath
    canonicalPath = $canonicalPath
    normalizedPath = $normalizedPath
    isGitWorktree = $isGitWorktree
    originUrl = $originUrl
    relatedTasks = @(Get-RelatedTasks -RegistryRoot $TasksRoot -ProjectPaths $relatedTaskProjectPaths)
    exists = (Test-Path -LiteralPath $manifestPath)
    created = $created
}

if ($Json) {
    # Pure-ASCII output survives piping through non-UTF-8 console code pages.
    $result | ConvertTo-Json -Depth 10 -EscapeHandling EscapeNonAscii
}
else {
    $projectHome
}
