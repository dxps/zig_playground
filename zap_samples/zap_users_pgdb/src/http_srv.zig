const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const pg = @import("pg");
const zap = @import("zap");
const UserController = @import("http_users_api.zig").UserController;
const log = @import("log.zig").log;

pub const HttpServerConfig = struct {
    listener_port: u16,
    listener_log: bool,
    db_pool: *pg.Pool,
};

pub const HttpServer = struct {

    // The main router.
    router: zap.Router,

    // The listener.
    listener: zap.Endpoint.Listener,

    // The listening port.
    listener_port: u16,

    pub fn init(a: Allocator, cfg: HttpServerConfig) !HttpServer {
        var router = zap.Router.init(a, .{
            .not_found = notFound,
        });

        var listener = zap.Endpoint.Listener.init(a, .{
            .log = cfg.listener_log,
            .on_request = router.on_request_handler(),
            .port = cfg.listener_port,
        });

        var userCtrlr = UserController.init(a, cfg.db_pool);

        try listener.register(userCtrlr.endpoint());

        return HttpServer{
            .router = router,
            .listener = listener,
            .listener_port = cfg.listener_port,
        };
    }

    pub fn deinit(self: *HttpServer) void {
        self.listener.deinit();
        self.router.deinit();
    }

    pub fn start(self: *HttpServer) !void {
        try self.listener.listen();
        log("Listening on 0.0.0.0:{d} ...\n", .{self.listener_port});

        zap.start(.{
            .threads = 1,
            .workers = 1,
        });
    }
};

/// The global handler for the "Not found" case.
fn notFound(req: zap.Request) void {
    req.setStatus(.not_found);
    req.sendBody("Not found") catch return;
}
