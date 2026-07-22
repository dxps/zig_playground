const std = @import("std");

const app = @import("api_test_tui");

const Result = struct {
    uid: []const u8,
    start_time: [23]u8,
    operation: []const u8,
    method: []const u8,
    url: []const u8,
    expected_status: u16,
    actual_status: ?u16,
    duration_ms: u64,
    passed: bool,
    error_name: ?[]const u8,
    response_body: ?[]u8,

    pub fn jsonStringify(result: @This(), json: anytype) !void {
        try json.beginObject();
        try json.objectField("uid");
        try json.write(result.uid);
        try json.objectField("start_time");
        try json.write(result.start_time[0..]);
        try json.objectField("operation");
        try json.write(result.operation);
        try json.objectField("method");
        try json.write(result.method);
        try json.objectField("url");
        try json.write(result.url);
        try json.objectField("expected_status");
        try json.write(result.expected_status);
        try json.objectField("actual_status");
        try json.write(result.actual_status);
        try json.objectField("duration_ms");
        try json.write(result.duration_ms);
        try json.objectField("passed");
        try json.write(result.passed);
        if (result.error_name) |error_name| {
            try json.objectField("error_name");
            try json.write(error_name);
        }
        if (result.response_body) |response_body| {
            try json.objectField("response_body");
            try json.write(response_body);
        }
        try json.endObject();
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const execution_start_epoch_seconds = std.Io.Timestamp.now(io, .real).toSeconds();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2 or std.mem.eql(u8, args[1], "--help") or std.mem.eql(u8, args[1], "-h")) {
        try printUsage(io, args[0]);
        return;
    }

    const uid_prefix = try std.fmt.allocPrint(allocator, "{d}", .{execution_start_epoch_seconds});

    const config_bytes = try std.Io.Dir.cwd().readFileAlloc(io, args[1], allocator, .limited(1024 * 1024));
    var scanner = std.json.Scanner.initCompleteInput(allocator, config_bytes);
    defer scanner.deinit();
    var diagnostics: std.json.Diagnostics = .{};
    scanner.enableDiagnostics(&diagnostics);
    const parsed = std.json.parseFromTokenSource(app.Config, allocator, &scanner, .{
        .ignore_unknown_fields = false,
    }) catch |err| exitWithConfigParseError(io, args[1], err, &diagnostics);
    defer parsed.deinit();
    app.validate(parsed.value) catch |err| {
        exitWithConfigValidationError(io, args[1], err);
    };
    const config = parsed.value;

    const output_file = try std.Io.Dir.cwd().createFile(io, config.output_file, .{ .truncate = true });
    defer output_file.close(io);
    var output_buffer: [4096]u8 = undefined;
    var output = output_file.writer(io, &output_buffer);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &stdout_buffer);

    var client: std.http.Client = .{ .allocator = allocator, .io = io };
    defer client.deinit();

    var seed_bytes: [8]u8 = undefined;
    io.random(&seed_bytes);
    var prng = std.Random.DefaultPrng.init(std.mem.readInt(u64, &seed_bytes, .little));
    const random = prng.random();
    var passed: u64 = 0;
    var failed: u64 = 0;

    try stdout.interface.writeAll("\x1b[2J\x1b[H");
    try renderHeader(&stdout.interface, config, passed, failed);
    try stdout.interface.flush();

    try output.interface.writeAll("[\n");

    for (0..config.run_count) |index| {
        const wait_ms = app.intervalMs(random, config.min_interval_ms, config.max_interval_ms);
        if (wait_ms > 0) try io.sleep(.fromMilliseconds(@intCast(wait_ms)), .awake);

        // Fair coverage: every operation runs once per cycle, while the delay
        // before each operation remains independently random.
        const operation = config.operations[index % config.operations.len];
        const uid = try std.fmt.allocPrint(allocator, "{s}-{d}", .{ uid_prefix, index + 1 });
        const result = runOperation(&client, io, operation, uid, config.max_wait_ms);
        defer if (result.response_body) |body| std.heap.smp_allocator.free(body);
        if (result.passed) passed += 1 else failed += 1;

        if (index > 0) try output.interface.writeAll(",\n");
        try std.json.Stringify.value(result, .{}, &output.interface);
        try output.interface.flush();

        try stdout.interface.writeAll("\x1b[H");
        try renderHeader(&stdout.interface, config, passed, failed);
        try stdout.interface.print("\nLast result\n  [{s}] {s} {s}\n  expected={d} actual={s} duration={d}ms", .{
            if (result.passed) "PASS" else "FAIL",
            result.method,
            result.operation,
            result.expected_status,
            if (result.actual_status) |status| try std.fmt.allocPrint(allocator, "{d}", .{status}) else "-",
            result.duration_ms,
        });
        if (result.error_name) |name| try stdout.interface.print(" error={s}", .{name});
        try stdout.interface.print("\n  url={s}\n\nNext call in {d}-{d}ms; results: {s}\x1b[J", .{
            result.url, config.min_interval_ms, config.max_interval_ms, config.output_file,
        });
        try stdout.interface.flush();
    }

    try output.interface.writeAll("\n]\n");
    try output.interface.flush();

    try stdout.interface.print("\n\nCompleted {d} calls: {d} passed, {d} failed.\n", .{ config.run_count, passed, failed });
    try stdout.interface.flush();
}

