//! This package helps you generate UUIDs.
//!

const uuid = @import("uuid.zig");
pub const Uuid = uuid.Uuid;

// Re-exporting for convenience (shorter name).
