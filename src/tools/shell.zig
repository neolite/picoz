const std = @import("std");
const base = @import("base.zig");

/// Exec tool - executes shell commands with safety guards
pub const ExecTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    working_dir: []const u8,
    timeout_ms: u64,
    restrict_to_workspace: bool,

    const DANGEROUS_PATTERNS = [_][]const u8{
        "rm -rf",
        "rm -fr",
        "del /f",
        "del /q",
        "rmdir /s",
        "format",
        "mkfs",
        "diskpart",
        "dd if=",
        ">/dev/sd",
        "shutdown",
        "reboot",
        "poweroff",
    };

    pub fn init(working_dir: []const u8, allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
            .working_dir = try allocator.dupe(u8, working_dir),
            .timeout_ms = 60 * 1000, // 60 seconds
            .restrict_to_workspace = false,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.working_dir);
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "exec";
    }

    pub fn description(_: *Self) []const u8 {
        return "Execute a shell command and return its output. Use with caution.";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        return .null;
    }

    fn isDangerous(command: []const u8) bool {
        const lower = std.ascii.allocLowerString(std.heap.page_allocator, command) catch return true;
        defer std.heap.page_allocator.free(lower);

        for (DANGEROUS_PATTERNS) |pattern| {
            if (std.mem.indexOf(u8, lower, pattern) != null) {
                return true;
            }
        }
        return false;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        const obj = switch (args) {
            .object => |o| o,
            else => return error.InvalidArguments,
        };

        const command = if (obj.get("command")) |c| switch (c) {
            .string => |s| s,
            else => return error.CommandRequired,
        } else return error.CommandRequired;

        // Safety check
        if (isDangerous(command)) {
            return try std.fmt.allocPrint(
                allocator,
                "Error: Command blocked by safety guard (dangerous pattern detected)",
                .{},
            );
        }

        var working_dir = self.working_dir;
        if (obj.get("working_dir")) |wd| {
            if (wd == .string) {
                working_dir = wd.string;
            }
        }

        // Execute command
        var child = std.process.Child.init(&[_][]const u8{ "sh", "-c", command }, allocator);
        child.cwd = working_dir;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();

        var stdout = std.ArrayList(u8).init(allocator);
        defer stdout.deinit();
        var stderr = std.ArrayList(u8).init(allocator);
        defer stderr.deinit();

        try child.collectOutput(&stdout, &stderr, 10 * 1024 * 1024); // 10MB max

        const term = try child.wait();

        var result = std.ArrayList(u8).init(allocator);
        errdefer result.deinit();

        if (stdout.items.len > 0) {
            try result.appendSlice(stdout.items);
        }

        if (stderr.items.len > 0) {
            try result.appendSlice("\nSTDERR:\n");
            try result.appendSlice(stderr.items);
        }

        if (term != .Exited or term.Exited != 0) {
            try result.writer().print("\nExit code: {d}", .{
                if (term == .Exited) term.Exited else -1,
            });
        }

        if (result.items.len == 0) {
            try result.appendSlice("(no output)");
        }

        // Truncate if too long
        const max_len = 10000;
        if (result.items.len > max_len) {
            result.items.len = max_len;
            try result.writer().print("\n... (truncated, {} more chars)", .{
                result.items.len - max_len,
            });
        }

        return result.toOwnedSlice();
    }

    pub fn toTool(self: *Self) base.Tool {
        return base.Tool{
            .ptr = self,
            .vtable = &.{
                .name = vtableName,
                .description = vtableDescription,
                .parameters = vtableParameters,
                .execute = vtableExecute,
                .deinit = vtableDeinit,
            },
        };
    }

    fn vtableName(ptr: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.name();
    }

    fn vtableDescription(ptr: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.description();
    }

    fn vtableParameters(ptr: *anyopaque, allocator: std.mem.Allocator) std.json.Value {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.parameters(allocator);
    }

    fn vtableExecute(ptr: *anyopaque, args: std.json.Value, allocator: std.mem.Allocator) anyerror![]const u8 {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return self.execute(args, allocator);
    }

    fn vtableDeinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        _ = allocator;
        self.deinit();
    }
};