const FetchOutcome = struct {
    status: ?u16,
    error_name: ?[]const u8,
    response_body: ?[]u8,
};

const OperationEvent = union(enum) {
    response: FetchOutcome,
    timeout: void,
};

const RequestStart = struct {
    formatted_utc: [23]u8,
    monotonic: std.Io.Clock.Timestamp,
};

fn runOperation(client: *std.http.Client, io: std.Io, operation: app.Operation, uid: []const u8, max_wait_ms: u64) Result {
    const started: RequestStart = .{
        .formatted_utc = formatStartTime(std.Io.Timestamp.now(io, .real)),
        .monotonic = std.Io.Clock.Timestamp.now(io, .awake),
    };
    var header_storage: [65]std.http.Header = undefined;
    const headers = prepareHeaders(operation, uid, &header_storage) orelse
        return makeResult(operation, uid, started, io, null, "TooManyHeaders", null);

    var event_buffer: [2]OperationEvent = undefined;
    var select: std.Io.Select(OperationEvent) = .init(io, &event_buffer);
    select.async(.response, fetchOperation, .{ client, operation, headers });
    select.async(.timeout, waitForTimeout, .{ io, max_wait_ms });

    const event = select.await() catch {
        cancelOperationSelect(&select);
        return makeResult(operation, uid, started, io, null, "Canceled", null);
    };
    cancelOperationSelect(&select);

    return switch (event) {
        .response => |outcome| response: {
            if (outcome.status != null and outcome.status.? == operation.expected_status) {
                if (outcome.response_body) |body| std.heap.smp_allocator.free(body);
                break :response makeResult(operation, uid, started, io, outcome.status, outcome.error_name, null);
            }
            break :response makeResult(operation, uid, started, io, outcome.status, outcome.error_name, outcome.response_body);
        },
        .timeout => makeResult(operation, uid, started, io, null, "Timeout", null),
    };
}

fn prepareHeaders(operation: app.Operation, uid: []const u8, storage: *[65]std.http.Header) ?[]const std.http.Header {
    const implicit_header_count = 1;
    if (operation.headers.len > storage.len - implicit_header_count) return null;

    storage[0] = .{ .name = "X-Unique-ID", .value = uid };
    for (operation.headers, 0..) |header, i| {
        storage[i + implicit_header_count] = .{ .name = header.name, .value = header.value };
    }
    return storage[0 .. operation.headers.len + implicit_header_count];
}

fn cancelOperationSelect(select: *std.Io.Select(OperationEvent)) void {
    while (select.cancel()) |event| switch (event) {
        .response => |outcome| if (outcome.response_body) |body| std.heap.smp_allocator.free(body),
        .timeout => {},
    };
}

fn fetchOperation(client: *std.http.Client, operation: app.Operation, headers: []const std.http.Header) FetchOutcome {
    var allocated_body: ?[]u8 = null;
    defer if (allocated_body) |body| client.allocator.free(body);
    const payload: ?[]const u8 = if (operation.body) |body| switch (body) {
        .string => |string| string,
        else => blk: {
            allocated_body = std.json.Stringify.valueAlloc(client.allocator, body, .{}) catch
                return .{ .status = null, .error_name = "OutOfMemory", .response_body = null };
            break :blk allocated_body.?;
        },
    } else null;

    const method = std.meta.stringToEnum(std.http.Method, operation.method).?;
    var response_body: std.Io.Writer.Allocating = .init(std.heap.smp_allocator);
    defer response_body.deinit();
    const response = client.fetch(.{
        .location = .{ .url = operation.url },
        .method = method,
        .payload = payload,
        .extra_headers = headers,
        .keep_alive = false,
        .response_writer = &response_body.writer,
    }) catch |err| return .{ .status = null, .error_name = @errorName(err), .response_body = null };
    const owned_body = response_body.toOwnedSlice() catch
        return .{ .status = null, .error_name = "OutOfMemory", .response_body = null };
    return .{ .status = @backingInt(response.status), .error_name = null, .response_body = owned_body };
}

