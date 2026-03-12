use "collections"

class val Input
  """
  Validated Zulip message parameters.

  Constructed via `InputParser` from GitHub Actions environment variables.
  All fields are guaranteed valid at construction time: required fields
  are present and non-empty, `api_type` is one of `"stream"` or
  `"private"`, `topic` is present when `api_type` is `"stream"`, and
  `to` is formatted for the Zulip API (JSON array for private messages).
  """
  let api_key: String
  let email: String
  let organization_url: String
  let to: String
  let api_type: String
  let topic: (String | None)
  let content: String

  new val _create(
    api_key': String,
    email': String,
    organization_url': String,
    to': String,
    api_type': String,
    topic': (String | None),
    content': String)
  =>
    api_key = api_key'
    email = email'
    organization_url = organization_url'
    to = to'
    api_type = api_type'
    topic = topic'
    content = content'

primitive InputParser
  """
  Parse and validate GitHub Actions input environment variables into
  an `Input`.

  GitHub Actions passes action inputs as environment variables named
  `INPUT_<NAME>` where `<NAME>` is the uppercased input name with
  hyphens preserved. For example, `api-key` becomes `INPUT_API-KEY`.

  Returns a validated `Input` on success or an error message on failure.
  """
  fun apply(vars: Map[String, String] box): (Input val | String) =>
    """
    Parse environment variables into a validated `Input`, or return an
    error message describing the first validation failure.
    """
    let api_key =
      try _require(vars, "INPUT_API-KEY")?
      else return "input \"api-key\" must be provided and non-empty"
      end
    let email =
      try _require(vars, "INPUT_EMAIL")?
      else return "input \"email\" must be provided and non-empty"
      end
    let organization_url =
      try _require(vars, "INPUT_ORGANIZATION-URL")?
      else
        return
          "input \"organization-url\" must be provided and non-empty"
      end
    let to_raw =
      try _require(vars, "INPUT_TO")?
      else return "input \"to\" must be provided and non-empty"
      end
    let type_raw =
      try _require(vars, "INPUT_TYPE")?
      else return "input \"type\" must be provided and non-empty"
      end
    let content =
      try _require(vars, "INPUT_CONTENT")?
      else return "input \"content\" must be provided and non-empty"
      end

    let api_type =
      match type_raw
      | "stream" => "stream"
      | "channel" => "stream"
      | "private" => "private"
      | "direct" => "private"
      else
        return
          "input \"type\" must be one of: "
            + "stream, channel, private, direct"
      end

    let topic: (String | None) =
      try
        let t = vars("INPUT_TOPIC")?
        if t.size() > 0 then t else None end
      else
        None
      end

    if api_type == "stream" then
      match topic
      | None =>
        return
          "input \"topic\" is required when type is "
            + "\"stream\" or \"channel\""
      end
    end

    let to =
      if api_type == "private" then
        _format_private_to(to_raw)
      else
        to_raw
      end

    Input._create(
      api_key,
      email,
      organization_url,
      to,
      api_type,
      topic,
      content)

  fun _require(vars: Map[String, String] box, key: String): String ? =>
    """
    Look up `key` in `vars` and return its value. Errors if the key is
    missing or the value is empty.
    """
    let value = vars(key)?
    if value.size() == 0 then error end
    value

  fun _format_private_to(raw: String): String =>
    """
    Format the `to` field for private/direct messages as a JSON array.

    The Zulip API expects private message recipients as a JSON array.
    Input is a comma-separated string of user IDs or emails. Parts are
    trimmed of surrounding whitespace so `"1, 2, 3"` works the same as
    `"1,2,3"`. If all items are numeric, formats as `[1, 2, 3]`;
    otherwise formats as `["a@b.com", "c@d.com"]`.
    """
    let raw_parts = raw.split(",")
    let parts = recover val
      let trimmed = Array[String](raw_parts.size())
      for part in (consume raw_parts).values() do
        trimmed.push(part.clone().>strip())
      end
      trimmed
    end
    var all_numeric = true
    for part in parts.values() do
      if not _is_numeric(part) then
        all_numeric = false
        break
      end
    end

    recover val
      let result = String
      result.append("[")
      var first = true
      for part in parts.values() do
        if not first then result.append(", ") end
        if all_numeric then
          result.append(part)
        else
          result.append("\"")
          result.append(part)
          result.append("\"")
        end
        first = false
      end
      result.append("]")
      result
    end

  fun _is_numeric(s: String box): Bool =>
    """
    True if `s` is non-empty and contains only ASCII digits.
    """
    if s.size() == 0 then return false end
    for byte in s.values() do
      if (byte < '0') or (byte > '9') then return false end
    end
    true
