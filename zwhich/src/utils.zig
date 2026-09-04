const std = @import("std");

/// It checks if a file system entry exists at the given path.
///
/// This function attempts to access the specified path and returns:
/// - `true`, if the path exists (file, directory, symlink, etc.)
/// - `false`, if the path does not exist or any error
///
/// ### Parameters
/// - `io`: Io instance for async filesystem access
/// - `path`: File system path to check
///
pub fn canAccess(io: std.Io, path: []const u8) bool {
    var found: bool = true;
    std.Io.Dir.cwd().access(io, path, .{}) catch |e| switch (e) {
        error.FileNotFound => found = false,
        else => found = false,
    };
    return found;
}

/// Determines if a path points to a regular file.
///
/// It returns `false` for directories, symlinks, or any access errors.
///
/// ### Parameters
/// - `io`: Io instance for async filesystem access
/// - `path`: File system path to check
///
/// ### See also:
/// - `canAccess`: For generic existence check
/// - `isExecutable`: For executable verification
///
pub fn isFile(io: std.Io, path: []const u8) bool {
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    return stat.kind == .file;
}

/// It hecks if a file is executable by any user (UNIX permissions).
///
/// It examines the file mode's executable bits (owner/group/others).\
/// It returns `false` for non-files or inaccessible paths.
///
/// ### Parameters
/// - `io`: Io instance for async filesystem access
/// - `path`: File system path to check
///
pub fn isExecutable(io: std.Io, path: []const u8) bool {
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    const mode = stat.permissions.toMode();
    return (mode & 0o111) != 0;
}
