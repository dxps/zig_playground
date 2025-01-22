const std = @import("std");

var _logger: ?std.fs.File.Writer = null;

/// Init the logger, if you want to use this logging module.
pub fn initLog(logger: std.fs.File.Writer) void {
    _logger = logger;
}

/// Log a message.
pub fn log(comptime format: []const u8, args: anytype) void {
    if (_logger) |logger| {
        logger.print(">>> " ++ format, args) catch return;
    }
}
