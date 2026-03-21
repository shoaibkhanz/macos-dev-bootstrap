# Git aliases
if [[ -x "$(command -v git)" ]]; then
  # Basic commands
  alias g='git'
  alias ga='git add'
  alias gc='git commit'
  alias gcm='git commit -m'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gl='git log'
  alias gpl='git pull'
  alias gps='git push'
  alias gpf='git push --force-with-lease'  # Safe force push
  alias gr='git remote'
  alias grv='git remote -v'
  alias gs='git status'

  # Branch commands
  alias gb='git branch'
  alias gba='git branch -a'
  alias gbd='git branch -d'
  alias gbD='git branch -D'
  alias gbm='git branch -m'
  alias gbn='git branch --no-merged'
  alias gbo='git branch --remote --verbose'
  alias gbs='git show-branch'

  # Other commands
  alias gch='git cherry'
  alias gcl='git clone'
  alias gco='git checkout'
  alias gcp='git cherry-pick'
  alias gcv='git commit --verbose'
  alias gdt='git difftool'
  alias glg='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative'
fi
