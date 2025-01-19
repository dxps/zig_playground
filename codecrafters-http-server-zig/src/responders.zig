const std = @import("std");
const net = std.net;

pub fn respond_ok(body: []const u8, writer: net.Stream.Writer) !void {
    try std.fmt.format(writer, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{s}", .{ body.len, body });
}
