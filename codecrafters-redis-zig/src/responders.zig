const net = @import("std").net;

/// Respond with PONG.
pub fn respondPong(conn: net.Server.Connection) void {
    conn.stream.writeAll("+PONG\r\n") catch return;
}

/// Respond with error.
pub fn respondError(conn: net.Server.Connection) void {
    conn.stream.writeAll("Failed to process the request") catch return;
}
