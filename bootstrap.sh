#!/bin/sh
set -eu

repository=${UNIX_SYNC_REPOSITORY:-${CONFIG_SYNC_REPOSITORY:-https://github.com/Elliot-Wang/unix-config-sync.git}}
ref=${UNIX_SYNC_REF:-${CONFIG_SYNC_REF:-main}}
source_dir=${UNIX_SYNC_SOURCE:-${CONFIG_SYNC_SOURCE:-"$HOME/.local/share/unix-sync/source"}}
bin_dir=${UNIX_SYNC_BIN_DIR:-${CONFIG_SYNC_BIN_DIR:-"$HOME/.local/bin"}}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "unix-sync: sudo is required to install bootstrap dependencies" >&2
    return 1
  fi
}

install_bootstrap_dependencies() {
  if command -v curl >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
    return
  fi
  case "$(uname -s)" in
    Darwin)
      echo "unix-sync: install the Xcode command-line tools, then run this script again:" >&2
      echo "  xcode-select --install" >&2
      exit 1
      ;;
    Linux)
      if command -v dnf >/dev/null 2>&1; then
        as_root dnf install -y ca-certificates curl git
      elif command -v yum >/dev/null 2>&1; then
        as_root yum install -y ca-certificates curl git
      elif command -v apt-get >/dev/null 2>&1; then
        as_root apt-get update
        as_root apt-get install -y ca-certificates curl git
      else
        echo "unix-sync: install curl and git with the system package manager" >&2
        exit 1
      fi
      ;;
    *)
      echo "unix-sync: unsupported bootstrap platform $(uname -s)" >&2
      exit 1
      ;;
  esac
}

resolve_source() {
  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)
  if [ -n "$script_dir" ] && [ -f "$script_dir/go.mod" ] && [ -f "$script_dir/.unix-sync.json" ]; then
    source_dir=$script_dir
    return
  fi
  if [ -d "$source_dir/.git" ]; then
    return
  fi
  if [ -e "$source_dir" ]; then
    echo "unix-sync: source path exists but is not a Git checkout: $source_dir" >&2
    exit 1
  fi
  mkdir -p "$(dirname -- "$source_dir")"
  git clone --branch "$ref" --depth 1 "$repository" "$source_dir"
}

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    return
  fi
  echo "Installing chezmoi into $bin_dir"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$bin_dir"
}

install_unix_sync() {
  mkdir -p "$bin_dir"
  if command -v go >/dev/null 2>&1; then
    echo "Building unix-sync from $source_dir"
    (cd "$source_dir" && go build -o "$bin_dir/unix-sync" ./cmd/unix-sync)
    return
  fi

  case "$(uname -s)" in
    Darwin) target_os=darwin ;;
    Linux) target_os=linux ;;
    *) echo "unix-sync: no release binary for $(uname -s)" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) target_arch=amd64 ;;
    arm64|aarch64) target_arch=arm64 ;;
    *) echo "unix-sync: unsupported architecture $(uname -m)" >&2; exit 1 ;;
  esac

  temporary_dir=$(mktemp -d)
  trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM
  archive="$temporary_dir/unix-sync.tar.gz"
  release_url="https://github.com/Elliot-Wang/unix-config-sync/releases/latest/download/unix-sync_${target_os}_${target_arch}.tar.gz"
  echo "Downloading $release_url"
  curl -fL "$release_url" -o "$archive"
  tar -xzf "$archive" -C "$temporary_dir"
  install -m 0755 "$temporary_dir/unix-sync" "$bin_dir/unix-sync"
}

install_bootstrap_dependencies
resolve_source
mkdir -p "$bin_dir"
export PATH="$bin_dir:$PATH"
install_chezmoi
install_unix_sync

"$bin_dir/unix-sync" settings --source "$source_dir" "$@"
exec "$bin_dir/unix-sync" --source "$source_dir"
