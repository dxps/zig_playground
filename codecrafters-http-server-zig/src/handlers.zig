const std = @import("std");
const net = std.net;
const log = @import("log.zig").log;
const Request = @import("request.zig").Request;
const responders = @import("responders.zig");
const respond_ok = responders.respond_ok;
const respond_ok_with_body = responders.respond_ok_with_body;
const respond_not_found = responders.respond_not_found;
const respond_internal_error = responders.respond_internal_error;

pub fn handle_connection(conn: net.Server.Connection, alloc: std.mem.Allocator) void {
    defer conn.stream.close();

    const buffer = alloc.alloc(u8, 512) catch return respond_internal_error(conn);
    defer alloc.free(buffer);

    const data_len = conn.stream.read(buffer) catch return respond_internal_error(conn);

    log("Received request: '{s}'.\n", .{buffer[0..data_len]});

    var req = Request.parse(buffer[0..data_len]);
    if (std.mem.eql(u8, req.get_target().?, "/")) {
        respond_ok(conn);
        return;
    }

    var route_iter = std.mem.splitSequence(u8, req.get_target().?, "/");
    // skip the first '/' as there is nothing in front of it
    _ = route_iter.next();

    if (std.mem.eql(u8, route_iter.peek().?, "echo")) {
        _ = route_iter.next(); // skip what we peeked
        if (route_iter.peek()) |part| {
            respond_ok_with_body(part, conn);
        } else {
            respond_not_found(conn);
        }
    } else if (std.mem.eql(u8, route_iter.peek().?, "user-agent")) {
        _ = route_iter.next(); // skip what we peeked
        respond_ok_with_body(req.get_user_agent().?, conn);
    } else if (std.mem.eql(u8, route_iter.peek().?, "files")) {
        _ = route_iter.next(); // skip what we peeked, a: []const T, b: []const T))
        if (route_iter.peek()) |_| {
            // const filepath = try std.fmt.allocPrint(alloc, "/tmp/{s}", .{part}) catch return respond_internal_error(conn);
            const filepath = "/tmp/foo";
            log("Looking for '{s}' file ...\n", .{filepath});

            if (get_file_contents_size(filepath)) |content| {
                respond_ok_with_body(content, conn);
            } else {
                respond_not_found(conn);
            }
        }
    } else {
        respond_not_found(conn);
    }

    log("HTTP response sent\n", .{});
}

fn get_file_contents_size(filename: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();
    const stat = try file.stat();
    const size = stat.size;
    var content = std.mem.zeroInit([size]u8, undefined);
    try file.readAll(&content);
    return content;
}
