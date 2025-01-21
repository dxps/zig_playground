const std = @import("std");
const net = std.net;

pub fn respond_ok(conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n",
        .{},
    ) catch respond_internal_error(conn);
}

pub fn respond_ok_with_body(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{s}",
        .{ body.len, body },
    ) catch respond_internal_error(conn);
}

/// Respond with Internal Server Error.
pub fn respond_not_found(conn: net.Server.Connection) void {
    conn.stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n") catch return;
}

/// Respond with Internal Server Error.
pub fn respond_internal_error(conn: net.Server.Connection) void {
    conn.stream.writeAll("HTTP/1.1 500 Internal Server Error\r\n\r\n") catch return;
}
