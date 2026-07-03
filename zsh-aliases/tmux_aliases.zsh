# Tmux aliases
if [[ -x "$(command -v tmux)" ]]; then
  # Basic tmux commands
  alias tm="tmux"                    # Alias for 'tmux'
  alias tmc="nv ~/.tmux.conf"        # Alias for 'nv ~/.tmux.conf' (edit the tmux configuration file)
  alias tmka="tmux kill-session"     # Alias for 'tmux kill-session' (kill the current tmux session)
  alias tmk="tmux kill-session -t $1" # Alias for 'tmux kill-session -t $1' (kill the specified tmux session)
  alias tma="tmux attach -t $1"      # Alias for 'tmux attach -t $1' (attach to the specified tmux session)
  alias tmn="tmux new -s $1"         # Alias for 'tmux new -s $1' (create a new tmux session with the specified name)
  alias tml="tmux list-sessions"     # Alias for 'tmux list-sessions' (list all tmux sessions)
fi
