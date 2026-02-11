const std = @import("std");
const Tool = @import("base.zig").Tool;

/// Tool registry for managing available tools
pub const ToolRegistry = struct {
    const Self = @This();

    tools: std.StringHashMap(Tool),
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    /// Initialize tool registry
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .tools = std.StringHashMap(Tool).init(allocator),
            .mutex = .{},
            .allocator = allocator,
        };
        return self;
    }

    /// Clean up registry
    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        var iter = self.tools.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
        }
        self.tools.deinit();
        self.allocator.destroy(self);
    }

    /// Register a tool
    pub fn register(self: *Self, tool: Tool) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const name = tool.name();
        try self.tools.put(name, tool);
    }

    /// Get a tool by name
    pub fn get(self: *Self, name: []const u8) ?Tool {
        self.mutex.lock();
        defer self.mutex.unlock();

        return self.tools.get(name);
    }

    /// Execute a tool by name
    pub fn execute(
        self: *Self,
        name: []const u8,
        args: std.json.Value,
        allocator: std.mem.Allocator,
    ) ![]const u8 {
        const tool = self.get(name) orelse return error.ToolNotFound;
        return tool.execute(args, allocator);
    }

    /// Get all tool definitions as JSON schemas
    pub fn getDefinitions(self: *Self, allocator: std.mem.Allocator) ![]std.json.Value {
        self.mutex.lock();
        defer self.mutex.unlock();

        var definitions = std.ArrayList(std.json.Value).init(allocator);
        errdefer definitions.deinit();

        var iter = self.tools.valueIterator();
        while (iter.next()) |tool| {
            const schema = try @import("base.zig").toolToSchema(tool.*, allocator);
            try definitions.append(schema);
        }

        return definitions.toOwnedSlice();
    }
};

test "tool registry" {
    const allocator = std.testing.allocator;
    const registry = try ToolRegistry.init(allocator);
    defer registry.deinit();

    // Test would need actual tool implementation
}
