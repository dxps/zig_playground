const std = @import("std");
const Io = std.Io;
const File = std.Io.File;

const ztee = @import("ztee");

pub fn main(init: std.process.Init) !void {

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    // var stdout_buffer: [1024]u8 = undefined;
    // var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    // const stdout_writer = &stdout_file_writer.interface;
    // try stdout_writer.flush(); // Don't forget to flush!

    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);

    const io = init.io;
    const stdout = File.stdout();
    const stderr = File.stderr();
    const stdin = File.stdin();

    checkHelp(stdout, io, args);

    // Default configuration.
    var append_mode = false;
    var files_start_index: usize = 1;

    // Check for -a / --append flag.
    if (args.len > 1) {
        const arg1 = args[1];
        if (std.mem.eql(u8, arg1, "-a") or std.mem.eql(u8, arg1, "--append")) {
            append_mode = true;
            files_start_index = 2;
        }
        // Open output files.
        var out_files = std.ArrayList(std.Io.File).empty; // List of file descriptors.
        defer {
            for (out_files.items) |out_file| out_file.close(io);
            out_files.deinit(alloc);
        }
        var write_offsets = std.ArrayList(u64).empty;
        defer write_offsets.deinit(alloc);

        var i = files_start_index;
        while (i < args.len) : (i += 1) {
            const path = args[i];
            const file = std.Io.Dir.cwd().createFile(io, path, .{ .truncate = !append_mode }) catch |err| {
                const msg = try std.fmt.allocPrint(alloc, "ztee: {s}: {s}\n", .{ path, @errorName(err) });
                try stderr.writeStreamingAll(io, msg);
                continue;
            };
            const initial_offset: u64 = if (append_mode) blk: {
                const stat = try file.stat(io);
                break :blk stat.size;
            } else 0;
            try out_files.append(alloc, file);
            try write_offsets.append(alloc, initial_offset);
        }

        // The I/O loop: buffering data efficiently.
        var buf: [4096]u8 = undefined;
        while (true) {
            const bytes_read = stdin.readStreaming(io, &.{&buf}) catch |err| {
                if (err == error.EndOfStream) break;
                return err;
            };
            if (bytes_read == 0) break;

            const chunk = buf[0..bytes_read];
            try stdout.writeStreamingAll(io, chunk);

            for (out_files.items, 0..) |out_file, idx| {
                if (append_mode) {
                    out_file.writePositionalAll(io, chunk, write_offsets.items[idx]) catch |err| {
                        try log_write_error(alloc, io, stderr, args[idx + files_start_index], err);
                    };
                } else {
                    out_file.writeStreamingAll(io, chunk) catch |err| {
                        try log_write_error(alloc, io, stderr, args[idx + files_start_index], err);
                    };
                }
            }
        }
    }
}

fn checkHelp(stdout: File, io: Io, args: []const []const u8) void {
    if (args.len > 1) {
        const arg1 = args[1];
        if (std.mem.eql(u8, arg1, "-h") or std.mem.eql(u8, arg1, "--help")) {
            const help_text =
                \\Usage: ztee [options]... [file]...
                \\Copy standard input to each file, and also to standard output.
                \\
                \\Options:
                \\   -a, --append       append to the given files, do not overwrite
                \\   -h, --help         display this help and exit
                \\
            ;
            stdout.writeStreamingAll(io, help_text) catch |err| {
                std.debug.print("ztee: Failed to show help text: {s}\n", .{@errorName(err)});
            };
            std.process.exit(0);
        }
    }
}

fn log_write_error(alloc: std.mem.Allocator, io: Io, stderr: File, filename: []const u8, err: anyerror) !void {
    const msg = try std.fmt.allocPrint(alloc, "ztee: write error (for file {s}): {s}\n", .{ filename, @errorName(err) });
    try stderr.writeStreamingAll(io, msg);
}
