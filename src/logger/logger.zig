const std = @import("std");

pub const Level = enum {
    debug,
    info,
    warn,
    err,

    pub fn toString(self: Level) []const u8 {
        return switch (self) {
            .debug => "DEBUG",
            .info => "INFO",
            .warn => "WARN",
            .err => "ERROR",
        };
    }

    pub fn color(self: Level) []const u8 {
        return switch (self) {
            .debug => "\x1b[36m", // Cyan
            .info => "\x1b[32m", // Green
            .warn => "\x1b[33m", // Yellow
            .err => "\x1b[31m", // Red
        };
    }
};

const RESET = "\x1b[0m";

/// Log a message with a specific level
pub fn log(level: Level, comptime category: []const u8, comptime fmt: []const u8, args: anytype) void {
    const stderr = std.io.getStdErr().writer();

    stderr.print("{s}[{s}]{s} [{s}] ", .{
        level.color(),
        level.toString(),
        RESET,
        category,
    }) catch return;

    stderr.print(fmt, args) catch return;
    stderr.writeByte('\n') catch return;
}

/// Log debug message
pub fn debug(comptime category: []const u8, comptime fmt: []const u8, args: anytype) void {
    log(.debug, category, fmt, args);
}

/// Log info message
pub fn info(comptime category: []const u8, comptime fmt: []const u8, args: anytype) void {
    log(.info, category, fmt, args);
}

/// Log warning message
pub fn warn(comptime category: []const u8, comptime fmt: []const u8, args: anytype) void {
    log(.warn, category, fmt, args);
}

/// Log error message
pub fn err(comptime category: []const u8, comptime fmt: []const u8, args: anytype) void {
    log(.err, category, fmt, args);
}

test "logger basic" {
    info("test", "Hello, {s}!", .{"world"});
    debug("test", "Debug value: {d}", .{42});
    warn("test", "Warning!", .{});
    err("test", "Error!", .{});
}
