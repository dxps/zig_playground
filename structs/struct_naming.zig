//! Structs are anonymous, by default.
//! Their names get inferred based on the declaration.

const print = @import("std").debug.print;

pub fn main() void {
    const Some = struct {};
    print("  variable: {s}\n", .{@typeName(Some)});
    print(" anonymous: {s}\n", .{@typeName(struct {})});
    print("  function: {s}\n", .{@typeName(List(i32))});
}

/// `List` returns an anonymous struct
/// (that gets named based on this function name and its param)
/// with an `x` field as the provided type.
fn List(comptime T: type) type {
    return struct {
        x: T,
    };
}
