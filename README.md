# zulip-action

A GitHub Action for sending messages to Zulip, written in [Pony](https://www.ponylang.io/).

## Status

zulip-action is in early development and has not yet been released.

## Usage

```yaml
- uses: ponylang/zulip-action@0.1.0
  with:
    api-key: ${{ secrets.ZULIP_API_KEY }}
    email: 'bot@example.zulipchat.com'
    organization-url: 'https://example.zulipchat.com'
    to: 'general'
    type: 'stream'
    topic: 'deployments'
    content: 'Deploy succeeded for ${{ github.sha }}'
```

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `api-key` | Yes | Zulip bot API key |
| `email` | Yes | Email of the bot that owns the API key |
| `organization-url` | Yes | Zulip organization URL (e.g., `https://myorg.zulipchat.com`) |
| `to` | Yes | Stream name/ID (for stream/channel) or comma-separated user IDs/emails (for private/direct) |
| `type` | Yes | Message type: `stream`, `channel`, `private`, or `direct` |
| `topic` | No | Message topic (required for stream/channel messages) |
| `content` | Yes | Message content |

The `channel` type is an alias for `stream`, and `direct` is an alias for `private`.

For private/direct messages, `to` accepts a comma-separated list of user IDs or email addresses. If all values are numeric, they are sent as integer IDs; otherwise they are sent as email strings.
