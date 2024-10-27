# Keep track of the directory containing the active venv
export VENV_ROOT=""

# Function to handle venv activation/deactivation
auto_venv() {
  local venv_path=".venv"

  # Find venv directory in current or parent directories
  local current_dir="$PWD"
  local found_venv_root=""

  while [[ "$current_dir" != "/" ]]; do
    if [[ -d "$current_dir/$venv_path" ]]; then
      found_venv_root="$current_dir"
      break
    fi
    current_dir=$(dirname "$current_dir")
  done

  # If we're no longer in a directory tree with a venv
  if [[ -z "$found_venv_root" && -n "$VIRTUAL_ENV" ]]; then
    echo "🐍 Deactivating venv from $VIRTUAL_ENV"
    deactivate
    VENV_ROOT=""
    return
  fi

  # If we found a venv
  if [[ -n "$found_venv_root" ]]; then
    # If it's a different venv than what's currently active
    if [[ "$found_venv_root" != "$VENV_ROOT" ]]; then
      # Deactivate existing venv if any
      if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate
      fi
      echo "🐍 Activating venv from $found_venv_root/$venv_path"
      source "$found_venv_root/$venv_path/bin/activate"
      VENV_ROOT="$found_venv_root"
    fi
  fi
}

# Register the auto_venv function to run when changing directories
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv

# Run once for the initial shell
auto_venv