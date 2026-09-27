## Working In Git Repositories

Before reasoning about repository state, fetch and check how far the checkout is behind its remote. Fast-forward only when on the default branch with no local changes; otherwise leave the checkout alone and read current upstream state with `git show origin/<default-branch>:<path>` or `git log origin/<default-branch>`. If a repository fact is surprising, suspect a stale checkout before concluding. Never overwrite or discard uncommitted work to update a checkout.

**Wait for the user's clear confirmation before pushing or merging into shared branches.** Approval of an approach before the changes exist is not push authorization; an unambiguous "ship it" after reviewing the actual changes is.

Never open a pull request, issue, or equivalent upstream action against a repository outside the user's own or their organisation's without explicit approval each time. Before reporting what is pushed, live, or open, verify the remote state with a read-only check.
