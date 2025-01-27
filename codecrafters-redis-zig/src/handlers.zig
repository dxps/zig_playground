const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const responders = @import("responders.zig");
const respondPong = responders.respondPong;
const respondError = responders.respondError;
const respondToEcho = responders.respondToEcho;
const respondNullBulkString = responders.respondNullBulkString;
const respondSimpleString = responders.respondSimpleString;
const respondOk = responders.respondOk;
const Command = @import("command.zig").Command;
const CommandName = @import("command.zig").CommandName;

var store: std.StringHashMap([]const u8) = undefined;

pub fn initStore() void {
    store = std.StringHashMap([]const u8).init(std.heap.page_allocator);
}

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
            return handleSet(conn, cmd);
        }

        /////////
        // GET //
        /////////
        else if (cmd.name == CommandName.GET) {
            return handleGet(conn, cmd);
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

fn handleSet(conn: net.Server.Connection, cmd: Command) void {
    const key = cmd.payload[0];
    const value = cmd.payload[1];

    store.put(key, value) catch |err| {
        log("Failed to set key='{s}' value='{s}': '{any}'.\n", .{ key, value, err });
        return respondError(conn);
    };
    log("Set key='{s}' value='{s}'.\n", .{ key, value });

    // Testing back (the result).
    if (store.get(key)) |val| {
        log("Testing back: got value='{s}' for key='{s}'.\n", .{ val, key });
    } else {
        log("Testing back: got nothing for key='{s}'.\n", .{key});
    }

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

test "string hashmap" {
    const expect = std.testing.expect;

    var map = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    defer map.deinit();

    try map.put("loris", "uncool");
    try map.put("me", "cool");

    try expect(std.mem.eql(u8, map.get("me").?, "cool"));
    try expect(std.mem.eql(u8, map.get("loris").?, "uncool"));
}
