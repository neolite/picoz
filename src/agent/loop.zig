const std = @import("std");
const config = @import("../config/config.zig");
const bus = @import("../bus/bus.zig");
const providers = @import("../providers/types.zig");
const session = @import("../session/manager.zig");
const tools = @import("../tools/registry.zig");
const logger = @import("../logger/logger.zig");

/// Agent loop for processing messages
pub const AgentLoop = struct {
    const Self = @This();

    bus: *bus.MessageBus,
    provider: providers.LLMProvider,
    workspace: []const u8,
    model: []const u8,
    context_window: i32,
    max_iterations: i32,
    sessions: *session.SessionManager,
    tools_registry: *tools.ToolRegistry,
    running: bool,
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    /// Initialize agent loop
    pub fn init(
        cfg: config.Config,
        message_bus: *bus.MessageBus,
        provider: providers.LLMProvider,
        allocator: std.mem.Allocator,
    ) !*Self {
        const workspace = try allocator.dupe(u8, cfg.agents.defaults.workspace);
        const model = try allocator.dupe(u8, cfg.agents.defaults.model);

        // Create workspace directory
        std.fs.makeDirAbsolute(workspace) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        // Initialize tools registry
        const tools_reg = try tools.ToolRegistry.init(allocator);
        errdefer tools_reg.deinit();

        // TODO: Register tools
        // try tools_reg.register(ReadFileTool.init(allocator));
        // try tools_reg.register(WriteFileTool.init(allocator));
        // try tools_reg.register(ExecTool.init(workspace, allocator));
        // etc.

        // Initialize session manager
        const sessions_path = try std.fmt.allocPrint(allocator, "{s}/../sessions", .{workspace});
        defer allocator.free(sessions_path);

        const session_mgr = try session.SessionManager.init(sessions_path, allocator);
        errdefer session_mgr.deinit();

        const self = try allocator.create(Self);
        self.* = Self{
            .bus = message_bus,
            .provider = provider,
            .workspace = workspace,
            .model = model,
            .context_window = cfg.agents.defaults.max_tokens,
            .max_iterations = cfg.agents.defaults.max_tool_iterations,
            .sessions = session_mgr,
            .tools_registry = tools_reg,
            .running = false,
            .mutex = .{},
            .allocator = allocator,
        };

        return self;
    }

    /// Clean up agent loop
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.workspace);
        self.allocator.free(self.model);
        self.tools_registry.deinit();
        self.sessions.deinit();
        self.allocator.destroy(self);
    }

    /// Run agent loop (blocking)
    pub fn run(self: *Self) !void {
        self.mutex.lock();
        self.running = true;
        self.mutex.unlock();

        logger.info("agent", "Agent loop started", .{});

        while (true) {
            self.mutex.lock();
            const is_running = self.running;
            self.mutex.unlock();

            if (!is_running) break;

            // Try to consume inbound message
            if (self.bus.tryConsumeInbound()) |msg| {
                const response = self.processMessage(msg) catch |err| blk: {
                    logger.err("agent", "Error processing message: {}", .{err});
                    break :blk try std.fmt.allocPrint(
                        self.allocator,
                        "Error processing message: {}",
                        .{err},
                    );
                };

                if (response.len > 0) {
                    try self.bus.publishOutbound(.{
                        .channel = try self.allocator.dupe(u8, msg.channel),
                        .chat_id = try self.allocator.dupe(u8, msg.chat_id),
                        .content = response,
                    });
                }

                var mutable_msg = msg;
                mutable_msg.deinit(self.allocator);
            } else {
                // Sleep briefly to avoid busy-waiting
                std.time.sleep(10 * std.time.ns_per_ms);
            }
        }

        logger.info("agent", "Agent loop stopped", .{});
    }

    /// Stop agent loop
    pub fn stop(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.running = false;
    }

    /// Process direct message (for CLI)
    pub fn processDirect(
        self: *Self,
        content: []const u8,
        session_key: []const u8,
    ) ![]const u8 {
        const msg = bus.InboundMessage{
            .channel = try self.allocator.dupe(u8, "cli"),
            .sender_id = try self.allocator.dupe(u8, "user"),
            .chat_id = try self.allocator.dupe(u8, "direct"),
            .content = try self.allocator.dupe(u8, content),
            .session_key = try self.allocator.dupe(u8, session_key),
        };

        return self.processMessage(msg);
    }

    /// Process a message and return response
    fn processMessage(self: *Self, msg: bus.InboundMessage) ![]const u8 {
        logger.info("agent", "Processing message from {s}", .{msg.sender_id});

        // Get conversation history and summary
        const history = self.sessions.getHistory(msg.session_key);
        const summary = self.sessions.getSummary(msg.session_key);

        // Build messages for LLM
        var messages = std.ArrayList(providers.Message).init(self.allocator);
        defer messages.deinit();

        // Add system prompt
        try messages.append(.{
            .role = try self.allocator.dupe(u8, "system"),
            .content = try self.allocator.dupe(u8, "You are a helpful AI assistant."),
            .tool_calls = &[_]providers.ToolCall{},
            .tool_call_id = null,
        });

        // Add summary if exists
        if (summary) |s| {
            try messages.append(.{
                .role = try self.allocator.dupe(u8, "system"),
                .content = try std.fmt.allocPrint(
                    self.allocator,
                    "Previous conversation summary: {s}",
                    .{s},
                ),
                .tool_calls = &[_]providers.ToolCall{},
                .tool_call_id = null,
            });
        }

        // Add history
        for (history) |hist_msg| {
            try messages.append(hist_msg);
        }

        // Add current message
        try messages.append(.{
            .role = try self.allocator.dupe(u8, "user"),
            .content = try self.allocator.dupe(u8, msg.content),
            .tool_calls = &[_]providers.ToolCall{},
            .tool_call_id = null,
        });

        // Agent loop with tool calling
        var iteration: i32 = 0;
        var final_content: []const u8 = "";

        while (iteration < self.max_iterations) : (iteration += 1) {
            // Get tool definitions
            const tool_defs = try self.tools_registry.getDefinitions(self.allocator);
            defer self.allocator.free(tool_defs);

            // TODO: Convert tool_defs to provider format
            const provider_tools = &[_]providers.ToolDefinition{};

            // Call LLM
            const options = std.json.Value{ .object = std.json.ObjectMap.init(self.allocator) };
            var response = try self.provider.chat(
                messages.items,
                provider_tools,
                self.model,
                options,
                self.allocator,
            );
            defer response.deinit(self.allocator);

            logger.debug("agent", "LLM response: {s}", .{response.content});

            // If no tool calls, we're done
            if (response.tool_calls.len == 0) {
                final_content = try self.allocator.dupe(u8, response.content);
                break;
            }

            // Execute tool calls
            for (response.tool_calls) |tool_call| {
                const tool_name = tool_call.function.?.name;
                logger.info("agent", "Executing tool: {s}", .{tool_name});

                // TODO: Parse arguments and execute tool
                // const args = try parseToolArgs(tool_call.function.?.arguments);
                // const result = try self.tools_registry.execute(tool_name, args, self.allocator);

                // Add tool result to messages
                // try messages.append(.{
                //     .role = try self.allocator.dupe(u8, "tool"),
                //     .content = result,
                //     .tool_calls = &[_]providers.ToolCall{},
                //     .tool_call_id = try self.allocator.dupe(u8, tool_call.id),
                // });
            }
        }

        // Save to session
        try self.sessions.addMessage(msg.session_key, .{
            .role = try self.allocator.dupe(u8, "user"),
            .content = try self.allocator.dupe(u8, msg.content),
            .tool_calls = &[_]providers.ToolCall{},
            .tool_call_id = null,
        });

        try self.sessions.addMessage(msg.session_key, .{
            .role = try self.allocator.dupe(u8, "assistant"),
            .content = try self.allocator.dupe(u8, final_content),
            .tool_calls = &[_]providers.ToolCall{},
            .tool_call_id = null,
        });

        return final_content;
    }
};
