#!/bin/bash
# Claude Code status line — receives session JSON on stdin.
# Shows: model id + display name, cwd, total in/out tokens, context %,
# effort level, thinking enabled, 5h/7d rate-limit usage.
# Fields per https://code.claude.com/docs/en/statusline

input=$(cat)

IFS=$'\t' read -r MODEL_ID MODEL_NAME CWD IN_TOK OUT_TOK CTX_PCT EFFORT THINKING RL5 RL7 <<EOF
$(echo "$input" | jq -r '[
    (.model.id // "?"),
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // "?"),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    ((.context_window.used_percentage // 0) | floor),
    (.effort.level // "-"),
    (if .thinking.enabled then "on" else "off" end),
    (.rate_limits.five_hour.used_percentage | if . == null then "-" else (. | floor | tostring) end),
    (.rate_limits.seven_day.used_percentage | if . == null then "-" else (. | floor | tostring) end)
] | @tsv')
EOF

# Shorten home dir to ~
CWD="${CWD/#$HOME/~}"

# Humanize token counts (12345 -> 12.3k, 1234567 -> 1.2M)
fmt_tokens() {
    local n=$1
    if (( n >= 1000000 )); then
        printf '%.1fM' "$(echo "$n / 1000000" | bc -l)"
    elif (( n >= 1000 )); then
        printf '%.1fk' "$(echo "$n / 1000" | bc -l)"
    else
        printf '%d' "$n"
    fi
}

IN_FMT=$(fmt_tokens "$IN_TOK")
OUT_FMT=$(fmt_tokens "$OUT_TOK")

# Color context % by pressure: green < 50, yellow < 80, red >= 80
if (( CTX_PCT >= 80 )); then
    CTX_COLOR='\033[31m'
elif (( CTX_PCT >= 50 )); then
    CTX_COLOR='\033[33m'
else
    CTX_COLOR='\033[32m'
fi

DIM='\033[2m'
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
RESET='\033[0m'
SEP="${DIM} | ${RESET}"

RL5_FMT="$RL5"; [ "$RL5" != "-" ] && RL5_FMT="${RL5}%"
RL7_FMT="$RL7"; [ "$RL7" != "-" ] && RL7_FMT="${RL7}%"

printf "${CYAN}%s${RESET} ${DIM}(%s)${RESET}${SEP}${BLUE}%s${RESET}${SEP}↑%s ↓%s${SEP}ctx ${CTX_COLOR}%s%%${RESET}${SEP}effort ${MAGENTA}%s${RESET}${SEP}think %s${SEP}5h %s${SEP}7d %s" \
    "$MODEL_NAME" "$MODEL_ID" "$CWD" "$IN_FMT" "$OUT_FMT" "$CTX_PCT" "$EFFORT" "$THINKING" "$RL5_FMT" "$RL7_FMT"
