const std = @import("std");

const core = @import("core");
const migrations = core.db.migrations;
const features = @import("features");
const home = features.home;
const movies = features.movies;
const spider = @import("spider");
const Response = spider.Response;
const db = spider.pg;

pub const spider_templates = @import("embedded_templates.zig").EmbeddedTemplates;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    try db.init(allocator, io, .{});
    defer db.deinit();

    var server = spider.app(.{});
    defer server.deinit();

    try migrations.migrate(allocator);

    server
        .get("/", home.index)
        .onError(errorHandler)
        .get("/movies", movies.controller.index)
        .get("/movies/new", movies.controller.newForm)
        .get("/movies/:id/edit", movies.controller.edit)
        .post("/movies/create", movies.controller.create)
        .post("/movies/:id/update", movies.controller.update)
        .post("/movies/:id/delete", movies.controller.delete)
        .listen(.{ .port = 3000, .host = "0.0.0.0" }) catch |err| return err;
}

fn errorHandler(c: *spider.Ctx, err: anyerror) !Response {
    return switch (err) {
        error.TemplateNotFound => c.text("Template not found", .{ .status = .not_found }),
        else => c.text(@errorName(err), .{ .status = .internal_server_error }),
    };
}
