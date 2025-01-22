const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const Request = @import("request.zig").Request;
const responders = @import("responders.zig");
const respond_ok = responders.respond_ok;
const respond_created = responders.respond_created;
const respond_ok_with_body = responders.respond_ok_with_body;
const respond_ok_with_octet_and_body = responders.respond_ok_with_octet_and_body;
const respond_not_found = responders.respond_not_found;
const respond_internal_error = responders.respond_internal_error;

pub fn handleConnection(conn: net.Server.Connection, files_directory: []const u8, a: Allocator) void {
    defer conn.stream.close();

    const buffer = a.alloc(u8, 512) catch return respond_internal_error(conn);
    defer a.free(buffer);

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
        log("Got {s} request to /files.\n", .{req.get_method()});
        _ = route_iter.next(); // skip what we peeked, a: []const T, b: []const T))
        if (route_iter.peek()) |part| {
            const filepath = std.fmt.allocPrint(a, "{s}/{s}", .{ files_directory, part }) catch |err| {
                log("Error appending slices for filepath: {any}", .{err});
                respond_internal_error(conn);
                return;
            };
            if (std.mem.eql(u8, req.get_method(), "GET")) {
                log("Looking for '{s}' file to read from ...\n", .{filepath});
                const content = getFileContent(filepath, a) catch |err| {
                    log(">>> Err: {any}", .{err});
                    if (err == error.FileNotFound) {
                        return respond_not_found(conn);
                    }
                    return respond_internal_error(conn);
                };
                respond_ok_with_octet_and_body(content, conn);
            } else if (std.mem.eql(u8, req.get_method(), "POST")) {
                log("Trying to write to '{s}' file ...\n", .{filepath});
                writeFile(filepath, req.body) catch return respond_internal_error(conn);
                respond_created(conn);
            }
        }
    } else {
        respond_not_found(conn);
    }

    log("HTTP response sent\n", .{});
}

fn getFileContent(filename: []u8, a: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();
    const file_size = (try file.stat()).size;
    const content = try a.alloc(u8, file_size);
    _ = try file.readAll(content);
    return content;
}

fn writeFile(filepath: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(filepath, .{});
    defer file.close();
    try file.writeAll(content);
}
