const std = @import("std");

/// Tool interface
pub const Tool = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        name: *const fn (ptr: *anyopaque) []const u8,
        description: *const fn (ptr: *anyopaque) []const u8,
        parameters: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) std.json.Value,
        execute: *const fn (
            ptr: *anyopaque,
            args: std.json.Value,
            allocator: std.mem.Allocator,
        ) anyerror![]const u8,
        deinit: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void,
    };

    pub fn name(self: Self) []const u8 {
        return self.vtable.name(self.ptr);
    }

    pub fn description(self: Self) []const u8 {
        return self.vtable.description(self.ptr);
    }

    pub fn parameters(self: Self, allocator: std.mem.Allocator) std.json.Value {
        return self.vtable.parameters(self.ptr, allocator);
    }

    pub fn execute(self: Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        return self.vtable.execute(self.ptr, args, allocator);
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.ptr, allocator);
    }
};

/// Convert tool to JSON schema for LLM
pub fn toolToSchema(tool: Tool, allocator: std.mem.Allocator) !std.json.Value {
    const schema = std.json.ObjectMap.init(allocator);
    try schema.put("type", .{ .string = "function" });

    const function = std.json.ObjectMap.init(allocator);
    try function.put("name", .{ .string = tool.name() });
    try function.put("description", .{ .string = tool.description() });
    try function.put("parameters", tool.parameters(allocator));

    try schema.put("function", .{ .object = function });

    return .{ .object = schema };
}
