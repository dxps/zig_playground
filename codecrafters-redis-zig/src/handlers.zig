const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const Store = @import("datastore.zig").Store;
const responders = @import("responders.zig");
const respondPong = responders.respondPong;
const respondError = responders.respondError;
const respondToEcho = responders.respondToEcho;
const respondNullBulkString = responders.respondNullBulkString;
const respondSimpleString = responders.respondSimpleString;
const respondCommandError = responders.respondCommandError;
const respondOk = responders.respondOk;
const Command = @import("command.zig").Command;
const CommandName = @import("command.zig").CommandName;

// var store: std.StringHashMap([]const u8) = undefined;
// var store_mutex: std.Thread.Mutex = undefined;

var store: Store = undefined;

pub fn initStore(a: Allocator) void {
    store = Store.init(a);
}

pub fn handleConnection(conn: net.Server.Connection, a: Allocator) void {
    defer conn.stream.close();

    const input = a.alloc(u8, 512) catch return respondError(conn);
    defer a.free(input);

    while (true) {
        const data_len = conn.stream.read(input) catch return respondError(conn);
        if (data_len == 0) {
            break;
        }
        log("Received input:'{s}'.\n", .{input[0..data_len]});

        // Parse the command.
        const cmd = Command.parse(input[0..data_len]) catch |err| {
            log("Failed to parse command: '{any}'.\n", .{err});
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

        /////////
        // SET //
        /////////
        else if (cmd.name == CommandName.SET) {
            handleSet(a, conn, cmd) catch |err| {
                const err_msg = std.fmt.allocPrint(a, "{any}", .{err}) catch unreachable;
                respondCommandError(conn, err_msg);
                // respondCommandError(conn, try std.fmt.allocPrint(a, "{any}", .{err}));
            };
        }

        /////////
        // GET //
        /////////
        else if (cmd.name == CommandName.GET) {
            handleGet(conn, cmd);
        }
    }
}

fn handleEcho(conn: net.Server.Connection, cmd: Command) void {
    const data = cmd.payload[0];
    std.fmt.format(
        conn.stream.writer(),
        "${}\r\n{s}\r\n",
        .{ data.len, data },
    ) catch respondError(conn);
}

fn handleSet(a: Allocator, conn: net.Server.Connection, cmd: Command) !void {
    const key = cmd.payload[0];
    const value = cmd.payload[1];

    const key_copy = std.mem.Allocator.dupe(a, u8, cmd.payload[0]) catch |err| {
        log("Failed to duplicate key='{s}': '{any}'.\n", .{ key, err });
        return respondError(conn);
    };
    const value_copy = std.mem.Allocator.dupe(a, u8, cmd.payload[1]) catch |err| {
        log("Failed to duplicate value='{s}': '{any}'.\n", .{ value, err });
        return respondError(conn);
    };

    // const expires = if (cmd.payload_size == 4 and std.mem.eql(u8, cmd.payload[2], "px")) {
    var expires: i64 = 0;
    if (cmd.payload_size == 4 and std.mem.eql(u8, cmd.payload[2], "px")) {
        expires = try std.fmt.parseUnsigned(i64, cmd.payload[3], 10);
    }

    store.put(key_copy, value_copy, expires) catch |err| {
        log("Failed to set key='{s}' value='{s}': '{any}'.\n", .{ key_copy, value_copy, err });
        return respondError(conn);
    };

    log("Set key='{s}' value='{s}'.\n", .{ key_copy, value_copy });

    respondOk(conn);
}

fn handleGet(conn: net.Server.Connection, cmd: Command) void {
    const key = cmd.payload[0];
    log("Looking for key='{s}' ...\n", .{key});

    if (store.get(key)) |value| {
        log("Got value='{s}' for key='{s}'.\n", .{ value, key });
        respondSimpleString(conn, value);
    } else {
        respondNullBulkString(conn);
    }
}
