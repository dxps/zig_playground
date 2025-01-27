const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const responders = @import("responders.zig");
const respondPong = responders.respondPong;
const respondError = responders.respondError;
const respondToEcho = responders.respondToEcho;
const Command = @import("command.zig").Command;
const CommandName = @import("command.zig").CommandName;

pub fn handleConnection(conn: net.Server.Connection, alloc: Allocator) void {
    defer conn.stream.close();

    const input = alloc.alloc(u8, 512) catch return respondError(conn);
    defer alloc.free(input);

    while (true) {
        const data_len = conn.stream.read(input) catch return respondError(conn);
        if (data_len == 0) {
            break;
        }
        log("Received input:'{s}'.\n", .{input[0..data_len]});

        // Parse the command.
        const cmd = Command.parse(input[0..data_len]) catch |err| {
            log("Command.parse failed with '{any}'.\n", .{err});
            return respondError(conn);
        };
        log("Parsed command name={s} lines={} payload={s}\n", .{ @tagName(cmd.name), cmd.payload_size, cmd.payload });

        //////////
        // PING //
        //////////
        if (cmd.name == CommandName.PING) {
            respondPong(conn);
        }

        //////////
        // ECHO //
        //////////
        else if (cmd.name == CommandName.ECHO) {
            return handleEcho(conn, cmd);
        }
    }
}

fn handleEcho(conn: net.Server.Connection, cmd: Command) void { //, alloc: Allocator) void {

    const data = cmd.payload[0];
    std.fmt.format(
        conn.stream.writer(),
        "${}\r\n{s}\r\n",
        .{ data.len, data },
    ) catch respondError(conn);
}
