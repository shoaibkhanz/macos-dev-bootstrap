# Conda aliases
if [[ -x "$(command -v conda)" ]]; then
  # Basic conda commands
  alias cda='conda activate $1'    # Alias for 'conda activate' (activate a conda environment)
  alias cde='conda deactivate' # Alias for 'conda deactivate' (deactivate the current conda environment)
  alias cs='conda search'      # Alias for 'conda search' (search for packages on Anaconda Cloud and/or in a local channel)
  alias cenv='conda env'       # Alias for 'conda env' (create and manage conda environments)
  alias clist='conda env list' # Alias for 'conda env list' (list all conda environments)
  alias cr='conda remove'      # Alias for 'conda remove' (remove a package or an environment)

  # Package management commands
  alias ci='conda install'     # Alias for 'conda install' (install a package or multiple packages)
  alias cu='conda update'      # Alias for 'conda update' (update a package or multiple packages)
  alias cup='conda update --all' # Alias for 'conda update --all' (update all packages in the current environment)
  alias crm='conda remove'     # Alias for 'conda remove' (remove a package or an environment)
  alias csr='conda search'     # Alias for 'conda search' (search for packages on Anaconda Cloud and/or in a local channel)

  # Informational commands
  alias che='conda --version'  # Alias for 'conda --version' (display the conda version number)
  alias chl='conda list'       # Alias for 'conda list' (list installed packages in the current environment)
  alias chr='conda info'       # Alias for 'conda info' (display information about the current conda installation)
  alias chs='conda search'     # Alias for 'conda search' (search for packages on Anaconda Cloud and/or in a local channel)

  # Clean-up commands
  alias cc='conda clean'       # Alias for 'conda clean' (remove unused packages and caches from the current environment)
  alias cca='conda clean --all' # Alias for 'conda clean --all' (remove unused packages and caches from all conda environments)
fi
