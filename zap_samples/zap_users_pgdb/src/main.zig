const std = @import("std");
const builtin = @import("builtin");
const initLog = @import("log.zig").initLog;
const log = @import("log.zig").log;
const db = @import("db.zig");
const HttpServer = @import("http_srv.zig").HttpServer;

pub fn main() !void {

    // Logging init.
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    defer _ = gpa.detectLeaks();
    const a = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;

    try db.init(a);
    defer db.pool.deinit();

    const serverVersion = try db.getServerVersion();
    log("Connected to PosgreSQL version '{s}'.\n", .{serverVersion});

    var http_server = try HttpServer.init(a, .{
        .listener_port = 3003,
        .listener_log = true,
        .db_pool = db.pool,
    });
    defer _ = http_server.deinit();

    try http_server.start();
}
