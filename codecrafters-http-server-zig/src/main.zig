const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const handle_connection = @import("handlers.zig").handle_connection;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var alloc: std.heap.ThreadSafeAllocator = .{
        .child_allocator = std.heap.page_allocator,
    };

    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    var pool: std.Thread.Pool = undefined;

    try pool.init(std.Thread.Pool.Options{
        .allocator = alloc.child_allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    while (true) {
        const connection = try listener.accept();
        try pool.spawn(handle_connection, .{
            connection,
            stdout,
            alloc.allocator(),
        });
    }
}
