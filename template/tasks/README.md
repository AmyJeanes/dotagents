# Cross-Project Task Registry

This registry holds temporary handoffs whose implementation or decisions span more than one project. A task has one canonical directory; do not duplicate it into participant project scratch spaces.

Each immediate subdirectory must use a stable lowercase hyphenated task ID and contain:

- `task.json`: discovery metadata;
- `TASK.md`: the default human-readable entrypoint;
- optional participant-specific subdirectories and supporting files.

Use this manifest shape:

```json
{
  "schemaVersion": 1,
  "id": "example-task",
  "title": "Example cross-project task",
  "status": "paused",
  "entrypoint": "TASK.md",
  "participants": [
    {
      "path": "/absolute/path/to/first-project",
      "role": "producer"
    },
    {
      "path": "/absolute/path/to/second-project",
      "role": "consumer"
    }
  ]
}
```

`status` must be `active`, `paused`, or `blocked`. Participant paths must be the absolute `canonicalPath` values returned by `Resolve-AgentProject.ps1`. The entrypoint must be a relative path inside the task directory and must exist.

After editing a manifest, resolve every participant and verify the task appears in `relatedTasks`. When the work finishes, promote durable knowledge into the affected repositories and delete the task directory.
