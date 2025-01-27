const std = @import("std");
const net = std.net;
const log = @import("log.zig").log;

/// Respond to PING with PONG.
pub fn respondPong(conn: net.Server.Connection) void {
    conn.stream.writeAll("+PONG\r\n") catch return;
}

/// Respond with OK.
pub fn respondOk(conn: net.Server.Connection) void {
    conn.stream.writeAll("+OK\r\n") catch return;
}

/// Respond with a simple string (content).
pub fn respondSimpleString(conn: net.Server.Connection, content: []const u8) void {
    std.fmt.format(conn.stream.writer(), "${}\r\n{s}\r\n", .{ content.len, content }) catch respondError(conn);
}

/// Respond with error.
pub fn respondError(conn: net.Server.Connection) void {
    conn.stream.writeAll("Failed to process the request") catch return;
}

/// Respond with a command error.
pub fn respondCommandError(conn: net.Server.Connection, err: []const u8) void {
    std.fmt.format(conn.stream.writer(), "-ERR command error: '{s}'\r\n", .{err}) catch respondError(conn);
}

/// Respond with a "null bulk string" (`$-1\r\n`).
pub fn respondNullBulkString(conn: net.Server.Connection) void {
    conn.stream.writeAll("$-1\r\n") catch return;
}
