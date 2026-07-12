#!/bin/bash
# Claude Code statusLine: cwd, git branch, model, context usage

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir_display=$(basename "$cwd")

branch=""
if [ -e "$cwd/.git" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')

used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Colors (dimmed to match terminal theme)
DIM=$'\033[2m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
MAGENTA=$'\033[0;35m'
RESET=$'\033[0m'

parts=()
if [ -n "$branch" ]; then
  parts+=("${BLUE}${dir_display}${RESET} ${BLUE}[${branch}]${RESET}")
else
  parts+=("${BLUE}${dir_display}${RESET}")
fi

if [ -n "$effort" ]; then
  parts+=("${MAGENTA}${model} [${effort}]${RESET}")
else
  parts+=("${MAGENTA}${model}${RESET}")
fi

ctx=$(printf "%.0f%% ctx" "$used")
parts+=("${GREEN}${ctx}${RESET}")

if [ -n "$five_hour" ]; then
  five=$(printf "5h %.0f%%" "$five_hour")
  parts+=("${YELLOW}${five}${RESET}")
fi

if [ -n "$seven_day" ]; then
  week=$(printf "7d %.0f%%" "$seven_day")
  parts+=("${YELLOW}${week}${RESET}")
fi

IFS=" ${DIM}|${RESET} "
printf "%s" "${parts[0]}"
for p in "${parts[@]:1}"; do
  printf " %s %s" "${DIM}|${RESET}" "$p"
done
printf "\n"
