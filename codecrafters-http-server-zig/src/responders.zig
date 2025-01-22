const std = @import("std");
const net = std.net;

/// Respond with HTTP/1.1 200 OK.
pub fn respond_ok(conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n",
        .{},
    ) catch respond_internal_error(conn);
}

/// Respond with HTTP/1.1 201 Created.
pub fn respond_created(conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 201 Created\r\n\r\n",
        .{},
    ) catch respond_internal_error(conn);
}
/// Respond with "Content-Type: text/plain" (header) and provided body.
pub fn respond_ok_with_body(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{s}",
        .{ body.len, body },
    ) catch respond_internal_error(conn);
}

/// Respond with "Content-Type: application/octet-stream" (header) and provided body.
pub fn respond_ok_with_octet_and_body(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: {}\r\n\r\n{s}",
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
