const std = @import("std");
const base = @import("base.zig");

/// Web search tool using Brave Search API
pub const WebSearchTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    api_key: []const u8,
    max_results: i32,

    pub fn init(api_key: []const u8, max_results: i32, allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
            .api_key = try allocator.dupe(u8, api_key),
            .max_results = if (max_results > 0 and max_results <= 10) max_results else 5,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.api_key);
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "web_search";
    }

    pub fn description(_: *Self) []const u8 {
        return "Search the web. Returns titles, URLs, and snippets.";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        return .null;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        if (self.api_key.len == 0) {
            return try allocator.dupe(u8, "Error: BRAVE_API_KEY not configured");
        }

        const obj = switch (args) {
            .object => |o| o,
            else => return error.InvalidArguments,
        };

        const query = if (obj.get("query")) |q| switch (q) {
            .string => |s| s,
            else => return error.QueryRequired,
        } else return error.QueryRequired;

        // TODO: Implement HTTP request to Brave Search API
        // For now, return placeholder
        return try std.fmt.allocPrint(
            allocator,
            "Search results for: {s}\n(HTTP client not yet implemented in Zig version)",
            .{query},
        );
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

/// Web fetch tool - fetches URL content
pub const WebFetchTool = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    max_chars: usize,

    pub fn init(max_chars: usize, allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
            .max_chars = if (max_chars > 0) max_chars else 50000,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn name(_: *Self) []const u8 {
        return "web_fetch";
    }

    pub fn description(_: *Self) []const u8 {
        return "Fetch a URL and extract readable content (HTML to text)";
    }

    pub fn parameters(self: *Self) std.json.Value {
        _ = self;
        return .null;
    }

    pub fn execute(self: *Self, args: std.json.Value, allocator: std.mem.Allocator) ![]const u8 {
        const obj = switch (args) {
            .object => |o| o,
            else => return error.InvalidArguments,
        };

        const url = if (obj.get("url")) |u| switch (u) {
            .string => |s| s,
            else => return error.UrlRequired,
        } else return error.UrlRequired;

        // TODO: Implement HTTP request
        _ = self;
        return try std.fmt.allocPrint(
            allocator,
            "Would fetch: {s}\n(HTTP client not yet implemented in Zig version)",
            .{url},
        );
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
