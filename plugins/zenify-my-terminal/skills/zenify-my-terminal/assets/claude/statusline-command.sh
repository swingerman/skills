#!/bin/sh
input=$(cat)

# Model name — read from per-instance JSON payload (unique per session)
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "Unknown"')

# Context usage percentage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Effort level — read from settings file (not in statusline JSON payload)
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
case "$effort" in
  low)    effort_label="low effort" ;;
  medium) effort_label="medium effort" ;;
  high)   effort_label="high effort" ;;
  *)      effort_label="" ;;
esac

# Worktree and branch info
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Build context bar with color coding
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar_filled=$(( used_int / 5 ))
  bar_empty=$(( 20 - bar_filled ))

  # Color: green <=50%, yellow <=80%, red >80%
  if [ "$used_int" -le 50 ]; then
    bar_color="\033[32m"   # green
  elif [ "$used_int" -le 80 ]; then
    bar_color="\033[33m"   # yellow
  else
    bar_color="\033[31m"   # red
  fi

  bar=""
  i=0
  while [ $i -lt $bar_filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $bar_empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done

  ctx_part="${bar_color}[${bar}] ${used_int}%\033[0m"
else
  ctx_part="\033[2m[░░░░░░░░░░░░░░░░░░░░] -\033[0m"
fi

# Rate limit percentages (Claude.ai subscription: 5-hour session and 7-day weekly)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rate_part=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  if [ -n "$five_pct" ]; then
    five_int=$(printf "%.0f" "$five_pct")
    if [ "$five_int" -le 50 ]; then
      five_color="\033[32m"
    elif [ "$five_int" -le 80 ]; then
      five_color="\033[33m"
    else
      five_color="\033[31m"
    fi
    rate_part="\033[2m5h:\033[0m ${five_color}${five_int}%\033[0m"
  fi
  if [ -n "$week_pct" ]; then
    week_int=$(printf "%.0f" "$week_pct")
    if [ "$week_int" -le 50 ]; then
      week_color="\033[32m"
    elif [ "$week_int" -le 80 ]; then
      week_color="\033[33m"
    else
      week_color="\033[31m"
    fi
    if [ -n "$rate_part" ]; then
      rate_part="${rate_part}  \033[2m7d:\033[0m ${week_color}${week_int}%\033[0m"
    else
      rate_part="\033[2m7d:\033[0m ${week_color}${week_int}%\033[0m"
    fi
  fi
fi

# Assemble the status line
output="\033[2m${model}\033[0m  ${ctx_part}"

# Append rate limits if available
if [ -n "$rate_part" ]; then
  output="${output}  ${rate_part}"
fi

# Append worktree / branch if present
if [ -n "$worktree_name" ] && [ -n "$worktree_branch" ]; then
  output="${output}  \033[2mworktree:\033[0m \033[36m${worktree_name}\033[0m \033[2m(\033[0m\033[35m${worktree_branch}\033[0m\033[2m)\033[0m"
elif [ -n "$worktree_name" ]; then
  output="${output}  \033[2mworktree:\033[0m \033[36m${worktree_name}\033[0m"
elif [ -n "$worktree_branch" ]; then
  output="${output}  \033[35m${worktree_branch}\033[0m"
fi

# Append effort label if present
if [ -n "$effort_label" ]; then
  output="${output}  \033[2m${effort_label}\033[0m"
fi

printf "%b" "${output}"
