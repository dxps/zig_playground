//! The struct type can be inferred.

const print = @import("std").debug.print;
const expect = @import("std").testing.expect;

const Point = struct { x: i32, y: i32 };

test "anonymous struct literal, provided for instantiation" {
    var pt: Point = .{
        .x = 11,
        .y = 22,
    };
    try expect(pt.x == 11);
    try expect(pt.y == 22);
}

test "fully anonymous struct literal" {
    
    try dump(.{
        .myInt = @as(u32, 123),
        .myFloat = @as(f64, 12.3),
        .myBool = true,
        .myStr = "hi",
    });
}

fn dump(args: anytype) !void {
    // The struct type is being inferred here.
    try expect(args.myInt == 123);
    try expect(args.myFloat == 12.3);
    try expect(args.myBool);
    try expect(args.myStr[0] == 'h');
    try expect(args.myStr[1] == 'i');
}
