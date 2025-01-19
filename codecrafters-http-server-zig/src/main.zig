const std = @import("std");
const net = std.net;
const printout = @import("printout.zig").printout;

pub fn main() !void {
    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    printout("Listening to 127.0.0.1:4221 ...\n", .{});

    var conn = try listener.accept();

    printout("Received connection from {}.\n", .{conn.address});

    // Explicitly handle the potential error.
    _ = conn.stream.write("HTTP/1.1 200 OK\r\n\r\n") catch |err| {
        std.log.err("Failed to write to connection: {}", .{err});
    };
    conn.stream.close();

    // This is the concise version (at least minimal enough for the current case).
    // try conn.stream.writeAll("HTTP/1.1 200 OK\r\n\r\n");
}
