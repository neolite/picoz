// PicoZ - Ultra-lightweight personal AI assistant in Zig
// Ported from PicoClaw (https://github.com/sipeed/picoclaw)
// License: MIT

const std = @import("std");
const config = @import("config/config.zig");
const logger = @import("logger/logger.zig");
const agent = @import("agent/loop.zig");
const bus = @import("bus/bus.zig");
const providers = @import("providers/provider.zig");
const channels = @import("channels/manager.zig");

const VERSION = "0.1.0";
const LOGO = "🦞";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printHelp();
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "onboard")) {
        try onboard(allocator);
    } else if (std.mem.eql(u8, command, "agent")) {
        try agentCmd(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "gateway")) {
        try gatewayCmd(allocator);
    } else if (std.mem.eql(u8, command, "status")) {
        try statusCmd(allocator);
    } else if (std.mem.eql(u8, command, "version") or
        std.mem.eql(u8, command, "--version") or
        std.mem.eql(u8, command, "-v"))
    {
        std.debug.print("{s} picoz v{s}\n", .{ LOGO, VERSION });
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        printHelp();
        std.process.exit(1);
    }
}

fn printHelp() void {
    std.debug.print("{s} picoz - Personal AI Assistant v{s}\n\n", .{ LOGO, VERSION });
    std.debug.print("Usage: picoz <command>\n\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  onboard     Initialize picoz configuration and workspace\n", .{});
    std.debug.print("  agent       Interact with the agent directly\n", .{});
    std.debug.print("  gateway     Start picoz gateway\n", .{});
    std.debug.print("  status      Show picoz status\n", .{});
    std.debug.print("  version     Show version information\n", .{});
}

fn onboard(allocator: std.mem.Allocator) !void {
    const config_path = try config.getConfigPath(allocator);
    defer allocator.free(config_path);

    // Check if config exists
    if (std.fs.accessAbsolute(config_path, .{})) |_| {
        std.debug.print("Config already exists at {s}\n", .{config_path});
        std.debug.print("Use --force to overwrite.\n", .{});
        return;
        // TODO: Add interactive confirmation when stdin API is fixed
    } else |_| {}

    const cfg = config.defaultConfig();
    try config.saveConfig(config_path, cfg, allocator);

    const workspace = try config.getWorkspacePath(allocator);
    defer allocator.free(workspace);

    // Create workspace directories
    try std.fs.makeDirAbsolute(workspace);

    var workspace_dir = try std.fs.openDirAbsolute(workspace, .{});
    defer workspace_dir.close();

    try workspace_dir.makeDir("memory");
    try workspace_dir.makeDir("skills");

    std.debug.print("{s} picoz is ready!\n", .{LOGO});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  1. Add your API key to {s}\n", .{config_path});
    std.debug.print("     Get one at: https://openrouter.ai/keys\n", .{});
    std.debug.print("  2. Chat: picoz agent -m \"Hello!\"\n", .{});
}

fn agentCmd(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var message: ?[]const u8 = null;
    var session_key: []const u8 = "cli:default";

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "-m") or std.mem.eql(u8, args[i], "--message")) {
            if (i + 1 < args.len) {
                message = args[i + 1];
                i += 1;
            }
        } else if (std.mem.eql(u8, args[i], "-s") or std.mem.eql(u8, args[i], "--session")) {
            if (i + 1 < args.len) {
                session_key = args[i + 1];
                i += 1;
            }
        }
    }

    const cfg = try config.loadConfig(allocator);
    defer cfg.deinit(allocator);

    // TODO: Initialize provider, message bus, agent loop
    // const provider = try providers.createProvider(cfg, allocator);
    // const msg_bus = try bus.MessageBus.init(allocator);
    // const agent_loop = try agent.AgentLoop.init(cfg, msg_bus, provider, allocator);

    if (message) |msg| {
        // Process single message
        std.debug.print("\n{s} Processing: {s}\n", .{ LOGO, msg });
        // TODO: const response = try agent_loop.processDirect(msg, session_key);
        // std.debug.print("\n{s} {s}\n", .{ LOGO, response });
    } else {
        // Interactive mode
        std.debug.print("{s} Interactive mode (Ctrl+C to exit)\n\n", .{LOGO});
        // TODO: interactiveMode(agent_loop, session_key);
    }
}

fn gatewayCmd(allocator: std.mem.Allocator) !void {
    const cfg = try config.loadConfig(allocator);
    defer cfg.deinit(allocator);

    std.debug.print("✓ Gateway started on {s}:{d}\n", .{ cfg.gateway.host, cfg.gateway.port });
    std.debug.print("Press Ctrl+C to stop\n", .{});

    // TODO: Initialize all services
    // - Provider
    // - Message bus
    // - Agent loop
    // - Channel manager
    // - Cron service
    // - Heartbeat service

    // TODO: Start all services and wait for interrupt
}

fn statusCmd(allocator: std.mem.Allocator) !void {
    const config_path = try config.getConfigPath(allocator);
    defer allocator.free(config_path);

    std.debug.print("{s} picoz Status\n\n", .{LOGO});

    if (std.fs.accessAbsolute(config_path, .{})) |_| {
        std.debug.print("Config: {s} ✓\n", .{config_path});
    } else |_| {
        std.debug.print("Config: {s} ✗\n", .{config_path});
        return;
    }

    const cfg = try config.loadConfig(allocator);
    defer cfg.deinit(allocator);

    const workspace = try config.getWorkspacePath(allocator);
    defer allocator.free(workspace);

    if (std.fs.accessAbsolute(workspace, .{})) |_| {
        std.debug.print("Workspace: {s} ✓\n", .{workspace});
    } else |_| {
        std.debug.print("Workspace: {s} ✗\n", .{workspace});
    }

    std.debug.print("Model: {s}\n", .{cfg.agents.defaults.model});
}
