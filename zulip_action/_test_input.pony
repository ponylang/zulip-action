use "collections"
use "pony_test"

primitive \nodoc\ _TestInputSuite
  fun tests(test: PonyTest) =>
    test(_TestValidStreamInput)
    test(_TestValidPrivateInput)
    test(_TestChannelMapsToStream)
    test(_TestDirectMapsToPrivate)
    test(_TestMissingApiKey)
    test(_TestMissingEmail)
    test(_TestMissingOrganizationUrl)
    test(_TestMissingTo)
    test(_TestMissingType)
    test(_TestMissingContent)
    test(_TestInvalidType)
    test(_TestMissingTopicForStream)
    test(_TestEmptyTopicForStream)
    test(_TestTopicNotRequiredForPrivate)
    test(_TestPrivateToNumericIds)
    test(_TestPrivateToEmails)
    test(_TestPrivateToMixedDefaultsToStrings)
    test(_TestPrivateToSingleId)
    test(_TestPrivateToSpacesAroundIds)
    test(_TestPrivateToSpacesAroundEmails)

primitive \nodoc\ _InputVars
  """
  Factory methods for test environment variable maps.
  """
  fun stream(): Map[String, String] ref =>
    let vars = Map[String, String]
    vars("INPUT_API-KEY") = "test-key"
    vars("INPUT_EMAIL") = "bot@example.com"
    vars("INPUT_ORGANIZATION-URL") = "https://example.zulipchat.com"
    vars("INPUT_TO") = "general"
    vars("INPUT_TYPE") = "stream"
    vars("INPUT_TOPIC") = "greetings"
    vars("INPUT_CONTENT") = "Hello"
    vars

  fun private(): Map[String, String] ref =>
    let vars = Map[String, String]
    vars("INPUT_API-KEY") = "test-key"
    vars("INPUT_EMAIL") = "bot@example.com"
    vars("INPUT_ORGANIZATION-URL") = "https://example.zulipchat.com"
    vars("INPUT_TO") = "1,2"
    vars("INPUT_TYPE") = "private"
    vars("INPUT_CONTENT") = "Hello"
    vars

class \nodoc\ iso _TestValidStreamInput is UnitTest
  fun name(): String => "input/valid stream"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("test-key", input.api_key)
      h.assert_eq[String]("bot@example.com", input.email)
      h.assert_eq[String](
        "https://example.zulipchat.com",
        input.organization_url)
      h.assert_eq[String]("general", input.to)
      h.assert_eq[String]("stream", input.api_type)
      h.assert_eq[String]("Hello", input.content)
      match input.topic
      | let t: String => h.assert_eq[String]("greetings", t)
      | None => h.fail("expected topic")
      end
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestValidPrivateInput is UnitTest
  fun name(): String => "input/valid private"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("[1, 2]", input.to)
      h.assert_eq[String]("private", input.api_type)
      match input.topic
      | let _: String => h.fail("expected no topic")
      | None => None
      end
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestChannelMapsToStream is UnitTest
  fun name(): String => "input/channel maps to stream"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    vars("INPUT_TYPE") = "channel"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("stream", input.api_type)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestDirectMapsToPrivate is UnitTest
  fun name(): String => "input/direct maps to private"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TYPE") = "direct"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("private", input.api_type)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestMissingApiKey is UnitTest
  fun name(): String => "input/missing api-key"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_API-KEY")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("api-key"))
    end

class \nodoc\ iso _TestMissingEmail is UnitTest
  fun name(): String => "input/missing email"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_EMAIL")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("email"))
    end

class \nodoc\ iso _TestMissingOrganizationUrl is UnitTest
  fun name(): String => "input/missing organization-url"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_ORGANIZATION-URL")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("organization-url"))
    end

class \nodoc\ iso _TestMissingTo is UnitTest
  fun name(): String => "input/missing to"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_TO")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("\"to\""))
    end

class \nodoc\ iso _TestMissingType is UnitTest
  fun name(): String => "input/missing type"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_TYPE")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("\"type\""))
    end

class \nodoc\ iso _TestMissingContent is UnitTest
  fun name(): String => "input/missing content"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_CONTENT")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("content"))
    end

class \nodoc\ iso _TestInvalidType is UnitTest
  fun name(): String => "input/invalid type"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    vars("INPUT_TYPE") = "invalid"
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("\"type\""))
    end

class \nodoc\ iso _TestMissingTopicForStream is UnitTest
  fun name(): String => "input/missing topic for stream"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    try vars.remove("INPUT_TOPIC")? end
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("topic"))
    end

class \nodoc\ iso _TestEmptyTopicForStream is UnitTest
  fun name(): String => "input/empty topic for stream"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.stream()
    vars("INPUT_TOPIC") = ""
    match InputParser(vars)
    | let _: Input => h.fail("expected error")
    | let err: String =>
      h.assert_true(err.contains("topic"))
    end

class \nodoc\ iso _TestTopicNotRequiredForPrivate is UnitTest
  fun name(): String => "input/topic not required for private"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    try vars.remove("INPUT_TOPIC")? end
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("private", input.api_type)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToNumericIds is UnitTest
  fun name(): String => "input/private to numeric ids"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "1,2,3"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("[1, 2, 3]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToEmails is UnitTest
  fun name(): String => "input/private to emails"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "a@b.com,c@d.com"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String](
        "[\"a@b.com\", \"c@d.com\"]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToMixedDefaultsToStrings is UnitTest
  fun name(): String =>
    "input/private to mixed defaults to strings"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "1,a@b.com"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String](
        "[\"1\", \"a@b.com\"]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToSingleId is UnitTest
  fun name(): String => "input/private to single id"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "42"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("[42]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToSpacesAroundIds is UnitTest
  fun name(): String => "input/private to spaces around ids"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "1, 2, 3"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String]("[1, 2, 3]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end

class \nodoc\ iso _TestPrivateToSpacesAroundEmails is UnitTest
  fun name(): String => "input/private to spaces around emails"

  fun ref apply(h: TestHelper) =>
    let vars = _InputVars.private()
    vars("INPUT_TO") = "a@b.com, c@d.com"
    match InputParser(vars)
    | let input: Input =>
      h.assert_eq[String](
        "[\"a@b.com\", \"c@d.com\"]", input.to)
    | let err: String =>
      h.fail("unexpected error: " + err)
    end
