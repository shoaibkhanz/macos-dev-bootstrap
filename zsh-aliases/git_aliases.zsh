# Git aliases
if [[ -x "$(command -v git)" ]]; then
  # Basic git commands
  alias g='git'                # Alias for 'git'
  alias ga='git add'           # Alias for 'git add' (stage changes)
  alias gc='git commit'        # Alias for 'git commit' (commit changes)
  alias gcm='git commit -m'    # Alias for 'git commit -m' (commit changes with a message)
  alias gd='git diff'          # Alias for 'git diff' (show changes between commits)
  alias gds='git diff --staged' # Alias for 'git diff --staged' (show changes between the staging area and the last commit)
  alias gl='git log'           # Alias for 'git log' (show commit logs)
  alias gpl='git pull'         # Alias for 'git pull' (fetch and merge changes from the remote repository)
  alias gps='git push'         # Alias for 'git push' (push changes to the remote repository)
  alias gr='git remote'        # Alias for 'git remote' (manage set of tracked repositories)
  alias grv='git remote -v'    # Alias for 'git remote -v' (list tracked repositories and their URLs)
  alias gs='git status'        # Alias for 'git status' (show the status of changes)

  # Branch commands
  alias gb='git branch'        # Alias for 'git branch' (list branches)
  alias gba='git branch -a'    # Alias for 'git branch -a' (list both remote-tracking and local branches)
  alias gbd='git branch -d'    # Alias for 'git branch -d' (delete branch)
  alias gbD='git branch -D'    # Alias for 'git branch -D' (force delete branch)
  alias gbm='git branch -m'    # Alias for 'git branch -m' (rename branch)
  alias gbn='git branch --no-merged' # Alias for 'git branch --no-merged' (list branches not yet merged into the specified branch)
  alias gbo='git branch --remote --verbose' # Alias for 'git branch --remote --verbose' (list remote branches)
  alias gbs='git show-branch'  # Alias for 'git show-branch' (show branch labels and their commits)

  # Commit history commands
  alias gch='git cherry'       # Alias for 'git cherry' (compare two branches and list the commits that are not on both)
  alias gcl='git clone'        # Alias for 'git clone' (clone a repository)
  alias gco='git checkout'     # Alias for 'git checkout' (switch branches or restore working tree files)
  alias gcp='git cherry-pick'  # Alias for 'git cherry-pick' (apply changes introduced by some existing commits)
  alias gcv='git covert'       # Alias for 'git covert' (manage remote-tracking branches)
  alias gdt='git difftool'     # Alias for 'git difftool' (show changes between commits using external diff tools)
  alias glg='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative' # Alias for a colored, decorated, graph log with
fi
