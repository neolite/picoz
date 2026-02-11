const std = @import("std");

/// Tool call from LLM response
pub const ToolCall = struct {
    id: []const u8,
    type: []const u8,
    function: ?FunctionCall,
    name: ?[]const u8,
    arguments: ?std.json.Value,

    pub fn deinit(self: *ToolCall, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.type);
        if (self.function) |*func| {
            func.deinit(allocator);
        }
        if (self.name) |name| {
            allocator.free(name);
        }
    }
};

/// Function call details
pub const FunctionCall = struct {
    name: []const u8,
    arguments: []const u8,

    pub fn deinit(self: *FunctionCall, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.arguments);
    }
};

/// LLM response
pub const LLMResponse = struct {
    content: []const u8,
    tool_calls: []ToolCall,
    finish_reason: []const u8,
    usage: ?UsageInfo,

    pub fn deinit(self: *LLMResponse, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
        for (self.tool_calls) |*call| {
            call.deinit(allocator);
        }
        allocator.free(self.tool_calls);
        allocator.free(self.finish_reason);
        if (self.usage) |usage| {
            _ = usage;
            // UsageInfo is just integers, no cleanup needed
        }
    }
};

/// Token usage information
pub const UsageInfo = struct {
    prompt_tokens: i32,
    completion_tokens: i32,
    total_tokens: i32,
};

/// Message in conversation
pub const Message = struct {
    role: []const u8,
    content: []const u8,
    tool_calls: []ToolCall,
    tool_call_id: ?[]const u8,

    pub fn deinit(self: *Message, allocator: std.mem.Allocator) void {
        allocator.free(self.role);
        allocator.free(self.content);
        for (self.tool_calls) |*call| {
            call.deinit(allocator);
        }
        allocator.free(self.tool_calls);
        if (self.tool_call_id) |id| {
            allocator.free(id);
        }
    }
};

/// Tool definition for LLM
pub const ToolDefinition = struct {
    type: []const u8,
    function: ToolFunctionDefinition,

    pub fn deinit(self: *ToolDefinition, allocator: std.mem.Allocator) void {
        allocator.free(self.type);
        self.function.deinit(allocator);
    }
};

/// Tool function definition
pub const ToolFunctionDefinition = struct {
    name: []const u8,
    description: []const u8,
    parameters: std.json.Value,

    pub fn deinit(self: *ToolFunctionDefinition, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.description);
        // parameters is managed elsewhere
    }
};

/// LLM Provider interface
pub const LLMProvider = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        chat: *const fn (
            ptr: *anyopaque,
            messages: []const Message,
            tools: []const ToolDefinition,
            model: []const u8,
            options: std.json.Value,
            allocator: std.mem.Allocator,
        ) anyerror!LLMResponse,

        getDefaultModel: *const fn (ptr: *anyopaque) []const u8,

        deinit: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void,
    };

    pub fn chat(
        self: Self,
        messages: []const Message,
        tools: []const ToolDefinition,
        model: []const u8,
        options: std.json.Value,
        allocator: std.mem.Allocator,
    ) !LLMResponse {
        return self.vtable.chat(self.ptr, messages, tools, model, options, allocator);
    }

    pub fn getDefaultModel(self: Self) []const u8 {
        return self.vtable.getDefaultModel(self.ptr);
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.ptr, allocator);
    }
};
