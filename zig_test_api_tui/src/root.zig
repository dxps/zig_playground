const std = @import("std");

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Operation = struct {
    name: []const u8,
    url: []const u8,
    method: []const u8,
    headers: []const Header = &.{},
    body: ?std.json.Value = null,
    expected_status: u16,
};

pub const Config = struct {
    min_interval_ms: u64 = 500,
    max_interval_ms: u64 = 2_000,
    max_wait_ms: u64 = 5_000,
    run_count: u64 = 20,
    output_file: []const u8 = "test_result.json",
    operations: []const Operation,
};

pub fn validate(config: Config) !void {
    if (config.operations.len == 0) return error.NoOperations;
    if (config.min_interval_ms > config.max_interval_ms) return error.InvalidInterval;
    if (config.max_wait_ms == 0) return error.InvalidMaxWait;
    if (config.run_count == 0) return error.InvalidRunCount;
    for (config.operations) |operation| {
        if (operation.name.len == 0) return error.EmptyOperationName;
        if (operation.url.len == 0) return error.EmptyUrl;
        if (std.meta.stringToEnum(std.http.Method, operation.method) == null)
            return error.InvalidHttpMethod;
        if (operation.expected_status < 100 or operation.expected_status > 599)
            return error.InvalidExpectedStatus;
    }
}

pub fn intervalMs(random: std.Random, min: u64, max: u64) u64 {
    if (min == max) return min;
    return random.intRangeAtMost(u64, min, max);
}

test "configuration validation" {
    const valid = Config{ .operations = &.{.{
        .name = "health",
        .url = "http://localhost/health",
        .method = "GET",
        .expected_status = 200,
    }} };
    try validate(valid);

    var invalid = valid;
    invalid.min_interval_ms = 10;
    invalid.max_interval_ms = 5;
    try std.testing.expectError(error.InvalidInterval, validate(invalid));

    invalid = valid;
    invalid.max_wait_ms = 0;
    try std.testing.expectError(error.InvalidMaxWait, validate(invalid));
}

test "fixed interval" {
    var prng = std.Random.DefaultPrng.init(123);
    try std.testing.expectEqual(@as(u64, 42), intervalMs(prng.random(), 42, 42));
}

test "structured JSON request body" {
    const source =
        \\{"operations":[{"name":"login","url":"https://example.com/login","method":"POST","body":[{"username":"user"}],"expected_status":200}]}
    ;
    const parsed = try std.json.parseFromSlice(Config, std.testing.allocator, source, .{});
    defer parsed.deinit();

    const body = parsed.value.operations[0].body.?;
    try std.testing.expectEqual(@as(usize, 1), body.array.items.len);
    try std.testing.expectEqualStrings("user", body.array.items[0].object.get("username").?.string);
}
