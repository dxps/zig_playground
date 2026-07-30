///!
///! The examples below are mainly taken from https://ziglang.org/documentation/0.16.0/?#Slices
///!
const expectEqual = @import("std").testing.expectEqual;
const std = @import("std");

pub fn main(_: std.process.Init) !void {
    var array = [_]i32{ 1, 2, 3, 4, 5 };
    std.debug.print(
        "array has the type {} and it contains {any} items: {any}\n",
        .{ @TypeOf(array), array.len, array },
    );

    // If you slice with comptime-known start and end positions, the result is
    // a pointer to an array, rather than a slice.
    const array_ptr = array[0..array.len];
    try expectEqual(*[array.len]i32, @TypeOf(array_ptr));
    std.debug.print(
        "array_ptr has the type {} and it points to the previous array (of {any} items): {any}\n",
        .{ @TypeOf(array_ptr), array_ptr.len, array_ptr },
    );

    // You can perform a slice-by-length by slicing twice. This allows the compiler
    // to perform some optimisations like recognising a comptime-known length when
    // the start position is only known at runtime.
    var runtime_start: usize = 1;
    _ = &runtime_start;
    const length = 2;
    const array_ptr_len = array[runtime_start..][0..length];
    try expectEqual(*[length]i32, @TypeOf(array_ptr_len));
    std.debug.print(
        "array_ptr_len has the type {} and it points to a slice of {any} items: {any}\n",
        .{ @TypeOf(array_ptr_len), array_ptr_len.len, array_ptr_len },
    );
}
