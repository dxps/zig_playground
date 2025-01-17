const std = @import("std");
const zap = @import("zap");
const users = @import("users.zig");

pub const Routes = std.StringHashMap(zap.HttpRequestFn);

pub var routes: Routes = undefined;

pub fn init_routes(a: std.mem.Allocator) !Routes {
    routes = std.StringHashMap(zap.HttpRequestFn).init(a);
    try routes.put("/users/1", users.handleUsers);
    try routes.put("/users/2", users.handleUsers);
    return routes;
}
