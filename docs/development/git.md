# Version Control

Ansible content should be treated as any project containing source code, therefore using version control is always recommended. This guide focuses on *Git* as it is the most widespread tool.

## Branching concept

Branches are a part of your everyday development process, they are effectively a pointer to a snapshot of your changes. When you want to add a new feature or fix a bug, you spawn a new branch to encapsulate your changes. This makes it harder for unstable code to get merged into the main code base, and it gives you the chance to clean up your future's history before merging it into the main branch.  
We are using the following branches:

* main (protected, only merge commits are allowed)
* dev (protected, force-pushes are allowed)
* feature/*branch-name*
* bugfix/*branch-name*
* hotfix/*branch-name*

The *main* branch is the *production-code*, forking (a *feature* or *bugfix* branch) is always done from the *dev* branch. Forking a *hotfix* branch is done from the *main* branch, as it should fix something not working with the production code.

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

In case you need to fix a bug in a role or playbook, fork a new branch from *dev* and prefix your branch-name with `bugfix/` and provide a short, but meaningful description of the unwanted behavior.  

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
...
$ git add -A
...
$ git commit -m "Fixes Issue #31, will restore prod environment."
```

Now, push your changes to the upstream repository.

```bash
$ git push -u origin
...
```

In the upstream repository, open a *merge request* from your *hotfix* branch to the *main* branch.

!!! note
    After rolling out the changes to the production environment and ensuring the hotfix works as expected, open a new merge request against the *dev* branch to ensure the fixes are also available in the development stage.

## Git hooks

Git Hooks are scripts that Git can execute automatically when certain events occur, such as before or after a commit, push, or merge. There are several types of Git Hooks, each with a specific purpose.

### Pre-Commit

Pre-commit hooks can be used to enforce code formatting or run tests before a commit is made.  

The most convenient way is the use of the [pre-commit framework](https://pre-commit.com/){:target="_blank"}, install the *pre-commit* utility:

```bash
pip3 install pre-commit
```

Use the following configuration as a starting point, create the file in your project folder.

```yaml title=".pre-commit-config.yaml"
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
      - id: check-merge-conflict
      - id: trailing-whitespace
        args: [--markdown-linebreak-ext=md]
      - id: no-commit-to-branch
      - id: requirements-txt-fixer
  - repo: https://github.com/timgrt/pre-commit-hooks
    rev: v0.2.0
    hooks:
      - id: check-file-names
      - id: check-vault-files
  - repo: https://github.com/ansible-community/ansible-lint
    rev: v6.15.0
    hooks:
      - id: ansible-lint
```

Take a look at [https://pre-commit.com/hooks.html](https://pre-commit.com/hooks.html){:target="_blank"} for additional hooks for your use-case.  

Install all hooks of the `.pre-commit-config.yaml` file:

```bash
pre-commit install
```

Run the `autoupdate` command to update all revisions to the latest state:

```bash
pre-commit autoupdate
```

!!! success
    *pre-commit* will now run on every commit.

You can run all hooks at any time with the following command, without committing:

```bash
pre-commit run -a
```

??? example "Example output"

    ```{ .bash .no-copy }
    $ pre-commit run -a
    check yaml...............................................................Passed
    check for merge conflicts................................................Passed
    trim trailing whitespace.................................................Passed
    don't commit to branch...................................................Passed
    fix requirements.txt.................................(no files to check)Skipped
    markdownlint-docker......................................................Passed
    Check files for non-compliant names......................................Passed
    Ansible-lint.............................................................Failed
    - hook id: ansible-lint
    - exit code: 2

    [...output cut for readability...]

    Read documentation for instructions on how to ignore specific rule violations.

                          Rule Violation Summary  
    count tag                           profile rule associated tags  
        3 role-name                     basic   deprecations, metadata
        1 name[missing]                 basic   idiom  
        2 yaml[comments]                basic   formatting, yaml  
        1 yaml[new-line-at-end-of-file] basic   formatting, yaml  

    Failed after min profile: 7 failure(s), 0 warning(s) on 30 files.
    ```

!!! hint
    The first time pre-commit runs on a file it will automatically download, install, and run the hook. Note that running a hook for the first time may be slow. but will be faster in subsequent iterations.

#### Offline

The *pre-commit* framework by default needs internet connection to setup the hooks, in disconnected environments you can build the pre-commit hook yourself.

The following script can be used as a starting point, it uses *ansible-lint* from inside a container (see [Lint in Docker Image](linting.md#lint-in-docker-image) how to build it) and also checks for unencrypted files in your commit.

??? example ".git/hooks/pre-commit"

    ```bash
    #!/bin/bash
    #
    # File should be .git/hooks/pre-commit and executable
    #

    # Pre-commit hook that runs ansible-lint Container for best practice checking
    # If lint has errors, commit will fail with an error message.
    if [[ ! $(docker inspect ansible-lint) ]] ; then
      echo "# DOCKER IMAGE NOT FOUND"
      echo "# Build the Docker image from the Gitlab project 'ansible-lint Docker Image'."
      echo "# No linting is done!"
    else
      echo "# Running 'ansible-lint' against commit, this takes some time ..."
      # Getting all files currently staged and storing them in variable
      FILES_TO_LINT=$(git diff --cached --name-only)
      # Running with shared profile, see https://ansible-lint.readthedocs.io/profiles/
      if [ -z "$FILES_TO_LINT" ] ; then
        echo "# No files linting found. Add files to staging area with 'git add <file>'."
      else
        docker run --rm -v $(pwd):/data ansible-lint $FILES_TO_LINT
        if [ ! $? = 0 ]; then
          echo "# COMMIT REJECTED"
          echo "# Please fix the shown linting errors"
          echo "#   (or force the commit with '--no-verify')."
          exit 1;
        fi
      fi
    fi

    # Pre-commit hook that verifies if all files containing 'vault' in the name
    # are encrypted.
    # If not, commit will fail with an error message.
    # Finds all files in 'inventory' folder or 'files' folder in roles. Files in other
    # locations are not recognized!
    FILES_PATTERN='(inventory.*vault.*)|(files.*vault.*)'
    REQUIRED='ANSIBLE_VAULT'

    EXIT_STATUS=0
    wipe="\033[1m\033[0m"
    yellow='\033[1;33m'
    # carriage return hack. Leave it on 2 lines.
    cr='
    '
    echo "# Checking for unencrypted vault files in commit ..."
    for f in $(git diff --cached --name-only | grep -E $FILES_PATTERN)
    do
      # test for the presence of the required bit.
      MATCH=`head -n1 $f | grep --no-messages $REQUIRED`
      if [ ! $MATCH ] ; then
        # Build the list of unencrypted files if any
        UNENCRYPTED_FILES="$f$cr$UNENCRYPTED_FILES"
        EXIT_STATUS=1
      fi
    done
    if [ ! $EXIT_STATUS = 0 ] ; then
      echo '# COMMIT REJECTED'
      echo '# Looks like unencrypted ansible-vault files are part of the commit:'
      echo '#'
      while read -r line; do
        if [ -n "$line" ] ; then
          echo -e "#\t${yellow}unencrypted:   $line${wipe}"
        fi
      done <<< "$UNENCRYPTED_FILES"
      echo '#'
      echo "# Please encrypt them with 'ansible-vault encrypt <file>'"
      echo "#   (or force the commit with '--no-verify')."
      exit $EXIT_STATUS
    fi
    exit $EXIT_STATUS
    ```
