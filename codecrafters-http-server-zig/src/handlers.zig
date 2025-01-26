const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;
const Request = @import("request.zig").Request;
const responders = @import("responders.zig");
const respondOk = responders.respondOk;
const respondCreated = responders.respondCreated;
const respondOkWithBody = responders.respondOkWithBody;
const respondOkWithOctetAndBody = responders.respondOkWithOctetAndBody;
const respondOkWithGzipAndBody = responders.respondOkWithGzipAndBody;
const respondOkWithGzipAndCompressedBody = responders.respondOkWithGzipAndCompressedBody;
const respondNotFound = responders.respondNotFound;
const respondInternalError = responders.respondInternalError;

pub fn handleConnection(conn: net.Server.Connection, files_directory: []const u8, a: Allocator) void {
    defer conn.stream.close();

    const buffer = a.alloc(u8, 512) catch return respondInternalError(conn);
    defer a.free(buffer);

    const data_len = conn.stream.read(buffer) catch return respondInternalError(conn);

    log("Received request: '{s}'.\n", .{buffer[0..data_len]});

    var req = Request.parse(buffer[0..data_len]);
    if (std.mem.eql(u8, req.getTarget().?, "/")) {
        respondOk(conn);
        return;
    }

    var route_iter = std.mem.splitSequence(u8, req.getTarget().?, "/");
    // skip the first '/'
    _ = route_iter.next();

    //////////////////
    // /echo/{word} //
    //////////////////
    if (std.mem.eql(u8, route_iter.peek().?, "echo")) {
        _ = route_iter.next(); // skip what we peeked
        if (route_iter.peek()) |word| {
            if (req.getHeader("Accept-Encoding")) |encoding| {
                var it = std.mem.splitAny(u8, encoding, ",");
                while (it.next()) |enc| {
                    const e = std.mem.trim(u8, enc, " ");
                    if (std.mem.eql(u8, e, "gzip")) {
                        log("Responding with gzip encoding for '{s}' word.\n", .{word});
                        return respondOkWithGzipAndCompressedBody(word, conn);
                    }
                }
            }
            respondOkWithBody(word, conn);
        } else {
            respondNotFound(conn);
        }
    }

    /////////////////
    // /user-agent //
    /////////////////
    else if (std.mem.eql(u8, route_iter.peek().?, "user-agent")) {
        _ = route_iter.next(); // skip what we peeked
        respondOkWithBody(req.getUserAgent().?, conn);
    }

    ////////////
    // /files //
    ////////////
    else if (std.mem.eql(u8, route_iter.peek().?, "files")) {
        log("Got {s} request to /files.\n", .{req.getMethod()});
        _ = route_iter.next(); // skip what we peeked, a: []const T, b: []const T))
        if (route_iter.peek()) |filename| {
            const filepath = std.fmt.allocPrint(a, "{s}/{s}", .{ files_directory, filename }) catch |err| {
                log("Error appending slices for filepath: {any}", .{err});
                respondInternalError(conn);
                return;
            };
            if (std.mem.eql(u8, req.getMethod(), "GET")) {
                log("Looking for '{s}' file to read from ...\n", .{filepath});
                const content = getFileContents(filepath, a) catch |err| {
                    log(">>> Err: {any}", .{err});
                    if (err == error.FileNotFound) {
                        return respondNotFound(conn);
                    }
                    return respondInternalError(conn);
                };
                respondOkWithOctetAndBody(content, conn);
            } else if (std.mem.eql(u8, req.getMethod(), "POST")) {
                log("Trying to write to '{s}' file ...\n", .{filepath});
                writeFile(filepath, req.body) catch return respondInternalError(conn);
                respondCreated(conn);
            }
        }
    } else {
        respondNotFound(conn);
    }

    log("HTTP response sent\n", .{});
}

fn getFileContents(filename: []u8, a: Allocator) ![]u8 {
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
