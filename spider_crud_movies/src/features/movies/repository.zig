const std = @import("std");
const spider = @import("spider");
const db = spider.pg;
const model = @import("model.zig");

pub fn findAll(alloc: std.mem.Allocator) ![]model.Movies {
    const sql = "SELECT id, name FROM movies ORDER BY id DESC";
    return try db.query(model.Movies, alloc, sql, .{});
}
pub fn findById(alloc: std.mem.Allocator, id: i64) !?model.Movies {
    const sql = "SELECT id, name FROM movies WHERE id = $1";
    return try db.queryOne(model.Movies, alloc, sql, .{id});
}
pub fn create(alloc: std.mem.Allocator, input: model.CreateInput) !?model.Movies {
    const sql = "INSERT INTO movies (name) VALUES ($1) RETURNING id, name";
    return try db.queryOne(model.Movies, alloc, sql, .{input.name});
}
pub fn update(alloc: std.mem.Allocator, id: i64, updates: model.UpdateInput) !?model.Movies {
    const current = try findById(alloc, id) orelse return null;
    const new_name = updates.name orelse current.name;
    const sql = "UPDATE movies SET name = $1 WHERE id = $2 RETURNING id, name";
    return try db.queryOne(model.Movies, alloc, sql, .{ new_name, id });
}
pub fn delete(alloc: std.mem.Allocator, id: i64) !void {
    const sql = "DELETE FROM movies WHERE id = $1";
    _ = try db.query(void, alloc, sql, .{id});
}