fn waitForTimeout(io: std.Io, max_wait_ms: u64) void {
    io.sleep(.fromMilliseconds(@intCast(max_wait_ms)), .awake) catch {};
}

fn makeResult(operation: app.Operation, uid: []const u8, started: RequestStart, io: std.Io, status: ?u16, error_name: ?[]const u8, response_body: ?[]u8) Result {
    const elapsed_ms = started.monotonic.untilNow(io).raw.toMilliseconds();
    return .{
        .uid = uid,
        .start_time = started.formatted_utc,
        .operation = operation.name,
        .method = operation.method,
        .url = operation.url,
        .expected_status = operation.expected_status,
        .actual_status = status,
        .duration_ms = @intCast(elapsed_ms),
        .passed = status != null and status.? == operation.expected_status,
        .error_name = error_name,
        .response_body = response_body,
    };
}

fn formatStartTime(timestamp: std.Io.Timestamp) [23]u8 {
    const total_ms = @divFloor(timestamp.toNanoseconds(), std.time.ns_per_ms);
    const epoch_seconds: std.time.epoch.EpochSeconds = .{
        .secs = @intCast(@divFloor(total_ms, std.time.ms_per_s)),
    };
    const year_day = epoch_seconds.getEpochDay().calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch_seconds.getDaySeconds();
    const milliseconds: u10 = @intCast(@mod(total_ms, std.time.ms_per_s));

    var buffer: [23]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buffer, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
        day_seconds.getSecondsIntoMinute(),
        milliseconds,
    }) catch unreachable;
    std.debug.assert(formatted.len == buffer.len);
    return buffer;
}

fn renderHeader(writer: *std.Io.Writer, config: app.Config, passed: u64, failed: u64) !void {
    try writer.print("API operation tester\n====================\nOperations: {d}  Calls: {d}/{d}  Passed: {d}  Failed: {d}\n", .{
        config.operations.len, passed + failed, config.run_count, passed, failed,
    });
}

fn printUsage(io: std.Io, executable: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buffer);
    try stdout.interface.print("Usage: {s} <config.json>\n", .{executable});
    try stdout.interface.flush();
}

fn exitWithConfigParseError(io: std.Io, path: []const u8, err: anyerror, diagnostics: *const std.json.Diagnostics) noreturn {
    var buffer: [1024]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(io, &buffer);
    stderr.interface.print("Invalid configuration in {s} at line {d}, column {d}: {s}\n", .{
        path,
        diagnostics.getLine(),
        diagnostics.getColumn(),
        @errorName(err),
    }) catch {};
    stderr.interface.flush() catch {};
    std.process.exit(1);
}

fn exitWithConfigValidationError(io: std.Io, path: []const u8, err: anyerror) noreturn {
    var buffer: [1024]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(io, &buffer);
    stderr.interface.print("Invalid configuration in {s}: {s}\n", .{ path, @errorName(err) }) catch {};
    stderr.interface.flush() catch {};
    std.process.exit(1);
}

test "successful result omits empty error fields" {
    const result: Result = .{
        .uid = "1784643192-1",
        .start_time = "2026-07-21 14:13:12.000".*,
        .operation = "health",
        .method = "GET",
        .url = "https://example.com/health",
        .expected_status = 200,
        .actual_status = 200,
        .duration_ms = 10,
        .passed = true,
        .error_name = null,
        .response_body = null,
    };
    const encoded = try std.json.Stringify.valueAlloc(std.testing.allocator, result, .{});
    defer std.testing.allocator.free(encoded);

    try std.testing.expect(std.mem.startsWith(u8, encoded, "{\"uid\":\"1784643192-1\","));
    try std.testing.expect(std.mem.indexOf(u8, encoded, "error_name") == null);
    try std.testing.expect(std.mem.indexOf(u8, encoded, "response_body") == null);
}

test "start time uses UTC millisecond format" {
    const timestamp = std.Io.Timestamp.fromNanoseconds(1_784_643_192 * std.time.ns_per_s);
    try std.testing.expectEqualStrings("2026-07-21 14:13:12.000", &formatStartTime(timestamp));
}

test "implicit request headers precede configured headers" {
    const operation: app.Operation = .{
        .name = "health",
        .url = "https://example.com/health",
        .method = "GET",
        .headers = &.{.{ .name = "Accept", .value = "application/json" }},
        .expected_status = 200,
    };
    var storage: [65]std.http.Header = undefined;
    const headers = prepareHeaders(operation, "1784643192-7", &storage).?;

    try std.testing.expectEqual(@as(usize, 2), headers.len);
    try std.testing.expectEqualStrings("X-Unique-ID", headers[0].name);
    try std.testing.expectEqualStrings("1784643192-7", headers[0].value);
    try std.testing.expectEqualStrings("Accept", headers[1].name);
}
