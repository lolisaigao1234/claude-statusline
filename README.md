# claude-statusline

Custom [status line](https://code.claude.com/docs/en/statusline) for Claude Code.

Displays: model display name + id, current directory, git branch, total
input/output tokens, context window used % (color-coded), effort level,
thinking on/off, 5-hour rate-limit usage **with its reset time**, and the
**model-scoped weekly limit** (e.g. Fable) instead of the all-models weekly limit.

```
Fable (claude-fable-5-1) | ~/Documents/Github/akam-proxy |  main | ↑45.2k ↓3.1k | ctx 22% | effort high | think on | 5h 17% (14:40) | Fable 56%
```

## Model-scoped weekly limit

The JSON Claude Code pipes into the status line only carries the 5-hour and
all-models 7-day figures. The per-model weekly bucket shown by `/usage` comes
from `GET https://api.anthropic.com/api/oauth/usage` (`limits[]` entry with
`kind == "weekly_scoped"`). The script:

- reads the OAuth token from `~/.claude/.credentials.json`,
- fetches the endpoint at most once per 60 s, in a detached background process,
  so the status line never blocks on the network (warm run ≈ 35 ms),
- caches the response at `${XDG_CACHE_HOME:-~/.cache}/claude-statusline-usage.json`,
- shows the server-supplied label for the scoped bucket,
- falls back to the all-models `7d NN%` figure if the cache is empty, the
  token is missing, or the fetch fails.

## 5-hour session reset

The reset time next to `5h` comes from `rate_limits.five_hour.resets_at` in the
status-line JSON (Unix seconds or ISO-8601 both handled), rendered in local
time as `HH:MM` if today, else `Ddd HH:MM`. If that field is absent, the
`session` entry from the cached usage response is used instead. The weekly
reset is fixed and therefore not shown.

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
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

Requires `python3`, `curl`, `git`, and `bc`. No `jq` dependency.

## Test

```sh
echo '{"model":{"id":"claude-fable-5-1","display_name":"Fable"},"workspace":{"current_dir":"/tmp"},"rate_limits":{"five_hour":{"used_percentage":17},"seven_day":{"used_percentage":31}}}' | ./statusline.sh
```

Missing fields (effort, rate limits, context) degrade gracefully to `-` / `0`.
The first run after a cold cache shows `7d NN%`; subsequent runs show the
model-scoped bucket once the background fetch has landed.
