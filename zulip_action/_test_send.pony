use lori = "lori"
use "pony_test"

primitive \nodoc\ _TestSendSuite
  fun tests(test: PonyTest) =>
    test(_TestSendSuccess)
    test(_TestSendApiError)

class \nodoc\ iso _TestSendSuccess is UnitTest
  fun name(): String => "send/success via mock server"

  fun ref apply(h: TestHelper) =>
    h.long_test(5_000_000_000)
    let response = """{"id":42,"msg":"","result":"success"}"""
    _SendTestOrchestrator(h, response where
      expected_success = true, expected_id = "42")

class \nodoc\ iso _TestSendApiError is UnitTest
  fun name(): String => "send/api error via mock server"

  fun ref apply(h: TestHelper) =>
    h.long_test(5_000_000_000)
    let response =
      """{"code":"BAD_REQUEST","msg":"Invalid","result":"error"}"""
    _SendTestOrchestrator(h, response where
      expected_success = false,
      expected_failure_contains = "BAD_REQUEST")

actor \nodoc\ _SendTestOrchestrator is
  (ResultNotify & _MockServerNotify)
  """
  Coordinates a mock-server integration test.

  Creates a mock HTTP server, waits for it to start listening, then
  creates a ZulipClient that connects to it over plain TCP. Verifies
  the client's result notification matches expectations.
  """
  let _h: TestHelper
  let _response: String
  let _expected_success: Bool
  let _expected_id: String
  let _expected_failure_contains: String
  var _server: (_MockZulipServer | None) = None

  new create(
    h: TestHelper,
    response: String,
    expected_success: Bool = true,
    expected_id: String = "",
    expected_failure_contains: String = "")
  =>
    _h = h
    _response = response
    _expected_success = expected_success
    _expected_id = expected_id
    _expected_failure_contains = expected_failure_contains
    let auth = lori.TCPListenAuth(h.env.root)
    _server = _MockZulipServer(auth, this, response)

  be server_listening(port: U16) =>
    let input = Input._create(
      "test-api-key",
      "bot@example.com",
      "http://127.0.0.1:" + port.string(),
      "test-stream",
      "stream",
      "test-topic",
      "Hello from test")
    let auth = lori.TCPConnectAuth(_h.env.root)
    ZulipClient._test_plain(
      auth, "127.0.0.1", port.string(), input, this)

  be server_listen_failed() =>
    _h.fail("mock server failed to listen")
    _h.complete(true)

  be success(id: String) =>
    if _expected_success then
      _h.assert_eq[String](_expected_id, id)
    else
      _h.fail("expected failure but got success with id: " + id)
    end
    _dispose()

  be failure(msg: String) =>
    if not _expected_success then
      if _expected_failure_contains.size() > 0 then
        _h.assert_true(
          msg.contains(_expected_failure_contains),
          "expected failure containing '"
            + _expected_failure_contains
            + "' but got: " + msg)
      end
    else
      _h.fail("expected success but got failure: " + msg)
    end
    _dispose()

  fun ref _dispose() =>
    match _server
    | let s: _MockZulipServer => s.dispose()
    end
    _h.complete(true)
