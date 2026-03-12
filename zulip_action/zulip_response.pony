use courier = "courier"
use json = "json"

class val ZulipSuccess
  """
  A successful Zulip API response.
  """
  let id: I64

  new val create(id': I64) =>
    id = id'

class val ZulipError
  """
  An error response from the Zulip API.
  """
  let code: String
  let msg: String

  new val create(code': String, msg': String) =>
    code = code'
    msg = msg'

type ZulipResult is (ZulipSuccess | ZulipError)

class val ZulipResponse
  """
  A decoded Zulip API response, either success or error.
  """
  let result: ZulipResult

  new val create(result': ZulipResult) =>
    result = result'

primitive ZulipResponseDecoder is courier.JSONDecoder[ZulipResponse]
  """
  Decode a Zulip API JSON response into a `ZulipResponse`.

  Success responses have `"result": "success"` and an integer `"id"`.
  Error responses have `"result": "error"`, a string `"msg"`, and
  optionally a string `"code"`.
  """
  fun apply(value: json.JsonValue)
    : (ZulipResponse | courier.JSONDecodeError)
  =>
    """
    Decode a parsed JSON value into a `ZulipResponse`.

    Returns `JSONDecodeError` if the JSON lacks the expected `"result"`
    string field.
    """
    let nav = json.JsonNav(value)
    try
      let result_str = nav("result").as_string()?
      if result_str == "success" then
        let id = try nav("id").as_i64()? else 0 end
        ZulipResponse(ZulipSuccess(id))
      else
        let msg =
          try nav("msg").as_string()?
          else "Unknown error"
          end
        let code =
          try nav("code").as_string()?
          else ""
          end
        ZulipResponse(ZulipError(code, msg))
      end
    else
      courier.JSONDecodeError(
        "expected object with string 'result' field")
    end
