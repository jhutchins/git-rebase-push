[![Circle CI](https://circleci.com/gh/jhutchins/git-rebase-push.svg?style=shield)](https://circleci.com/gh/jhutchins/git-rebase-push)

#About

This is just a shortcut for a very common set of git commands that I run
```
git stash
git pull --rebase
git push
git stash pop
```

#Usage

Once installed simple run
```
git rebase-push
```
This will stash any local changes that you have, pull, rebase your changes on top, allow you
access to a console if there was a merge conflict, push your changes and unstash

#Install
If you're on Mac you can install with homebrew by running
```
brew tap jhutchins/tap
brew install git-rebase-push
```
