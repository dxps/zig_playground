//! Anonymous structs can be created without specifying field names.
//! These are referred as "tuples".
//! The fields are named using numbers starting from 0, and referred using `@"0"` syntax.
//! These names inside `@""` are always recognized as identifiers.

const expect = @import("std").testing.expect;

test "tuple" {

    const values = .{
        @as(u32, 123),
        @as(f64, 12.3),
        true,
        "hi",
    } ++ .{ false} ** 2;

    try expect(values[0] == 123);
    try expect(values[1] == 12.3);
    inline for (values) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
    try expect(values.@"4" == false);
}