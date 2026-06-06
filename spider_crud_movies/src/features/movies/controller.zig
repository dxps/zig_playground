const std = @import("std");
const spider = @import("spider");
const model = @import("model.zig");
const repository = @import("repository.zig");
const presenter = @import("presenter.zig");
const Response = spider.Response;

pub fn index(c: *spider.Ctx) !Response {
    const items = try repository.findAll(c.arena);
    const context = try presenter.buildMoviesListContext(c.arena, items);
    if (c.isHtmx()) return c.view("movies/index", context, .{});
    return c.view("movies/page", context, .{});
}

pub fn newForm(c: *spider.Ctx) !Response {
    if (c.isHtmx()) return c.view("MoviesForm", .{}, .{});
    return c.redirect("/movies");
}

pub fn edit(c: *spider.Ctx) !Response {
    const id_str = c.params.get("id") orelse return error.MissingParam;
    const id = try std.fmt.parseInt(i64, id_str, 10);
    const item = try repository.findById(c.arena, id);
    const name = if (item) |i| i.name else "";
    return c.view("MoviesEditForm", .{ .id = id, .name = name }, .{});
}

pub fn create(c: *spider.Ctx) !Response {
    const input = try c.parseForm(model.CreateInput);
    const created = try repository.create(c.arena, input);
    if (c.isHtmx()) {
        const item = created orelse return c.redirect("/movies");
        const headers = try c.arena.alloc([2][]const u8, 1);
        headers[0] = .{ "HX-Trigger", "item-saved" };
        return c.view("MoviesCard", .{ .id = item.id, .name = item.name }, .{ .headers = headers });
    }
    return c.redirect("/movies");
}

pub fn update(c: *spider.Ctx) !Response {
    const id_str = c.params.get("id") orelse return error.MissingParam;
    const id = try std.fmt.parseInt(i64, id_str, 10);
    const input = try c.parseForm(model.UpdateInput);
    const updated = try repository.update(c.arena, id, input);
    const name = if (updated) |u| u.name else input.name orelse "";
    if (c.isHtmx()) {
        const headers = try c.arena.alloc([2][]const u8, 1);
        headers[0] = .{ "HX-Trigger", "item-saved" };
        return c.view("MoviesCard", .{ .id = id, .name = name }, .{ .headers = headers });
    }
    return c.redirect("/movies");
}

pub fn delete(c: *spider.Ctx) !Response {
    const id_str = c.params.get("id") orelse return error.MissingParam;
    const id = try std.fmt.parseInt(i64, id_str, 10);
    try repository.delete(c.arena, id);
    if (c.isHtmx()) {
        const headers = try c.arena.alloc([2][]const u8, 1);
        headers[0] = .{ "HX-Trigger", "item-deleted" };
        return c.html("", .{ .headers = headers });
    }
    return c.redirect("/movies");
}
