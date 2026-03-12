use @exit[None](status: I32)
use @fprintf[I32](stream: Pointer[None] tag, fmt: Pointer[U8] tag, ...)
use @pony_os_stderr[Pointer[None]]()

primitive _Unreachable
  """
  Crash with a clear location when an unreachable code path is executed.
  """
  fun apply(loc: SourceLoc = __loc) =>
    @fprintf(
      @pony_os_stderr(),
      ("The unreachable was reached in %s at line %s\n" +
        "Please open an issue at " +
        "https://github.com/ponylang/zulip-action/issues")
        .cstring(),
      loc.file().cstring(),
      loc.line().string().cstring())
    @exit(1)
