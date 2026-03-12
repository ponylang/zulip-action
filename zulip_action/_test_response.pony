use courier = "courier"
use json = "json"
use "pony_test"

primitive \nodoc\ _TestResponseSuite
  fun tests(test: PonyTest) =>
    test(_TestResponseSuccess)
    test(_TestResponseErrorWithCode)
    test(_TestResponseErrorWithoutCode)
    test(_TestResponseMissingResult)
    test(_TestResponseMalformedJson)

class \nodoc\ iso _TestResponseSuccess is UnitTest
  fun name(): String => "response/success"

  fun ref apply(h: TestHelper) =>
    let body = """{"id":42,"msg":"","result":"success"}"""
    match json.JsonParser.parse(body)
    | let value: json.JsonValue =>
      match ZulipResponseDecoder(value)
      | let resp: ZulipResponse =>
        match resp.result
        | let s: ZulipSuccess =>
          h.assert_eq[I64](42, s.id)
        | let _: ZulipError =>
          h.fail("expected ZulipSuccess")
        end
      | let err: courier.JSONDecodeError =>
        h.fail("decode error: " + err.string())
      end
    | let err: json.JsonParseError =>
      h.fail("parse error: " + err.string())
    end

class \nodoc\ iso _TestResponseErrorWithCode is UnitTest
  fun name(): String => "response/error with code"

  fun ref apply(h: TestHelper) =>
    let body =
      """{"code":"STREAM_DOES_NOT_EXIST","""
        + """"msg":"Channel does not exist","""
        + """"result":"error"}"""
    match json.JsonParser.parse(body)
    | let value: json.JsonValue =>
      match ZulipResponseDecoder(value)
      | let resp: ZulipResponse =>
        match resp.result
        | let _: ZulipSuccess =>
          h.fail("expected ZulipError")
        | let e: ZulipError =>
          h.assert_eq[String](
            "STREAM_DOES_NOT_EXIST", e.code)
          h.assert_eq[String](
            "Channel does not exist", e.msg)
        end
      | let err: courier.JSONDecodeError =>
        h.fail("decode error: " + err.string())
      end
    | let err: json.JsonParseError =>
      h.fail("parse error: " + err.string())
    end

class \nodoc\ iso _TestResponseErrorWithoutCode is UnitTest
  fun name(): String => "response/error without code"

  fun ref apply(h: TestHelper) =>
    let body =
      """{"msg":"Something went wrong","result":"error"}"""
    match json.JsonParser.parse(body)
    | let value: json.JsonValue =>
      match ZulipResponseDecoder(value)
      | let resp: ZulipResponse =>
        match resp.result
        | let _: ZulipSuccess =>
          h.fail("expected ZulipError")
        | let e: ZulipError =>
          h.assert_eq[String]("", e.code)
          h.assert_eq[String](
            "Something went wrong", e.msg)
        end
      | let err: courier.JSONDecodeError =>
        h.fail("decode error: " + err.string())
      end
    | let err: json.JsonParseError =>
      h.fail("parse error: " + err.string())
    end

class \nodoc\ iso _TestResponseMissingResult is UnitTest
  fun name(): String => "response/missing result field"

  fun ref apply(h: TestHelper) =>
    let body = """{"id":42,"msg":""}"""
    match json.JsonParser.parse(body)
    | let value: json.JsonValue =>
      match ZulipResponseDecoder(value)
      | let _: ZulipResponse =>
        h.fail("expected decode error")
      | let _: courier.JSONDecodeError =>
        None // expected
      end
    | let err: json.JsonParseError =>
      h.fail("parse error: " + err.string())
    end

class \nodoc\ iso _TestResponseMalformedJson is UnitTest
  fun name(): String => "response/malformed json"

  fun ref apply(h: TestHelper) =>
    let body = "not json at all"
    match json.JsonParser.parse(body)
    | let _: json.JsonValue =>
      h.fail("expected parse error")
    | let _: json.JsonParseError =>
      None // expected
    end
