const std = @import("std");
const zap = @import("zap");
const users = @import("users.zig");
const api = @import("api.zig");

var routes: api.Routes = undefined;

fn on_request(r: zap.Request) void {
    if (r.path) |the_path| {

        // If the path matches a route, call the handler.
        if (routes.get(the_path)) |handler| {
            handler(r);
            return;
        }

        std.debug.print(" Route not found: {s}\n", .{the_path});

        // Otherwise, 404.
        r.setStatus(.not_found);
        r.sendFile("public/404.html") catch |err| {
            std.log.err("Failed to send 404 page: {}", .{err});
            r.sendBody("404 - Not Found") catch return;
        };
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const a = gpa.allocator();

    try users.initStore(a);

    routes = try api.init_routes(a);

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .public_folder = "public",
        .log = false,
    });
    try listener.listen();

    std.debug.print(
        \\ Listening on 0.0.0.0:3000
        \\ 
        \\ Check out:
        \\ http://localhost:3000/users/1   # -- First user.
        \\ http://localhost:3000/users/2   # -- Second user.
        \\ http://localhost:3000/users/3   # -- Non-existing user.
        \\
    , .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1, // users map cannot be shared among multiple worker processes
    });
}
