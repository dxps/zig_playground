const std = @import("std");
const jetzig = @import("jetzig");

pub fn index(request: *jetzig.Request) !jetzig.View {
    const query = jetzig.database.Query(.Blog).select(.{ .id, .title });
    const blogs = try request.repo.all(query);

    var root = try request.data(.object);
    try root.put("blogs", blogs);

    return request.render(.ok);
}

pub fn get(id: []const u8, request: *jetzig.Request) !jetzig.View {
    const query = jetzig.database.Query(.Blog).find(id);
    if (try request.repo.execute(query)) |blog| {
        var root = try request.data(.object);
        try root.put("blog", blog);

        const rendered_markdown = jetzig.markdown.render(request.allocator, blog.content, .{});
        try root.put("markdown", rendered_markdown);

        return request.render(.ok);
    } else {
        return request.fail(.not_found);
    }
}

pub fn new(request: *jetzig.Request) !jetzig.View {
    return request.render(.ok);
}

pub fn post(request: *jetzig.Request) !jetzig.View {
    const Params = struct { title: []const u8, content: []const u8 };
    const params = try request.expectParams(Params) orelse {
        return request.fail(.unprocessable_entity);
    };

    const query = jetzig.database.Query(.Blog)
        .insert(.{ .content = params.content, .title = params.title });

    try request.repo.execute(query);

    return request.redirect("/blogs", .moved_permanently);
}

test "index" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/blogs", .{});
    try response.expectStatus(.ok);
}

test "get" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/blogs/example-id", .{});
    try response.expectStatus(.ok);
}

test "new" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/blogs/new", .{});
    try response.expectStatus(.ok);
}

test "post" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.POST, "/blogs", .{});
    try response.expectStatus(.created);
}
