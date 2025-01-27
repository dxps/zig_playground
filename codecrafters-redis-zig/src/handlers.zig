const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const responders = @import("responders.zig");
const respondPong = responders.respondPong;
const respondError = responders.respondError;

pub fn handleConnection(conn: net.Server.Connection, alloc: Allocator) void {
    defer conn.stream.close();

    const buffer = alloc.alloc(u8, 512) catch return respondError(conn);
    defer alloc.free(buffer);

    while (true) {
        const data_len = conn.stream.read(buffer) catch return respondError(conn);
        if (data_len == 0) {
            break;
        }
        log("Received command: '{s}'.\n", .{buffer[0..data_len]});

        //////////
        // PING //
        //////////
        if (std.mem.eql(u8, buffer[0..data_len], "*1\r\n$4\r\nPING\r\n")) {
            respondPong(conn);
        }
    }
}
