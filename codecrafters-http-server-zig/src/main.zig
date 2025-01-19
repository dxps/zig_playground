const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const handleConnection = @import("handlers.zig").handleConnection;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const page_alloc = std.heap.page_allocator;
    var alloc: std.heap.ThreadSafeAllocator = .{ .child_allocator = page_alloc };

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
        try pool.spawn(handleConnection, .{ connection, stdout, alloc.allocator() });
    }
}
