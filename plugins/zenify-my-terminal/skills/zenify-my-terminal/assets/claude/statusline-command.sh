#!/bin/sh
# Claude Code statusline — themed.
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "sh ~/.claude/statusline-command.sh [theme]" }
#
# Themes: pure (default), powerline, rainbow, terminal, panels, minimal
# powerline & panels look best in a Nerd Font (use  arrow separator).
#
# THEME-AWARENESS: pure, powerline, terminal, panels, and minimal use ANSI
# base color codes (30-37, 90-97) which the terminal renders from its active
# palette — change your terminal theme and the statusline colors follow.
# rainbow uses 256-color indices (\033[38;5;NNNm) which stay fixed
# regardless of terminal theme.
#
# panels is the most graphical: filled backgrounds per segment with
# Nerd Font icons, but compact enough to fit 80-col terminals.

input=$(cat)
theme="${1:-pure}"

# ---------- Parse the JSON payload ----------
model=$(echo "$input"           | jq -r '.model.display_name // .model.id // "Unknown"')
used=$(echo "$input"            | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input"        | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"        | jq -r '.rate_limits.seven_day.used_percentage // empty')
worktree_name=$(echo "$input"   | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)

case "$effort" in
  low)    effort_label="low effort"    ;;
  medium) effort_label="medium effort" ;;
  high)   effort_label="high effort"   ;;
  *)      effort_label=""              ;;
esac

# ---------- Helpers ----------
to_int() { [ -z "$1" ] && echo "" || printf "%.0f" "$1"; }
used_int=$(to_int "$used")
five_int=$(to_int "$five_pct")
week_int=$(to_int "$week_pct")

color_fg_for_pct() {
  pct="$1"
  if [ "$pct" -le 50 ]; then echo "32"
  elif [ "$pct" -le 80 ]; then echo "33"
  else echo "31"
  fi
}

build_bar() {
  pct="$1"
  filled=$(( pct / 5 ))
  empty=$(( 20 - filled ))
  bar=""
  i=0; while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i+1)); done
  i=0; while [ $i -lt $empty  ]; do bar="${bar}░"; i=$((i+1)); done
  printf "%s" "$bar"
}

