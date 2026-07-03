# Main aliases
alias ls='exa --long --git -a --header --group'     # Alias for 'exa' command with options for long listing, git status, all files, header, and grouping
alias tree='exa --tree --level=2 --long -a --header --git' # Alias for 'exa' command with options for showing a tree view, limited to 2 levels, long listing, all files, header, and git status

# More aliases using exa
alias ll='exa --long --git --header --group --time-style=long-iso'  # Alias for 'exa' command with options for long listing, git status, header, grouping, and long-ISO time format
alias la='exa --long --git --all --header --group --time-style=long-iso'  # Alias for 'exa' command with options for long listing, git status, all files, header, grouping, and long-ISO time format
alias l.='exa --long --git --header --group --time-style=long-iso .'  # Alias for 'exa' command with options for long listing, git status, header, grouping, long-ISO time format, and current directory
alias lsr='exa --long --git --header --group --time-style=long-iso --recurse'  # Alias for 'exa' command with options for long listing, git status, header, grouping, long-ISO time format, and recursive listing

alias nv="/opt/homebrew/bin/nvim"
alias nvc="nv ~/.config/nvim"
alias zs="nv ~/.zshrc"
alias python="python3"
alias lz="lazygit"
alias cls="clear"
alias eng="cd ~/engineering"
alias py=python3
