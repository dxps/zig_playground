const std = @import("std");
const net = std.net;
const Request = @import("request.zig").Request;
const respond_ok = @import("responders.zig").respond_ok;

pub fn handleConnection(conn: net.Server.Connection, log: ?std.fs.File.Writer, alloc: std.mem.Allocator) void {
    defer conn.stream.close();

    const buffer = alloc.alloc(u8, 512) catch return handleError(conn);
    defer alloc.free(buffer);

    const data_len = conn.stream.read(buffer) catch return handleError(conn);

    if (log) |logger| {
        logger.print("Received request: '{s}'.\n", .{buffer[0..data_len]}) catch return handleError(conn);
    }

    var req = Request.parse(buffer[0..data_len]);
    if (std.mem.eql(u8, req.get_target().?, "/")) {
        conn.stream.writeAll("HTTP/1.1 200 OK\r\n\r\n") catch return handleError(conn);
    } else {
        var route_iter = std.mem.splitSequence(u8, req.get_target().?, "/");
        // skip the first '/' as there is nothing in front of it
        _ = route_iter.next();

        if (std.mem.eql(u8, route_iter.peek().?, "echo")) {
            _ = route_iter.next(); // skip what we peeked
            respond_ok(route_iter.next().?, conn.stream.writer()) catch return handleError(conn);
        } else if (std.mem.eql(u8, route_iter.peek().?, "user-agent")) {
            _ = route_iter.next(); // skip what we peeked
            respond_ok(req.get_user_agent().?, conn.stream.writer()) catch return handleError(conn);
        } else {
            conn.stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n") catch return handleError(conn);
        }
    }
    if (log) |logger| {
        logger.print("HTTP response sent\n", .{}) catch return;
    }
}

fn handleError(connection: net.Server.Connection) void {
    connection.stream.writeAll("HTTP/1.1 500 Internal Server Error\r\n\r\n") catch return;
}