# ---------- Themes ----------
case "$theme" in

  # PURE: dim labels, color-coded bar (green/yellow/red), percentages.
  pure)
    if [ -n "$used_int" ]; then
      c=$(color_fg_for_pct "$used_int"); bar=$(build_bar "$used_int")
      ctx="\033[${c}m[${bar}] ${used_int}%\033[0m"
    else
      ctx="\033[2m[░░░░░░░░░░░░░░░░░░░░] -\033[0m"
    fi
    rate=""
    if [ -n "$five_int" ]; then
      c=$(color_fg_for_pct "$five_int")
      rate="\033[2m5h:\033[0m \033[${c}m${five_int}%\033[0m"
    fi
    if [ -n "$week_int" ]; then
      c=$(color_fg_for_pct "$week_int")
      [ -n "$rate" ] && rate="${rate}  "
      rate="${rate}\033[2m7d:\033[0m \033[${c}m${week_int}%\033[0m"
    fi
    out="\033[2m${model}\033[0m  ${ctx}"
    [ -n "$rate"            ] && out="${out}  ${rate}"
    [ -n "$worktree_name"   ] && out="${out}  \033[2mworktree:\033[0m \033[36m${worktree_name}\033[0m"
    [ -n "$worktree_branch" ] && out="${out} \033[2m(\033[0m\033[35m${worktree_branch}\033[0m\033[2m)\033[0m"
    [ -n "$effort_label"    ] && out="${out}  \033[2m${effort_label}\033[0m"
    printf "%b" "$out"
    ;;

  # POWERLINE: filled-background segments with Nerd Font  separator.
  # bg colors used (ANSI 4x): 0=black, 4=blue, 3=yellow, 2=green, 6=cyan, 5=magenta
  powerline)
    sep=""
    out=""
    prev_bg=""

    push_seg() {
      bg="$1"; fg="$2"; text="$3"
      if [ -n "$prev_bg" ]; then
        out="${out}\033[${prev_bg};3${bg}m${sep}\033[0m"
      fi
      out="${out}\033[4${bg};3${fg}m ${text} \033[0m"
      prev_bg="4${bg}"
    }

    push_seg 0 7 "${model}"
    if [ -n "$used_int" ]; then
      push_seg 4 7 "$(build_bar "$used_int") ${used_int}%"
    fi
    [ -n "$five_int"        ] && push_seg 3 0 "5h ${five_int}%"
    [ -n "$week_int"        ] && push_seg 2 0 "7d ${week_int}%"
    [ -n "$worktree_name"   ] && push_seg 6 0 " ${worktree_name}"
    [ -n "$worktree_branch" ] && push_seg 5 0 " ${worktree_branch}"
    [ -n "$effort_label"    ] && push_seg 0 7 "⚡ ${effort_label}"

    if [ -n "$prev_bg" ]; then
      last_fg=$(echo "$prev_bg" | sed 's/^4/3/')
      out="${out}\033[${last_fg};49m${sep}\033[0m"
    fi
    printf "%b" "$out"
    ;;

  # RAINBOW: bright fixed colors per segment, no state-based coloring.
  rainbow)
    out="\033[38;5;203m${model}\033[0m"
    if [ -n "$used_int" ]; then
      bar=$(build_bar "$used_int")
      out="${out}  \033[38;5;215m[${bar}] ${used_int}%\033[0m"
    fi
    [ -n "$five_int"        ] && out="${out}  \033[38;5;221m5h ${five_int}%\033[0m"
    [ -n "$week_int"        ] && out="${out}  \033[38;5;120m7d ${week_int}%\033[0m"
    [ -n "$worktree_name"   ] && out="${out}  \033[38;5;117m${worktree_name}\033[0m"
    [ -n "$worktree_branch" ] && out="${out}  \033[38;5;141m${worktree_branch}\033[0m"
    [ -n "$effort_label"    ] && out="${out}  \033[38;5;213m${effort_label}\033[0m"
    printf "%b" "$out"
    ;;

  # TERMINAL: rainbow-style multi-color per segment, but uses ANSI base
  # colors so the terminal's active theme palette (Tokyo Night, Dracula,
  # Solarized, etc.) drives the actual hues. COMPACT layout — fits in
  # 80-col terminals where the wider rainbow theme would get truncated by
  # Claude Code.
  #   - Model name: parenthetical info stripped (e.g. "Opus 4.7" not
  #     "Opus 4.7 (1M context)")
  #   - Bar: 12 chars (build_bar emits 20; we slice in this theme only)
  #   - Effort: "⚡h" / "⚡m" / "⚡l" / "⚡x" (single letter)
  # Color choices: 91=bright red (model), 93=bright yellow (context bar),
  # 33=yellow (5h), 32=green (7d), 96=bright cyan (worktree), 95=bright
  # magenta (branch), 35=magenta (effort).
  terminal)
    short_model=$(printf '%s' "$model" | sed 's/ *(.*)//')
    out="\033[91m${short_model}\033[0m"
    if [ -n "$used_int" ]; then
      filled=$(( used_int * 12 / 100 )); empty=$(( 12 - filled ))
      sbar=""
      i=0; while [ $i -lt $filled ]; do sbar="${sbar}█"; i=$((i+1)); done
      i=0; while [ $i -lt $empty  ]; do sbar="${sbar}░"; i=$((i+1)); done
      out="${out}  \033[93m[${sbar}] ${used_int}%\033[0m"
    fi
    [ -n "$five_int"        ] && out="${out}  \033[33m5h ${five_int}%\033[0m"
    [ -n "$week_int"        ] && out="${out}  \033[32m7d ${week_int}%\033[0m"
    [ -n "$worktree_name"   ] && out="${out}  \033[96m${worktree_name}\033[0m"
    [ -n "$worktree_branch" ] && out="${out}  \033[95m${worktree_branch}\033[0m"
    if [ -n "$effort" ]; then
      case "$effort" in
        low)    e="l" ;;
        medium) e="m" ;;
        high)   e="h" ;;
        xhigh)  e="x" ;;
        *)      e="?" ;;
      esac
      out="${out}  \033[35m⚡${e}\033[0m"
    fi
    printf "%b" "$out"
    ;;

  # PANELS: powerline-style filled backgrounds with Nerd Font separators
  # AND per-segment icons. Uses ANSI base colors (4X bg / 3Y fg) so the
  # terminal palette drives the actual hues. Compact enough for 80 cols.
  # Each segment has its own background color and a leading icon.
  panels)
    sep=""
    out=""
    prev_bg=""

    short_model=$(printf '%s' "$model" | sed 's/ *(.*)//')

    push_seg() {
      bg="$1"; fg="$2"; text="$3"
      if [ -n "$prev_bg" ]; then
        out="${out}\033[${prev_bg};3${bg}m${sep}\033[0m"
      fi
      out="${out}\033[4${bg};3${fg}m ${text} \033[0m"
      prev_bg="4${bg}"
    }

    # Model — black bg, white fg, robot-ish glyph
    push_seg 0 7 "󰚩 ${short_model}"

    # Context — blue bg, white fg, 10-char compact bar
    if [ -n "$used_int" ]; then
      filled=$(( used_int * 10 / 100 )); empty=$(( 10 - filled ))
      sbar=""
      i=0; while [ $i -lt $filled ]; do sbar="${sbar}█"; i=$((i+1)); done
      i=0; while [ $i -lt $empty  ]; do sbar="${sbar}░"; i=$((i+1)); done
      push_seg 4 7 "󰍛 ${sbar} ${used_int}%"
    fi

    # Rate limits — yellow / green bg, black fg, clock + calendar
    [ -n "$five_int"        ] && push_seg 3 0 " ${five_int}%"
    [ -n "$week_int"        ] && push_seg 2 0 " ${week_int}%"

    # Worktree — cyan bg, branch — magenta bg
    [ -n "$worktree_name"   ] && push_seg 6 0 " ${worktree_name}"
    [ -n "$worktree_branch" ] && push_seg 5 0 " ${worktree_branch}"

    # Effort — black bg, single-letter glyph
    if [ -n "$effort" ]; then
      case "$effort" in
        low) e="l" ;; medium) e="m" ;; high) e="h" ;; xhigh) e="x" ;; *) e="?" ;;
      esac
      push_seg 0 7 "⚡${e}"
    fi

    if [ -n "$prev_bg" ]; then
      last_fg=$(echo "$prev_bg" | sed 's/^4/3/')
      out="${out}\033[${last_fg};49m${sep}\033[0m"
    fi
    printf "%b" "$out"
    ;;

  # MINIMAL: model · pct% · branch · effort. Single dim middle-dot separator.
  minimal)
    out="\033[2m${model}\033[0m"
    if [ -n "$used_int" ]; then
      c=$(color_fg_for_pct "$used_int")
      out="${out} \033[2m·\033[0m \033[${c}m${used_int}%\033[0m"
    fi
    [ -n "$worktree_branch" ] && out="${out} \033[2m·\033[0m \033[35m${worktree_branch}\033[0m"
    [ -n "$effort_label"    ] && out="${out} \033[2m·\033[0m \033[2m${effort_label}\033[0m"
    printf "%b" "$out"
    ;;

  *)
    echo "Unknown theme: $theme" >&2
    echo "Available themes: pure, powerline, rainbow, terminal, panels, minimal" >&2
    exit 1
    ;;
esac
