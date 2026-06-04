if [[ -n "$DEV_SHELL" ]]; then
  echo "info: dev-shell already activated" >&2
  return
fi
export DEV_SHELL=battery.nvim

if ! [[ -d "$PWD/.git" ]]; then
  echo "error: \$PWD ($PWD) is not a git repository" >&2
  return
fi

REPO="$PWD"

export XDG_DATA_HOME="$REPO/.xdg/data"
export XDG_CONFIG_HOME="$REPO/.xdg/config"
export XDG_STATE_HOME="$REPO/.xdg/state"
export XDG_CACHE_HOME="$REPO/.xdg/cache"

for dir in "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"; do
  mkdir -p "$dir"
done

mkdir -p "$XDG_CONFIG_HOME/nvim/pack/dev/opt"
if ! [[ -L "$XDG_CONFIG_HOME/nvim/pack/dev/opt/battery.nvim" ]]; then
  ln -s "$REPO" "$XDG_CONFIG_HOME/nvim/pack/dev/opt/battery.nvim"
fi

PS1="(dev-shell) $PS1"
