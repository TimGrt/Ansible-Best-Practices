# Version Control

## Branching concept

### Feature request

Creating a new feature should be done with a fork of the *latest* stage of the dev branch, prefix your branch-name with `feature/` and provide a short, but meaningful description of the new feature.

``` mermaid
gitGraph
   commit
   commit
   branch dev
   checkout dev
   commit
   branch feature
   checkout feature
   commit
   commit
   checkout dev
   commit
   checkout feature
   merge dev
   checkout dev
   merge feature
   commit
   checkout main
   merge dev
   checkout dev
   commit
   checkout main
   commit type:HIGHLIGHT
```

The complete workflow with *git* commands looks something like this:

```bash
$ git checkout dev
Switched to branch 'dev'
Your branch is behind 'origin/dev' by 3 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull
Updating b666be1..e1fc998
Fast-forward
...
$ git checkout -b feature/postgres-ha
Switched to a new branch 'feature/postgres-ha'
```

The single steps in order:

1. `git checkout dev` - Switching to *dev* branch.
2. `git pull` - Getting latest changes from upstream *dev* branch to local *dev* branch
3. `git checkout -b feature/postgres-ha` - Creating and switching to *hotfix* branch.

Start developing, save your work in a commit (or multiple commits).

```bash
$ git status
...
$ git add -A
...
$ git commit -m "Added tasks to configure Postgres High-Availability."
```

As the last step, before pushing your changes to the upstream repository and opening a *merge request*, ensure that the latest changes from the *dev* branch (which were made by others during your feature development) are also in your branch and no merge conflicts arise.  
Do the following steps:

```bash
$ git checkout dev
Switched to branch 'dev'
Your branch is behind 'origin/dev' by 2 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull
Updating e546ag7..klr732i
Fast-forward
...
$ git checkout -b feature/postgres-ha
...
Switched to branch 'feature/postgres-ha'
$ git merge dev
...
$ git push -u origin
```

### Bugfix request

In case you need to fix a bug in a role or playbook, fork a new branch from *dev* and prefix your branch-name with `bugfix/` and provide a short, but meaningful description of the unwanted behaviour.  

!!! info
    The steps are the same as for a feature branch, only the branch-name should indicate that a bug is to be fixed.

``` mermaid
gitGraph
   commit
   commit
   branch dev
   checkout dev
   commit
   branch bugfix
   checkout bugfix
   commit
   commit
   checkout dev
   commit
   checkout bugfix
   merge dev
   checkout dev
   merge bugfix
   commit
   checkout main
   merge dev
   checkout dev
   commit
   checkout main
   commit type:HIGHLIGHT
```

Take a look at the section above for an explanation of the single steps.

### Hotfix request

``` mermaid
gitGraph
   commit
   commit
   branch dev
   checkout dev
   commit
   checkout main
   commit
   branch hotfix
   checkout hotfix
   commit
   checkout main
   checkout hotfix
   commit
   checkout main
   merge hotfix
   checkout dev
   merge main
   commit
   commit
   checkout main
   commit type:HIGHLIGHT
```

The complete workflow with *git* commands looks something like this:

```bash
$ git checkout main
Switched to branch 'main'
Your branch is behind 'origin/main' by 11 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
$ git pull
Updating b666be1..e1fc998
Fast-forward
...
$ git checkout -b hotfix/mitigate-prod-outage
Switched to a new branch 'hotfix/mitigate-prod-outage'
```

The single steps in order:

1. `git checkout main` - Switching to *main* branch.
2. `git pull` - Getting latest changes from upstream *main* branch to local *main* branch
3. `git checkout -b hotfix/mitigate-prod-outage` - Creating and switching to *hotfix* branch.

After creating (and testing!) the fixes, save your work in a commit (or multiple commits).

```bash
$ git status
$ git add -A
$ git commit -m "Fixes Issue #31, will restore prod environment."
```

Now, push your changes to the upstream repository.

```bash
$ git push -u origin
```

In the upstream repository, open a *merge request* from your *hotfix* branch to the *main* branch.

After rolling out the changes to the production environment and ensuring the hotfix works as expected, open a new merge request against the *dev* branch to ensure the fixes are also available in the development stage.
