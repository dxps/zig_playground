const std = @import("std");
const net = std.net;
const log = @import("log.zig").log;

/// Respond to PING with PONG.
pub fn respondPong(conn: net.Server.Connection) void {
    conn.stream.writeAll("+PONG\r\n") catch return;
}

/// Respond with error.
pub fn respondError(conn: net.Server.Connection) void {
    conn.stream.writeAll("Failed to process the request") catch return;
}

/// Respond with a command error.
pub fn respondCommandError(conn: net.Server.Connection, err: []const u8) void {
    std.fmt.format(conn.stream.writer(), "-ERR command error: '{s}'\r\n", .{err}) catch respondError(conn);
}
