const std = @import("std");
const Message = @import("../providers/types.zig").Message;

/// Session data for a conversation
pub const Session = struct {
    key: []const u8,
    history: std.ArrayList(Message),
    summary: ?[]const u8,

    pub fn deinit(self: *Session, allocator: std.mem.Allocator) void {
        allocator.free(self.key);
        for (self.history.items) |*msg| {
            msg.deinit(allocator);
        }
        self.history.deinit();
        if (self.summary) |summary| {
            allocator.free(summary);
        }
    }
};

/// Session manager for handling conversation history
pub const SessionManager = struct {
    const Self = @This();

    sessions: std.StringHashMap(Session),
    mutex: std.Thread.Mutex,
    storage_path: []const u8,
    allocator: std.mem.Allocator,

    /// Initialize session manager
    pub fn init(storage_path: []const u8, allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .sessions = std.StringHashMap(Session).init(allocator),
            .mutex = .{},
            .storage_path = try allocator.dupe(u8, storage_path),
            .allocator = allocator,
        };

        // Create storage directory
        std.fs.makeDirAbsolute(storage_path) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        return self;
    }

    /// Clean up session manager
    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        var iter = self.sessions.valueIterator();
        while (iter.next()) |session| {
            session.deinit(self.allocator);
        }
        self.sessions.deinit();
        self.allocator.free(self.storage_path);
        self.allocator.destroy(self);
    }

    /// Get or create session
    fn getOrCreateSession(self: *Self, key: []const u8) !*Session {
        const entry = try self.sessions.getOrPut(key);
        if (!entry.found_existing) {
            entry.value_ptr.* = Session{
                .key = try self.allocator.dupe(u8, key),
                .history = std.ArrayList(Message).init(self.allocator),
                .summary = null,
            };
        }
        return entry.value_ptr;
    }

    /// Get conversation history for a session
    pub fn getHistory(self: *Self, key: []const u8) []const Message {
        self.mutex.lock();
        defer self.mutex.unlock();

        const session = self.getOrCreateSession(key) catch return &[_]Message{};
        return session.history.items;
    }

    /// Get summary for a session
    pub fn getSummary(self: *Self, key: []const u8) ?[]const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();

        const session = self.getOrCreateSession(key) catch return null;
        return session.summary;
    }

    /// Add message to session history
    pub fn addMessage(self: *Self, key: []const u8, message: Message) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const session = try self.getOrCreateSession(key);
        try session.history.append(message);
    }

    /// Update session summary
    pub fn updateSummary(self: *Self, key: []const u8, summary: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const session = try self.getOrCreateSession(key);
        if (session.summary) |old_summary| {
            self.allocator.free(old_summary);
        }
        session.summary = try self.allocator.dupe(u8, summary);
    }

    /// Clear session
    pub fn clearSession(self: *Self, key: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.sessions.fetchRemove(key)) |entry| {
            var session = entry.value;
            session.deinit(self.allocator);
        }
    }
};

test "session manager" {
    const allocator = std.testing.allocator;
    const manager = try SessionManager.init("/tmp/test-sessions", allocator);
    defer manager.deinit();

    const history = manager.getHistory("test-session");
    try std.testing.expectEqual(@as(usize, 0), history.len);
}
