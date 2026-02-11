const std = @import("std");
const json = std.json;

/// Main configuration structure
pub const Config = struct {
    agents: AgentsConfig,
    channels: ChannelsConfig,
    providers: ProvidersConfig,
    gateway: GatewayConfig,
    tools: ToolsConfig,

    pub fn deinit(self: *const Config, allocator: std.mem.Allocator) void {
        // Free allocated strings
        allocator.free(self.agents.defaults.workspace);
        allocator.free(self.agents.defaults.model);
        allocator.free(self.gateway.host);

        // Free provider strings
        if (self.providers.anthropic.api_key) |key| allocator.free(key);
        if (self.providers.anthropic.api_base) |base| allocator.free(base);
        if (self.providers.openai.api_key) |key| allocator.free(key);
        if (self.providers.openai.api_base) |base| allocator.free(base);
        if (self.providers.openrouter.api_key) |key| allocator.free(key);
        if (self.providers.openrouter.api_base) |base| allocator.free(base);
        if (self.providers.groq.api_key) |key| allocator.free(key);
        if (self.providers.groq.api_base) |base| allocator.free(base);
        if (self.providers.zhipu.api_key) |key| allocator.free(key);
        if (self.providers.zhipu.api_base) |base| allocator.free(base);
        if (self.providers.gemini.api_key) |key| allocator.free(key);
        if (self.providers.gemini.api_base) |base| allocator.free(base);

        // Free web search API key
        if (self.tools.web.search.api_key) |key| allocator.free(key);
    }
};

pub const AgentsConfig = struct {
    defaults: AgentDefaults,
};

pub const AgentDefaults = struct {
    workspace: []const u8,
    model: []const u8,
    max_tokens: i32,
    temperature: f64,
    max_tool_iterations: i32,
};

pub const ChannelsConfig = struct {
    telegram: TelegramConfig,
    discord: DiscordConfig,
    whatsapp: WhatsAppConfig,
    feishu: FeishuConfig,
    maixcam: MaixCamConfig,
};

pub const TelegramConfig = struct {
    enabled: bool,
    token: ?[]const u8,
    allow_from: [][]const u8,
};

pub const DiscordConfig = struct {
    enabled: bool,
    token: ?[]const u8,
    allow_from: [][]const u8,
};

pub const WhatsAppConfig = struct {
    enabled: bool,
    bridge_url: ?[]const u8,
    allow_from: [][]const u8,
};

pub const FeishuConfig = struct {
    enabled: bool,
    app_id: ?[]const u8,
    app_secret: ?[]const u8,
    encrypt_key: ?[]const u8,
    verification_token: ?[]const u8,
    allow_from: [][]const u8,
};

pub const MaixCamConfig = struct {
    enabled: bool,
    host: ?[]const u8,
    port: i32,
    allow_from: [][]const u8,
};

pub const ProvidersConfig = struct {
    anthropic: ProviderConfig,
    openai: ProviderConfig,
    openrouter: ProviderConfig,
    groq: ProviderConfig,
    zhipu: ProviderConfig,
    vllm: ProviderConfig,
    gemini: ProviderConfig,
};

pub const ProviderConfig = struct {
    api_key: ?[]const u8,
    api_base: ?[]const u8,
};

pub const GatewayConfig = struct {
    host: []const u8,
    port: i32,
};

pub const ToolsConfig = struct {
    web: WebToolsConfig,
};

pub const WebToolsConfig = struct {
    search: WebSearchConfig,
};

pub const WebSearchConfig = struct {
    api_key: ?[]const u8,
    max_results: i32,
};

