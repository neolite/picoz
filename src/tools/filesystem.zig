const std = @import("std");
const base = @import("base.zig");

/// Read file tool - reads contents of a file
pub const ReadFileTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "read_file";
    }

    pub fn description(_: *Self) []const u8 {
        return "Read the contents of a file";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        // TODO: Return proper JSON schema
        return .null;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        _ = self;

        const path = switch (args) {
            .object => |obj| blk: {
                if (obj.get("path")) |path_val| {
                    if (path_val == .string) {
                        break :blk path_val.string;
                    }
                }
                return error.PathRequired;
            },
            else => return error.InvalidArguments,
        };

        const file = try std.fs.openFileAbsolute(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // 10MB max
        return content;
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

/// Write file tool - writes content to a file
pub const WriteFileTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "write_file";
    }

    pub fn description(_: *Self) []const u8 {
        return "Write content to a file";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        return .null;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        _ = self;

        const obj = switch (args) {
            .object => |o| o,
            else => return error.InvalidArguments,
        };

        const path = if (obj.get("path")) |p| switch (p) {
            .string => |s| s,
            else => return error.PathRequired,
        } else return error.PathRequired;

        const content = if (obj.get("content")) |c| switch (c) {
            .string => |s| s,
            else => return error.ContentRequired,
        } else return error.ContentRequired;

        // Create parent directory if needed
        if (std.fs.path.dirname(path)) |dir| {
            std.fs.makeDirAbsolute(dir) catch |err| {
                if (err != error.PathAlreadyExists) return err;
            };
        }

        // Write file
        const file = try std.fs.createFileAbsolute(path, .{});
        defer file.close();
        try file.writeAll(content);

        return try std.fmt.allocPrint(allocator, "File written successfully to {s}", .{path});
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

/// List directory tool - lists files and directories
pub const ListDirTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "list_dir";
    }

    pub fn description(_: *Self) []const u8 {
        return "List files and directories in a path";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        return .null;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        _ = self;

        const path = switch (args) {
            .object => |obj| blk: {
                if (obj.get("path")) |path_val| {
                    if (path_val == .string) {
                        break :blk path_val.string;
                    }
                }
                break :blk ".";
            },
            else => ".",
        };

        var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
        defer dir.close();

        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            const prefix = if (entry.kind == .directory) "DIR:  " else "FILE: ";
            try result.writer().print("{s}{s}\n", .{ prefix, entry.name });
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
