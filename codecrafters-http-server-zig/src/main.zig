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

    const conn = try listener.accept();
    printout("Received connection from {}.\n", .{conn.address});
    const stream = conn.stream;

    // Allocate a buffer to read into.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const buff = try a.alloc(u8, 512);
    defer a.free(buff);

    _ = stream.read(buff) catch |err| {
        printout("Failed to read from client stream: {}\n", .{err});
    };

    var iter = std.mem.splitAny(u8, buff, " ");
    _ = iter.next(); // skip the HTTP method (first word in the first line)
    const url_path = iter.next();

    if (std.mem.eql(u8, url_path.?, "/")) {
        try respond_ok(stream);
        return;
    }

    if (url_path.?.len < 6) {
        try respond_not_found(stream);
        return;
    }

    const path = url_path.?[6..]; // the text in "/echo/{path}"
    if (std.mem.eql(u8, url_path.?[0..6], "/echo/")) {
        const res = try std.fmt.allocPrint(a, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {d}\r\n\r\n{s}", .{ path.len, path });
        try stream.writeAll(res);
    } else {
        try respond_not_found(stream);
    }
}

fn respond_ok(stream: anytype) !void {
    try stream.writeAll("HTTP/1.1 200 OK\r\n\r\n");
}

fn respond_not_found(stream: anytype) !void {
    try stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n");
}
