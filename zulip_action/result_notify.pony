interface tag ResultNotify
  """
  Notification interface for Zulip message send results.

  Implemented by actors that handle the outcome of a `ZulipClient`
  request. The production handler writes GitHub Actions workflow
  commands to stdout/stderr; test handlers record the result for
  assertion.
  """
  be success(id: String)
    """
    Called when the Zulip API returns a success response.

    `id` is the string representation of the message ID assigned by
    Zulip.
    """

  be failure(msg: String)
    """
    Called when the request fails at any stage: input validation,
    connection, HTTP parsing, or a Zulip API error response.

    `msg` is a human-readable description of what went wrong.
    """
