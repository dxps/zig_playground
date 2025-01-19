const std = @import("std");

pub const Request = struct {
    request_line: []const u8,
    headers: []const u8,
    body: []const u8,

    const Self = @This();

    pub fn parse(input: []const u8) Request {
        var iter = std.mem.splitSequence(u8, input, "\r\n\r\n");
        const request_line_and_headers = iter.next().?;
        const body = iter.rest();
        var headers_iter = std.mem.splitSequence(u8, request_line_and_headers, "\r\n");
        return Request{
            .request_line = headers_iter.first(),
            .headers = headers_iter.rest(),
            .body = body,
        };
    }

    // Get request's HTTP method.
    fn get_method(self: *Self) []const u8 {
        var request_line_iter = std.mem.splitSequence(u8, self.request_line, " ");
        return request_line_iter.first();
    }

    // Get request's URL.
    pub fn get_target(self: *Self) ?[]const u8 {
        var request_line_iter = std.mem.splitSequence(u8, self.request_line, " ");
        _ = request_line_iter.first();
        return request_line_iter.next();
    }

    //this function might be unnecessary
    fn is_echo(self: *Self) ?bool {
        if (self.get_target()) |target| {
            return std.mem.startsWith(u8, target, "/echo");
        }
        return null;
    }

    // Get request's header.
    fn get_header(self: *Self, header_name: []const u8) ?[]const u8 {
        var header_iter = std.mem.splitSequence(u8, self.headers, "\r\n");
        while (header_iter.next()) |header| {
            var header_split = std.mem.splitSequence(u8, header, ": ");
            if (std.mem.eql(u8, header_split.next().?, header_name)) {
                return header_split.next();
            }
        }
        return null;
    }

    // Get request's "User-Agent" header.
    pub fn get_user_agent(self: *Self) ?[]const u8 {
        return self.get_header("User-Agent");
    }
};
