# Tmux aliases
if [[ -x "$(command -v tmux)" ]]; then
  alias tm="tmux"
  alias tmc="nvim ~/.tmux.conf"
  alias tmka="tmux kill-session"
  alias tml="tmux list-sessions"
  tmk() { tmux kill-session -t "$1"; }
  tma() { tmux attach -t "$1"; }
  tmn() { tmux new -s "$1"; }
fi
