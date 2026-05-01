#!/usr/bin/env bash
# Preview Oh My Posh themes by rendering each one to the terminal.
#
# Usage:
#   preview-themes.sh                         # curated set
#   preview-themes.sh theme1 theme2 ...       # specific themes by name (no .omp.json)
#   preview-themes.sh --all                   # every bundled theme (~125)
#   preview-themes.sh --p10k                  # just the powerlevel10k_* ports
#
# Requires `oh-my-posh` on PATH (brew install oh-my-posh).

set -euo pipefail

# Locate themes dir (handles Intel + Apple Silicon brew prefixes)
if [[ -d /opt/homebrew/opt/oh-my-posh/themes ]]; then
  THEMES_DIR=/opt/homebrew/opt/oh-my-posh/themes
elif [[ -d /usr/local/opt/oh-my-posh/themes ]]; then
  THEMES_DIR=/usr/local/opt/oh-my-posh/themes
else
  echo "Oh My Posh themes directory not found." >&2
  echo "Install with: brew install oh-my-posh" >&2
  exit 1
fi

# Pick the theme list
case "${1:-}" in
  --all)
    THEMES=()
    while IFS= read -r f; do
      THEMES+=("$(basename "$f" .omp.json)")
    done < <(ls "$THEMES_DIR"/*.omp.json | sort)
    ;;
  --p10k)
    THEMES=(powerlevel10k_lean powerlevel10k_classic powerlevel10k_modern powerlevel10k_rainbow)
    ;;
  "")
    # Curated representative set — diverse styles, popular picks
    THEMES=(
      pure
      powerlevel10k_lean
      powerlevel10k_classic
      powerlevel10k_modern
      powerlevel10k_rainbow
      atomic
      montys
      catppuccin
      tokyo
      night-owl
      paradox
      agnoster
      robbyrussell
      jandedobbeleer
      slim
    )
    ;;
  *)
    THEMES=("$@")
    ;;
esac

# Render each
for t in "${THEMES[@]}"; do
  config="$THEMES_DIR/$t.omp.json"
  if [[ ! -f "$config" ]]; then
    printf '\n\033[1;31m=== %s (NOT FOUND) ===\033[0m\n' "$t"
    continue
  fi
  # Cyan heading, then the rendered prompt
  printf '\n\033[1;36m=== %s ===\033[0m\n' "$t"
  oh-my-posh print primary --config "$config" 2>/dev/null \
    || printf '\033[31m(theme failed to render — may require segments not available here)\033[0m\n'
done

echo
echo "To use one of these, edit ~/.zshrc and change the --config path in the oh-my-posh init line:"
echo "  eval \"\$(oh-my-posh init zsh --config $THEMES_DIR/<theme>.omp.json)\""
