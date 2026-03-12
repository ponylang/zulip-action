use courier = "courier"
use json = "json"
use lori = "lori"
use ssl = "ssl/net"

actor ZulipClient is courier.HTTPClientConnectionActor
  """
  HTTP client that sends a single message to the Zulip API.

  Connects to the Zulip server, POSTs to `/api/v1/messages` with
  HTTP Basic authentication and a form-encoded body, then notifies
  the `ResultNotify` handler with the outcome.

  For production use, create with `create` (HTTPS). For testing against
  a mock server, use `_test_plain` (plain TCP, package-private).
  """
  var _http: courier.HTTPClientConnection =
    courier.HTTPClientConnection.none()
  var _collector: courier.ResponseCollector = courier.ResponseCollector
  let _input: Input val
  let _notify: ResultNotify tag
  var _notified: Bool = false

  new create(
    auth: lori.TCPConnectAuth,
    ssl_ctx: ssl.SSLContext val,
    host: String,
    port: String,
    input: Input val,
    notify: ResultNotify tag)
  =>
    """
    Create a Zulip client with an HTTPS connection.
    """
    _input = input
    _notify = notify
    _http =
      courier.HTTPClientConnection.ssl(
        auth, ssl_ctx, host, port, this,
        courier.ClientConnectionConfig)

  new _test_plain(
    auth: lori.TCPConnectAuth,
    host: String,
    port: String,
    input: Input val,
    notify: ResultNotify tag)
  =>
    """
    Create a Zulip client with a plain TCP connection (for testing).
    """
    _input = input
    _notify = notify
    _http =
      courier.HTTPClientConnection(
        auth, host, port, this,
        courier.ClientConnectionConfig)

  fun ref _http_client_connection(): courier.HTTPClientConnection =>
    _http

  fun ref on_connected() =>
    let params = _build_params()
    let req =
      courier.Request.post("/api/v1/messages")
        .basic_auth(_input.email, _input.api_key)
        .form_body(params)
        .build()
    _http.send_request(req)

  fun ref on_connection_failure(
    reason: courier.ConnectionFailureReason)
  =>
    _notified = true
    let detail =
      match \exhaustive\ reason
      | courier.ConnectionFailedDNS => "DNS resolution failed"
      | courier.ConnectionFailedTCP => "TCP connection failed"
      | courier.ConnectionFailedSSL => "SSL handshake failed"
      end
    _notify.failure("Connection failed: " + detail)

  fun ref on_response(response: courier.Response val) =>
    _collector = courier.ResponseCollector
    _collector.set_response(response)

  fun ref on_body_chunk(data: Array[U8] val) =>
    _collector.add_chunk(data)

  fun ref on_response_complete() =>
    _notified = true
    try
      let response = _collector.build()?
      match courier.DecodeJSON[ZulipResponse](
        response, ZulipResponseDecoder)
      | let r: ZulipResponse =>
        match r.result
        | let s: ZulipSuccess =>
          _notify.success(s.id.string())
        | let e: ZulipError =>
          let detail =
            if e.code.size() > 0 then
              e.code + ": " + e.msg
            else
              e.msg
            end
          _notify.failure(detail)
        end
      | let err: json.JsonParseError =>
        _notify.failure(
          "Failed to parse Zulip response: " + err.string())
      | let err: courier.JSONDecodeError =>
        _notify.failure(
          "Unexpected Zulip response format: " + err.string())
      end
    else
      _notify.failure("Failed to build HTTP response")
    end
    _http.close()

  fun ref on_parse_error(err: courier.ParseError) =>
    _notified = true
    _notify.failure("HTTP parse error")

  fun ref on_closed() =>
    """
    Called when the connection closes for any reason. If the result has
    already been reported via another callback, this is a no-op.
    Otherwise, the connection was lost before a complete response was
    received.
    """
    if not _notified then
      _notified = true
      _notify.failure("Connection closed unexpectedly")
    end

  fun _build_params(): Array[(String, String)] val =>
    """
    Build the form-encoded parameters for the Zulip API request.
    """
    recover val
      let p = Array[(String, String)]
      p.push(("type", _input.api_type))
      p.push(("to", _input.to))
      match _input.topic
      | let t: String => p.push(("topic", t))
      end
      p.push(("content", _input.content))
      p
    end
