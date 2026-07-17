const std = @import("std");
const app = @import("zig_test_api_tui");

const Result = struct {
    sequence: u64,
    operation: []const u8,
    method: []const u8,
    url: []const u8,
    expected_status: u16,
    actual_status: ?u16,
    duration_ms: u64,
    passed: bool,
    error_name: ?[]const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2 or std.mem.eql(u8, args[1], "--help") or std.mem.eql(u8, args[1], "-h")) {
        try printUsage(io, args[0]);
        if (args.len == 2) return;
        return error.InvalidArguments;
    }

    const config_bytes = try std.Io.Dir.cwd().readFileAlloc(io, args[1], allocator, .limited(1024 * 1024));
    const parsed = try std.json.parseFromSlice(app.Config, allocator, config_bytes, .{
        .ignore_unknown_fields = false,
    });
    defer parsed.deinit();
    try app.validate(parsed.value);
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

    for (0..config.run_count) |index| {
        const wait_ms = app.intervalMs(random, config.min_interval_ms, config.max_interval_ms);
        if (wait_ms > 0) try io.sleep(.fromMilliseconds(@intCast(wait_ms)), .awake);

        // Fair coverage: every operation runs once per cycle, while the delay
        // before each operation remains independently random.
        const operation = config.operations[index % config.operations.len];
        const result = runOperation(&client, io, operation, index + 1);
        if (result.passed) passed += 1 else failed += 1;

        try std.json.Stringify.value(result, .{}, &output.interface);
        try output.interface.writeByte('\n');
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

    try stdout.interface.print("\n\nCompleted {d} calls: {d} passed, {d} failed.\n", .{ config.run_count, passed, failed });
    try stdout.interface.flush();
}

fn runOperation(client: *std.http.Client, io: std.Io, operation: app.Operation, sequence: usize) Result {
    const started = std.Io.Clock.Timestamp.now(io, .awake);
    var headers: [64]std.http.Header = undefined;
    if (operation.headers.len > headers.len) return makeResult(operation, sequence, started, io, null, "TooManyHeaders");
    for (operation.headers, 0..) |header, i| headers[i] = .{ .name = header.name, .value = header.value };

    const method = std.meta.stringToEnum(std.http.Method, operation.method).?;
    const response = client.fetch(.{
        .location = .{ .url = operation.url },
        .method = method,
        .payload = operation.body,
        .extra_headers = headers[0..operation.headers.len],
    }) catch |err| return makeResult(operation, sequence, started, io, null, @errorName(err));
    return makeResult(operation, sequence, started, io, @intFromEnum(response.status), null);
}

fn makeResult(operation: app.Operation, sequence: usize, started: std.Io.Clock.Timestamp, io: std.Io, status: ?u16, error_name: ?[]const u8) Result {
    const elapsed_ms = started.untilNow(io).raw.toMilliseconds();
    return .{
        .sequence = sequence,
        .operation = operation.name,
        .method = operation.method,
        .url = operation.url,
        .expected_status = operation.expected_status,
        .actual_status = status,
        .duration_ms = @intCast(elapsed_ms),
        .passed = status != null and status.? == operation.expected_status,
        .error_name = error_name,
    };
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
