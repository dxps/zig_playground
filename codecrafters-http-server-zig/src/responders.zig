const std = @import("std");
const net = std.net;

/// Respond with HTTP/1.1 200 OK.
pub fn respondOk(conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n",
        .{},
    ) catch respondInternalError(conn);
}

/// Respond with HTTP/1.1 201 Created.
pub fn respondCreated(conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 201 Created\r\n\r\n",
        .{},
    ) catch respondInternalError(conn);
}
/// Respond with "Content-Type: text/plain" (header) and provided body.
pub fn respondOkWithBody(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{s}",
        .{ body.len, body },
    ) catch respondInternalError(conn);
}

/// Respond with "Content-Type: application/octet-stream" (header) and provided body.
pub fn respondOkWithOctetAndBody(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: {}\r\n\r\n{s}",
        .{ body.len, body },
    ) catch respondInternalError(conn);
}

/// Respond with "Content-Encoding: gzip" and "Content-Type: text/plain" (headers) and provided body.
pub fn respondOkWithGzipAndBody(body: []const u8, conn: net.Server.Connection) void {
    std.fmt.format(
        conn.stream.writer(),
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: gzip\r\nContent-Length: {}\r\n\r\n{s}",
        .{ body.len, body },
    ) catch respondInternalError(conn);
}

/// Respond with Internal Server Error.
pub fn respondNotFound(conn: net.Server.Connection) void {
    conn.stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n") catch return;
}

/// Respond with Internal Server Error.
pub fn respondInternalError(conn: net.Server.Connection) void {
    conn.stream.writeAll("HTTP/1.1 500 Internal Server Error\r\n\r\n") catch return;
}
