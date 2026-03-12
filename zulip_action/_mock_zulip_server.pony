use lori = "lori"

interface tag _MockServerNotify
  """
  Callback interface for mock server lifecycle events.
  """
  be server_listening(port: U16)
  be server_listen_failed()

actor _MockZulipServer is lori.TCPListenerActor
  """
  Mock HTTP server for testing ZulipClient.

  Listens on a random port, accepts connections, and responds to each
  HTTP request with a canned JSON response body. Used in integration
  tests to verify the client's request/response handling without
  connecting to a real Zulip instance.
  """
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _server_auth: lori.TCPServerAuth
  let _response_body: String
  let _notify: _MockServerNotify tag

  new create(
    auth: lori.TCPListenAuth,
    notify: _MockServerNotify tag,
    response_body: String)
  =>
    _server_auth = lori.TCPServerAuth(auth)
    _response_body = response_body
    _notify = notify
    _tcp_listener = lori.TCPListener(auth, "127.0.0.1", "0", this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_listening() =>
    _notify.server_listening(
      _tcp_listener.local_address().port())

  fun ref _on_listen_failure() =>
    _notify.server_listen_failed()

  fun ref _on_accept(fd: U32): _MockZulipConnection =>
    _MockZulipConnection(_server_auth, fd, _response_body)

actor _MockDropServer is lori.TCPListenerActor
  """
  Mock server that accepts TCP connections and closes them immediately
  without sending a response. Used to test the client's `on_closed()`
  handler when the connection drops unexpectedly.
  """
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _server_auth: lori.TCPServerAuth
  let _notify: _MockServerNotify tag

  new create(
    auth: lori.TCPListenAuth,
    notify: _MockServerNotify tag)
  =>
    _server_auth = lori.TCPServerAuth(auth)
    _notify = notify
    _tcp_listener = lori.TCPListener(auth, "127.0.0.1", "0", this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_listening() =>
    _notify.server_listening(
      _tcp_listener.local_address().port())

  fun ref _on_listen_failure() =>
    _notify.server_listen_failed()

  fun ref _on_accept(fd: U32): _MockDropConnection =>
    _MockDropConnection(_server_auth, fd)

actor _MockDropConnection is
  (lori.TCPConnectionActor & lori.ServerLifecycleEventReceiver)
  """
  Server-side connection that closes immediately after accepting,
  without sending any response data.
  """
  var _conn: lori.TCPConnection = lori.TCPConnection.none()

  new create(auth: lori.TCPServerAuth, fd: U32) =>
    _conn = lori.TCPConnection.server(auth, fd, this, this)
    _close_now()

  be _close_now() =>
    _conn.close()

  fun ref _connection(): lori.TCPConnection => _conn

actor _MockZulipConnection is
  (lori.TCPConnectionActor & lori.ServerLifecycleEventReceiver)
  """
  Server-side connection handler for the mock Zulip server.

  Accumulates incoming data until the HTTP header terminator
  (`\\r\\n\\r\\n`) is detected, then sends a canned HTTP response
  and closes the connection.
  """
  var _conn: lori.TCPConnection = lori.TCPConnection.none()
  let _response_body: String
  var _data: Array[U8] = Array[U8]
  var _responded: Bool = false

  new create(
    auth: lori.TCPServerAuth,
    fd: U32,
    response_body: String)
  =>
    _response_body = response_body
    _conn = lori.TCPConnection.server(auth, fd, this, this)

  fun ref _connection(): lori.TCPConnection => _conn

  fun ref _on_received(data: Array[U8] iso) =>
    _data.append(consume data)
    if (not _responded) and _contains_header_end() then
      _responded = true
      _send_response()
    end

  fun _contains_header_end(): Bool =>
    """
    Check whether the accumulated data contains the HTTP header
    terminator `\\r\\n\\r\\n`.
    """
    if _data.size() < 4 then return false end
    try
      var i: USize = 0
      while i <= (_data.size() - 4) do
        if (_data(i)? == '\r') and (_data(i + 1)? == '\n')
          and (_data(i + 2)? == '\r') and (_data(i + 3)? == '\n')
        then
          return true
        end
        i = i + 1
      end
    else
      _Unreachable()
    end
    false

  fun ref _send_response() =>
    let response: String val =
      recover val
        "HTTP/1.1 200 OK\r\n"
          + "Content-Type: application/json\r\n"
          + "Connection: close\r\n"
          + "Content-Length: "
          + _response_body.size().string()
          + "\r\n\r\n"
          + _response_body
      end
    _conn.send(response)
    _conn.close()
