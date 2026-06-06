const std = @import("std");
const spider = @import("spider");
const model = @import("model.zig");

pub const MoviesRow = struct {
    id: i64,
    name: []const u8,
};

pub const MoviesListContext = struct {
    movies: []MoviesRow,
    page_title: []const u8,
};

pub fn buildMoviesListContext(
    alloc: std.mem.Allocator,
    movies: []const model.Movies,
) !MoviesListContext {
    var rows = try std.ArrayListUnmanaged(MoviesRow).initCapacity(alloc, movies.len);
    for (movies) |item| {
        try rows.append(alloc, MoviesRow{ .id = item.id, .name = item.name });
    }
    return MoviesListContext{
        .movies = rows.items,
        .page_title = "movies",
    };
}
