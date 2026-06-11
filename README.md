# claude-statusline

Custom [status line](https://code.claude.com/docs/en/statusline) for Claude Code.

Displays: model display name + id, current directory, total input/output tokens,
context window used % (color-coded), effort level, thinking on/off, and 5-hour /
7-day rate-limit usage.

```
Fable 5 (claude-fable-5) | ~/Documents/Github/akam-proxy | ↑45.2k ↓3.1k | ctx 22% | effort xhigh | think on | 5h 12% | 7d 38%
```

## Install

The live script is symlinked from this repo:

```sh
ln -sf "$(pwd)/statusline.sh" ~/.claude/statusline.sh
```

And registered in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/toosakarin/.claude/statusline.sh"
  }
}
```

Requires `jq`.

## Test

```sh
echo '{"model":{"id":"claude-fable-5","display_name":"Fable 5"},"workspace":{"current_dir":"/tmp"}}' | ./statusline.sh
```

Missing fields (effort, rate limits, context) degrade gracefully to `-` / `0`.