/// Create default configuration
pub fn defaultConfig() Config {
    return Config{
        .agents = AgentsConfig{
            .defaults = AgentDefaults{
                .workspace = "~/.picoz/workspace",
                .model = "glm-4.7",
                .max_tokens = 8192,
                .temperature = 0.7,
                .max_tool_iterations = 20,
            },
        },
        .channels = ChannelsConfig{
            .telegram = TelegramConfig{
                .enabled = false,
                .token = null,
                .allow_from = &[_][]const u8{},
            },
            .discord = DiscordConfig{
                .enabled = false,
                .token = null,
                .allow_from = &[_][]const u8{},
            },
            .whatsapp = WhatsAppConfig{
                .enabled = false,
                .bridge_url = null,
                .allow_from = &[_][]const u8{},
            },
            .feishu = FeishuConfig{
                .enabled = false,
                .app_id = null,
                .app_secret = null,
                .encrypt_key = null,
                .verification_token = null,
                .allow_from = &[_][]const u8{},
            },
            .maixcam = MaixCamConfig{
                .enabled = false,
                .host = null,
                .port = 18790,
                .allow_from = &[_][]const u8{},
            },
        },
        .providers = ProvidersConfig{
            .anthropic = ProviderConfig{ .api_key = null, .api_base = null },
            .openai = ProviderConfig{ .api_key = null, .api_base = null },
            .openrouter = ProviderConfig{ .api_key = null, .api_base = null },
            .groq = ProviderConfig{ .api_key = null, .api_base = null },
            .zhipu = ProviderConfig{ .api_key = null, .api_base = null },
            .vllm = ProviderConfig{ .api_key = null, .api_base = null },
            .gemini = ProviderConfig{ .api_key = null, .api_base = null },
        },
        .gateway = GatewayConfig{
            .host = "0.0.0.0",
            .port = 3000,
        },
        .tools = ToolsConfig{
            .web = WebToolsConfig{
                .search = WebSearchConfig{
                    .api_key = null,
                    .max_results = 5,
                },
            },
        },
    };
}

/// Get config file path (~/.picoz/config.json)
pub fn getConfigPath(allocator: std.mem.Allocator) ![]u8 {
    const home = std.posix.getenv("HOME") orelse return error.NoHomeDir;
    return std.fmt.allocPrint(allocator, "{s}/.picoz/config.json", .{home});
}

/// Get workspace path from config or default
pub fn getWorkspacePath(allocator: std.mem.Allocator) ![]u8 {
    const home = std.posix.getenv("HOME") orelse return error.NoHomeDir;
    return std.fmt.allocPrint(allocator, "{s}/.picoz/workspace", .{home});
}

/// Load configuration from file
pub fn loadConfig(allocator: std.mem.Allocator) !Config {
    _ = allocator;
    // For now, return default config
    // TODO: Implement JSON parsing when API stabilizes
    return defaultConfig();
}

/// Save configuration to file
pub fn saveConfig(path: []const u8, cfg: Config, allocator: std.mem.Allocator) !void {
    _ = cfg;
    _ = allocator;

    // Ensure directory exists
    const dir_path = std.fs.path.dirname(path) orelse return error.InvalidPath;
    try std.fs.makeDirAbsolute(dir_path);

    const file = try std.fs.createFileAbsolute(path, .{});
    defer file.close();

    // Write minimal JSON config
    const minimal_config =
        \\{
        \\  "agents": {
        \\    "defaults": {
        \\      "workspace": "~/.picoz/workspace",
        \\      "model": "glm-4.7",
        \\      "max_tokens": 8192,
        \\      "temperature": 0.7,
        \\      "max_tool_iterations": 20
        \\    }
        \\  },
        \\  "providers": {
        \\    "zhipu": {
        \\      "api_key": "YOUR_API_KEY_HERE",
        \\      "api_base": "https://open.bigmodel.cn/api/paas/v4"
        \\    }
        \\  },
        \\  "gateway": {
        \\    "host": "0.0.0.0",
        \\    "port": 3000
        \\  }
        \\}
    ;

    try file.writeAll(minimal_config);
}

/// Deep copy a config struct
fn deepCopy(comptime T: type, value: T, allocator: std.mem.Allocator) !T {
    // For now, return as-is since Config has const strings
    // In production, would need to allocate and copy all strings
    _ = allocator;
    return value;
}

test "default config" {
    const cfg = defaultConfig();
    try std.testing.expectEqualStrings("glm-4.7", cfg.agents.defaults.model);
    try std.testing.expectEqual(@as(i32, 8192), cfg.agents.defaults.max_tokens);
}
