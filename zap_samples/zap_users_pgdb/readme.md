# A CRUD on `/users` sample w/ zap and pg

This is a CRUD example on `/users` API, implemented with:

-   [zap](https://github.com/zigzap/zap) - a Web framework
-   [pg.zig](https://github.com/karlseguin/pg.zig) - the native PostgreSQL driver to use it in the persistence layer.

<br/>

## Start

### Setup

1. Run `docker-compose up -d` to start the PostgreSQL server container in the background.
2. Use Zig version 0.14 (aka the master branch at the time of this writing).

Run `./run_dev.sh` to start the server in "development mode" (restart on code changes). Otherwise, the classic `zig build run` command is enough.

<br/>

## Usage

_to be cont'd_

<br/>

**Todos**

1. Currently, with existing Zig version `0.14.0-dev.3020`, the server crashes on any request, crash details below.

    1. Instead of trying with Zig version `0.13.0`, I'll wait a bit for the release of Zig 0.14.0, planned for this month, Feb '25.
    2. <details>
            <summary>Crash (panic) details</summary>
            <pre>
                thread 864049 panic: incorrect alignment
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:775:44: 0x11336b7 in header (zap_users_pgdb)
                            return @ptrCast(@as([*]Header, @ptrCast(@alignCast(self.metadata.?))) - 1);
                                                        ^
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:789:31: 0x1133614 in capacity (zap_users_pgdb)
                            return self.header().capacity;
                                            ^
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:968:39: 0x115271d in getIndex__anon_28726 (zap_users_pgdb)
                            const mask = self.capacity() - 1;
                                                    ^
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:1079:30: 0x112219c in getAdapted__anon_25525 (zap_users_pgdb)
                            if (self.getIndex(key, ctx)) |idx| {
                                            ^
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:1076:35: 0x10ff212 in getContext (zap_users_pgdb)
                            return self.getAdapted(key, ctx);
                                                ^
                /home/dxps/apps/zig/0.14.0-dev.3020+c104e8644/files/lib/std/hash_map.zig:367:45: 0x10e6e15 in get (zap_users_pgdb)
                            return self.unmanaged.getContext(key, self.ctx);
                                                            ^
                /home/dxps/.cache/zig/p/12200223d76ab6cd32f75bc2e31463b0b429bb5b2b6fa4ce8f68dea494ca1ec3398b/src/router.zig:104:24: 0x10c196e in serve (zap_users_pgdb)
                    if (self.routes.get(path)) |routeInfo| {
                                    ^
                /home/dxps/.cache/zig/p/12200223d76ab6cd32f75bc2e31463b0b429bb5b2b6fa4ce8f68dea494ca1ec3398b/src/router.zig:98:17: 0x109d432 in zap_on_request (zap_users_pgdb)
                    return serve(_instance, r);
            </pre>
       </details><br/>

2. Use multiple threads and workers in zap, and everything that must be done to support this.
