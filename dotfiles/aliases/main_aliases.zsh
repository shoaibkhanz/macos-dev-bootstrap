# Main aliases

# File listing (eza - modern ls replacement)
alias ls='eza --long --git -a --header --group'
alias tree='eza --tree --level=2 --long -a --header --git'
alias ll='eza --long --git --header --group --time-style=long-iso'
alias la='eza --long --git --all --header --group --time-style=long-iso'
alias l.='eza --long --git --header --group --time-style=long-iso .'
alias lsr='eza --long --git --header --group --time-style=long-iso --recurse'

# Config shortcuts
alias vi="nvim"
alias nv="nvim ~/.config/nvim"
alias zrc="nvim ~/.zshrc"
alias src="source ~/.zshrc"
alias sec="nvim ~/.secrets"
alias sshnv="nvim ~/.ssh"

# General
alias cls="clear"
alias python="python3"

# Development tools
alias lz="lazygit"
alias op="opencode"
alias cl="claude"

# Python/UV
ur() { uv run "$@"; }
alias urn="uv run nvim"

# AWS
alias ad="awsume datascience"

# Docker
alias db="docker build"
alias dr="docker run"
alias dp="docker push"

# Kubernetes (lazy-load to prevent shell hang)
unalias kt kga 2>/dev/null
_kubectl_lazy_init() {
  unfunction _kubectl_lazy_init kubectl kubecolor kt 2>/dev/null
  source <(command kubectl completion zsh)
  compdef kubecolor=kubectl
  alias kt='kubecolor'
}
kubectl() { _kubectl_lazy_init; command kubecolor "$@"; }
kubecolor() { _kubectl_lazy_init; command kubecolor "$@"; }
kt() { _kubectl_lazy_init; command kubecolor "$@"; }

alias eks="eksctl"
alias kns="kubecolor get ns"
alias kp="kubecolor get po"
kga() { kubecolor get all -n "$1"; }

# Ray cluster helpers
hp() { export HEAD_POD=$(command kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers); }
kpo() { command kubectl port-forward "$HEAD_POD" "$@"; }
