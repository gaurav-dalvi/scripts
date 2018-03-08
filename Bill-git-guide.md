# Local Git Workflows when working with Github

## Table of Contents

- [0. Foreword](#0-foreword)
- [1. Initial Setup of Local Repository](#1-initial-setup-of-local-repository)
- [2. Set up a Remote for Your Personal Fork](#2-set-up-a-remote-for-your-personal-fork)
- [3. Creating a Feature Branch and Opening a Pull Request](#3-creating-a-feature-branch-and-opening-a-pull-request)
- [4. Adding commits to a PR](#4-adding-commits-to-a-pr)
- [5. Editing commits that are part of a PR](#5-editing-commits-that-are-part-of-a-pr)
- [6. Rebasing on new changes from origin/master](#6-rebasing-on-new-changes-from-originmaster)
- [7. Triggering a new CI Build](#7-triggering-a-new-ci-build)
- [8. Testing someone else's PR](#8-testing-someone-elses-pr)
- [9. Pruning dead branches](#9-pruning-dead-branches)
- [10. Collaborating with someone on their own branch](#10-collaborating-with-someone-on-their-own-branch)
- [11. Advanced: Skipping the local master branch](#11-advanced-skipping-the-local-master-branch)
- [12. Setting up SSH keys](#12-setting-up-ssh-keys)
	- [Generate an SSH key](#generate-an-ssh-key)
	- [Add SSH key to Github](#add-ssh-key-to-github)
	- [Interacting with Github from another machine](#interacting-with-github-from-another-machine)
		- [Enable SSH agent forwarding](#enable-ssh-agent-forwarding)
		- [Test it](#test-it)
	- [Updating HTTPS remotes on existing repos](#updating-https-remotes-on-existing-repos)
- [13. Using a better shell](#13-using-a-better-shell)
- [14. Merging PRs](#14-merging-prs)
	- [I have more than one commit and they should not be squashed together.](#i-have-more-than-one-commit-and-they-should-not-be-squashed-together)
	- [I have more than one commit on my PR which I want to squash into a single commit before merging.](#i-have-more-than-one-commit-on-my-pr-which-i-want-to-squash-into-a-single-commit-before-merging)
	- [I have only one commit OR I have multiple commits which I want added to master without generating a merge commit.](#i-have-only-one-commit-or-i-have-multiple-commits-which-i-want-added-to-master-without-generating-a-merge-commit)

## 0. Foreword

In this guide, the organization name is "organization", the target repo is
"repo.git", and the username is "username".

This guide also assumes you are only using SSH keys to access Github.  We will
be enforcing 2FA (two factor authentication) which prevents authentication via
HTTPS (as there is no way to enter a one-time code).

To test whether you can access Github via SSH, run:

```sh
ssh git@github.com
```

If this command does not state that you have successfully authenticated, please
[follow the instructions for setting up SSH keys](#12-setting-up-ssh-keys).

I also recommend using `zsh` + `oh-my-zsh` so you can easily see which branch
you are currently on and if there are any uncommitted changes.
[Instructions are here](#13-using-a-better-shell).

## 1. Initial Setup of Local Repository

We need to clone the original repository onto your dev machine/server.

**NOTE**: If you are working on a Go project, you should run the following two
commands before running `git clone` (replacing "organization" with your
company's organization name):

```sh
mkdir -p $GOPATH/src/github.com/organization
cd $GOPATH/src/github.com/organization
```

If you are not working on a Go project, just `cd` to whichever directory you
want to store the code in.

Run the following command (replacing "organization" with your company's
organization name and "repo" with the repository's name):

```sh
git clone git@github.com:organization/repo.git
```

Then change into the new directory which was created:

```sh
cd repo
```


## 2. Set up a Remote for Your Personal Fork

Go to the main repository's Github page and click "Fork" in the upper right
corner.  Fork it into your personal account.

Once it's done, run the following (replacing "username" with your Github
username and "repo" with the repository's name):

```sh
git remote add username git@github.com:username/repo.git
```

To make your local repo aware of the new remote and its branches/commits, run:

```sh
git fetch username
```

To keep things simple, "origin" will always be the canonical, main repo and
everyone else's forks will be referred to by their Github username (including
your own).

Inspect what you just did by running:

```sh
git branch -vv # note: -vv, not -v.  -v does not show tracking branches
```

To see all the branches (local and remote) that your local repo knows about,
run:

```sh
git branch -a
```


## 3. Creating a Feature Branch and Opening a Pull Request

Ensure that you're on your local master branch and that it's up to date:

```sh
git checkout master
git pull # no need to use --rebase because this is a fast-forward
```

Create a local feature branch and switch to it:

```sh
git checkout -b feature_branch
```

Write your code and create some commits using `git commit`.  When you are happy
with how things look, push your changes up to a branch on your fork:

```sh
git push -u username feature_branch
```

The `-u` switch sets your local `feature_branch` to track
`username/feature_branch` automatically.  From this point onwards, you can just
run `git push` and `git pull` when working on this branch.  You don't need to
specify any other options, remote names, or branch names.

When you open the main repo or your private fork on Github, you will now see a
**"Your recently pushed branches"** section at the top with a
**"Compare & pull request"** button.  Click that button, tidy up the message
and body of the PR, and submit it.


## 4. Adding commits to a PR

Add more commits locally, and run the following to add them to the PR:

```sh
git push
```

That's it!  Because your local branch is tracking the PR branch, nothing else
is necessary.  Your changes will show up immediately on Github when you refresh
the PR page.


## 5. Editing commits that are part of a PR

At some point, you will need to edit commits that are already part of a PR on
Github.  You can do this using `git rebase -i` or `git commit --amend`.  Once you
are happy with your work, you can update the PR:

```sh
git push -f
```

You need to use the `-f` (force) switch because you have altered history.  git
will refuse to perform operations when branch histories have diverged unless
specifically overriden by the user.


## 6. Rebasing on new changes from origin/master

Sometimes, you will need to take new changes that have been merged into
`origin/master` (via another PR) since you created your feature branch and put
your new changes on top of them. This is accomplished by pulling down those
changes to your local `master` branch and rebasing your feature branch on top
of it.

If you are in the middle of changes on your feature branch, you will either
need to `git stash` them or commit them.

```sh
git checkout master
git pull # no need to use --rebase because this is a fast-forward
git checkout feature_branch
git rebase master
```

The `git rebase master` command can result in a merge conflict if new changes
on origin/master are incompatible with changes you've made on your feature
branch.  You will need to resolve this before the rebase operation can finish.

To push the newly-rebased feature branch, you will need to use `-f` as you've
rewritten history.

```sh
git push -f
```

## 7. Triggering a new CI Build

Our repos have hooks installed which automatically trigger CI builds when *new*
commits come in on a PR.

Sometimes, a CI build will fail for some reason and you want to trigger another
one, but you also don't need to make any code changes.  This is accomplished by
changing the SHA1 hash for the latest commit on your branch and pushing it to
Github.

**NOTE: Triggering a new CI build should not generate an additional commit!**

Run the following command:

```sh
git commit --amend --no-edit
```

This updates the timestamp on your latest commit which causes a new SHA1 to be
generated.  When you force push (with `-f`), the CI system sees it as a
brand new commit and will launch a new CI build for you.


## 8. Testing someone else's PR

If you haven't already, add their fork as a remote:

```sh
git remote add theirusername git@github.com:theirusername/repo.git
```

Regardless of whether you've already added their remote or not, you will need
to make your local repo aware of the latest branches and commits on their fork:

```sh
git fetch theirusername
```

If you are in the middle of some work, stash it or commit it. Then run:

```sh
git checkout -t theirusername/theirbranchname
```

This creates a local branch called `theirbranchname` which tracks
`theirusername/theirbranchname` and switches you to it in one command.

Because `checkout` is a local operation, you can only do this for remote
branches which your local copy knows about, and it will make the HEAD of the
newly-created local branch equal with the latest commit from their remote
branch that your local copy knows about.  This is why we ran the fetch command
beforehand.

If they add new commits, you can just run `git pull` to grab them.  If they
rewrite history on their branch and force push it, your pull will fail.  You
will need to delete (i.e., "hard reset") the outdated local commits and fetch
the updated ones from the remote branch.

```sh
git reset --hard HEAD~5 # this deletes the last 5 commits on the branch
git pull # this brings you back up to date so your HEAD is even with theirs
```


## 9. Pruning dead branches

When you run any `git fetch` command, it will only add information about new
branches and new commits on known branches on the specified remote(s).  It will
not remove your local repo's knowledge of any remote branches which no longer
exist.

To remove your local repo's knowledge of remote branches which no longer exist:

```sh
git fetch --all --prune
```

It is not strictly necessary to run this, but over time you (and the remotes
you are tracking) will accumulate a lot of dead branches as PRs are merged.

This command can be safely run at any time.  It does not alter any local
commits or branches.


## 10. Collaborating with someone on their own branch

Sometimes, you may want to collaborate with someone on a branch before or after
it is formally opened as a PR.

They will need to add you as a collaborator on their private fork.  They can do
this by visiting their repo, clicking "Settings", and then clicking
"Collaborators & Teams".

You will need to track their branch locally.  Skip the first command if you
already have them as a remote:

```sh
git remote add theirusername git@github.com:theirusername/repo.git
git fetch theirusername
git checkout -t theirusername/their_feature_branch
```

You can now create commits locally and push and pull them as necessary.

Push operations may return an error if they have pushed new commits since you
last did a pull.  If you use `git pull` by itself in this situation, your local
repo will be forced to generate a merge commit to reconcile the differing
histories.  We don't want that.  We'll use `--rebase`.

```sh
git pull --rebase
```

This is the only time you will have to use `--rebase` when pulling.  This will
rewrite your local history and put the new commits on the remote branch _under_
the new commits on your local branch.

Using `--rebase` can result in commits not being in chronological order.  There
is no problem with this, but it's something to be aware of.


## 11. Advanced: Skipping the local master branch

It is not strictly necessary to have an up-to-date _local_ master branch when
creating a feature branch.  `git branch` can create a new branch from any
branch that your local repo knows about.  This includes remote branches that
your local repo knows about. The following two sets of commands have the same
result:

```sh
git checkout master
git pull # no need to use --rebase because this is a fast-forward
git checkout -b feature_branch
```

or:

```sh
git fetch origin # makes your local repo aware of new branches/commits on Github
git checkout -b feature_branch origin/master
```

In the latter example, git will create a new branch from the latest commit
that your _local_ copy knows exists for `origin/master` without having to switch
to a local `master` branch at all.  We run `git fetch` beforehand to ensure that
our local repo has the latest commits for `origin/master` from Github.

Similarly, you can ignore the local master branch when you want to rebase your
local feature branch on the latest changes on Github:

```sh
git fetch origin # makes your local repo aware of new branches/commits on Github
git rebase origin/master
```

## 12. Setting up SSH keys

These instructions will get you set up to work with Github without using a
username and password.  When you enable 2FA (or we force it on), this will
become the only way you can access our repos on Github.

### Generate an SSH key

If you don't already have an SSH keypair on your local machine (look in
`~/.ssh/` for something named like `id_rsa` and `id_rsa.pub`), generate one with
the following command.  You'll be prompted for a passphrase.  It's not required,
but I recommend adding one.

```sh
ssh-keygen -t rsa -b 4096
```

### Add SSH key to Github

You'll need to add the public part of the keypair to your Github account. Visit
https://github.com/settings/keys and add the key.  If you're on a Mac, you can
easily copy the key to your clipboard with `pbcopy < ~/.ssh/id_rsa.pub`

Once that's done, try the following:

```sh
ssh git@github.com
```

You should receive a message stating that you successfully authenticated as your
user.  If not, double check that you copied the full key.  If you still can't
get it working, come talk to me (Bill).

### Interacting with Github from another machine

If your keypair is on your local machine but you do all of your work while SSH'd
into another machine, you will need to do a little more setup.  SSH supports
something called "agent forwarding".  This allows a chain of SSH sessions to
forward authentication requests back to your local machine.  Without forwarding
enabled, an attempt to login to Github from your dev machine will fail because
there is no matching keypair present.

#### Enable SSH agent forwarding

On your local machine, edit `~/.ssh/config` (creating it if it doesn't exist)
and add the following at the top:

```
Host *
  ForwardAgent yes
```

Now, you'll need to add your SSH key to your local SSH agent.  If you put a
passphrase on your private key, you will be prompted to enter it.

```sh
ssh-add ~/.ssh/id_rsa
```

#### Test it

Login to your dev server and run the following:

```sh
ssh git@github.com
```

You should be able to successfully authenticate with Github without having a
keypair present on your devserver.

### Updating HTTPS remotes on existing repos

If you already have existing repos, you will likely have remotes set up which use
HTTPS.  You can check with `git remote -v`:

```sh
$ git remote -v
dseevr	https://github.com/dseevr/netplugin.git (fetch)
dseevr	https://github.com/dseevr/netplugin.git (push)
origin	https://github.com/contiv/netplugin.git (fetch)
origin	https://github.com/contiv/netplugin.git (push)
```

We want to change these to use SSH.  We'll need to remove the remotes, add
them again, and then make our local repo aware of the branches and commits on
the "new" remotes:

```sh
git remote remove dseevr
git remote remove origin
git remote add dseevr git@github.com:dseevr/netplugin.git
git remote add origin git@github.com:contiv/netplugin.git
git fetch --all
```

Now, `git remote -v` should show the correct output and you will be able to push
and pull without entering a username or password:

```sh
$ git remote -v
dseevr	git@github.com:dseevr/netplugin.git (fetch)
dseevr	git@github.com:dseevr/netplugin.git (push)
origin	git@github.com:contiv/netplugin.git (fetch)
origin	git@github.com:contiv/netplugin.git (push)
```

## 13. Using a better shell

By default, your OS probably has you using `bash` as your shell.  While there
are plugins which add some git integration to `bash`, I believe that `zsh` is a
far superior choice and recommend you try it.  My terminal looks like this:

```
~/src/github.com/containerx/storage(branch:foobar) »
```

I can see which branch I'm on and if there's any changes (indicated by a * in
the theme I am using).  I can also tab-complete all git commands, remotes,
branches, tags, and so on.

In a stock `bash` setup, my shell would just look like this:

```
bilrobin@contiv228:~/src/github.com/containerx/storage$
```

I use a great script called
[oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh#getting-started) which
automates the setup of `zsh` and enables git integration by default.

I also recommend editing your `~/.zshrc` and enabling "docker" and "vagrant" in
the `plugins` section:

```
plugins=(git docker vagrant)
```


## 14. Merging PRs

When you want to merge a PR on Github, there are three ways to do it.  You can
see the three options by clicking the downward-facing arrow next to "Merge pull
request".  Which one you use depends on the situation.

### I have more than one commit and they should not be squashed together.

You will want to choose the **Create a merge commit** option.  This will run the
equivalent of `git merge --no-ff` and always generates a merge commit.

### I have more than one commit on my PR which I want to squash into a single commit before merging.

You will want to choose the **Squash and merge** option.  This will do the
equivalent of a `git rebase -i` which squashes all the commits into one and	then
a `git merge --ff-only` to bring it into master. This option updates the
creation time of the single commit to be the time of merge so it's guaranteed
to be at HEAD on master.

If you are merging someone else's PR, do NOT use this option unless they have
specifically requested it.

### I have only one commit OR I have multiple commits which I want added to master without generating a merge commit.
You will want to choose the **Rebase and merge** option.  This will retain the
original commit timestamps but put your commits at the top of master.  This can
result in commits being out of chronoligcal order.  It's not a problem and won't
negatively affect anyone, but it's just something to be aware of.
