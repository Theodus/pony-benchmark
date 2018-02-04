use "../.."
use "net"

actor Main is BenchmarkList
  let _env: Env
  let _auth: (NetAuth | None)

  new create(env: Env) =>
    _env = env
    let auth =
      match env.root
      | let a: AmbientAuth => NetAuth(a)
      else env.err.print("unable to get network auth")
      end
    _auth = auth

    PonyBench(env, this)

  be benchmarks(bench: PonyBench) =>
    try bench(_BenchTCPConnect(_auth as NetAuth, _env.out)) end

class iso _BenchTCPConnect is AsyncMicroBenchmark
  var _p: USize = 8080
  var _server: (TCPListener | None) = None
  let _auth: NetAuth
  let _out: OutStream

  new iso create(auth: NetAuth, out: OutStream) =>
    _auth = auth
    _out = out

  fun name(): String =>
    "TCPConnect"

  fun ref before(c: AsyncBenchContinue) =>
    _p = _p + 1
    _server = TCPListener(_auth, TCPServer(_out, c), "127.0.0.1", _p.string())

  fun ref apply(c: AsyncBenchContinue) =>
    TCPConnection(_auth,
      object iso is TCPConnectionNotify
        fun ref connect_failed(conn: TCPConnection ref) =>
          conn.close()
          c.fail()

        fun ref connected(conn: TCPConnection ref) =>
          conn.close()
          c.complete()
      end,
      "127.0.0.1", _p.string())

  fun ref after(c: AsyncBenchContinue) =>
    match _server
    | let s: TCPListener => s.dispose()
    end
    c.complete()

class iso TCPServer is TCPListenNotify
  let _out: OutStream
  let _c: AsyncBenchContinue

  new iso create(out: OutStream, c: AsyncBenchContinue) =>
    _out = out
    _c = c

  fun ref listening(listener: TCPListener ref) =>
    // (let host, let service) =
    //   try listener.local_address().name()? else ("?", "?") end
    // _out.print(host + ":" + service)
    _c.complete()

  fun ref not_listening(listener: TCPListener ref) =>
    _out.print("Error: not listening")
    listener.close()
    _c.fail()

  // fun ref closed(listen: TCPListener ref) =>
  //   _out.print("closed")

  fun ref connected(listener: TCPListener ref): TCPConnectionNotify iso^ =>
    object iso is TCPConnectionNotify
      fun ref connect_failed(conn: TCPConnection ref) =>
        _out.print("connect fail")
    end
