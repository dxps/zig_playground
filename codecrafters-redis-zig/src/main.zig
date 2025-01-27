const std = @import("std");
const net = std.net;
const handleConnection = @import("handlers.zig").handleConnection;
const initLog = @import("log.zig").initLog;
const initStore = @import("handlers.zig").initStore;
const log = @import("log.zig").log;

pub fn main() !void {

    // Logging init.
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();

    // Store init.
    initStore(a);

    // Start the server.
    try runServer();
}

fn runServer() !void {
    var alloc: std.heap.ThreadSafeAllocator = .{
        .child_allocator = std.heap.page_allocator,
    };

    const address = try net.Address.resolveIp("127.0.0.1", 6379);
    var listener = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = alloc.child_allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    while (true) {
        const connection = try listener.accept();

        log("Accepted new connection from '{any}'.\n", .{connection.address});
        try pool.spawn(handleConnection, .{
            connection,
            alloc.allocator(),
        });
    }
}
