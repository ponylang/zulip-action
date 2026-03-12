use zulip = "../zulip_action"
use courier = "courier"
use "collections"
use "files"
use lori = "lori"
use ssl = "ssl/net"

actor \nodoc\ Main
  new create(env: Env) =>
    let vars = _parse_env_vars(env.vars)
    match zulip.InputParser(vars)
    | let input: zulip.Input =>
      match courier.URL.parse(input.organization_url)
      | let url: courier.ParsedURL =>
        try
          let ssl_ctx =
            recover val
              ssl.SSLContext
                .> set_client_verify(true)
                .> set_authority(
                  FilePath(
                    FileAuth(env.root),
                    "/etc/ssl/certs/ca-certificates.crt"))?
            end
          let notify = _EnvNotify(env)
          let auth = lori.TCPConnectAuth(env.root)
          zulip.ZulipClient(
            auth, ssl_ctx, url.host, url.port, input, notify)
        else
          env.err.print(
            "::error::Failed to initialize SSL context")
          env.exitcode(1)
        end
      | let err: courier.URLParseError =>
        env.err.print("::error::Invalid organization URL")
        env.exitcode(1)
      end
    | let err: String =>
      env.err.print("::error::" + err)
      env.exitcode(1)
    end

  fun _parse_env_vars(vars: Array[String] val)
    : Map[String, String] val
  =>
    """
    Convert the process environment array (`KEY=VALUE` strings) into
    a map.
    """
    recover val
      let m = Map[String, String]
      for v in vars.values() do
        try
          let eq = v.find("=")?
          m(v.substring(0, eq)) = v.substring(eq + 1)
        end
      end
      m
    end

actor \nodoc\ _EnvNotify is zulip.ResultNotify
  """
  Production result handler that writes GitHub Actions workflow
  commands to stdout/stderr.
  """
  let _env: Env

  new create(env: Env) =>
    _env = env

  be success(id: String) =>
    _env.out.print(
      "::notice::Message successfully sent with id: " + id)

  be failure(msg: String) =>
    _env.err.print("::error::" + msg)
    _env.exitcode(1)
