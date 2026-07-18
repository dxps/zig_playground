const std = @import("std");

pub fn main() void {
    var arr = [_]i8{ 1, 2, 3 };
    std.debug.print("     arr: {any}\n", .{arr});

    const slice_ro: []const i8 = &arr;
    std.debug.print("slice_ro: {any} length={} pointer={x}\n", .{
        slice_ro, slice_ro.len, @intFromPtr(slice_ro.ptr),
    });

    // This would fail (at compile time) with "error: cannot assign to constant".
    // slice_ro[2] += 1;

    const slice_rw = &arr;
    slice_rw[2] += 1;

    std.debug.print("     arr: {any}\n", .{arr});
    std.debug.print("slice_rw: {any} length={} pointer={x}\n", .{
        slice_rw, slice_rw.len, @intFromPtr(slice_rw.ptr),
    });
}
