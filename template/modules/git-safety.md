## Working In Git Repositories

Before reasoning about repository state or starting changes, fetch and fast-forward from the tracked remote so the checkout is current. If a repository fact is surprising, suspect a stale checkout before concluding. Never overwrite or discard uncommitted work to update a checkout.

**Wait for the user's clear confirmation before pushing or merging into shared branches.** Approval of an approach before the changes exist is not push authorization; an unambiguous "ship it" after reviewing the actual changes is.

Never open a pull request, issue, or equivalent upstream action against a repository the user does not own without explicit approval each time. Before reporting what is pushed, live, or open, verify the remote state with a read-only check.
