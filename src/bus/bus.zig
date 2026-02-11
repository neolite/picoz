const std = @import("std");

/// Inbound message from channels
pub const InboundMessage = struct {
    channel: []const u8,
    sender_id: []const u8,
    chat_id: []const u8,
    content: []const u8,
    session_key: []const u8,

    pub fn deinit(self: *InboundMessage, allocator: std.mem.Allocator) void {
        allocator.free(self.channel);
        allocator.free(self.sender_id);
        allocator.free(self.chat_id);
        allocator.free(self.content);
        allocator.free(self.session_key);
    }
};

/// Outbound message to channels
pub const OutboundMessage = struct {
    channel: []const u8,
    chat_id: []const u8,
    content: []const u8,

    pub fn deinit(self: *OutboundMessage, allocator: std.mem.Allocator) void {
        allocator.free(self.channel);
        allocator.free(self.chat_id);
        allocator.free(self.content);
    }
};

/// Message bus for inbound/outbound communication
pub const MessageBus = struct {
    const Self = @This();

    inbound: std.ArrayList(InboundMessage),
    outbound: std.ArrayList(OutboundMessage),
    mutex: std.Thread.Mutex,
    cond_inbound: std.Thread.Condition,
    cond_outbound: std.Thread.Condition,
    allocator: std.mem.Allocator,

    /// Initialize message bus
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = Self{
            .inbound = std.ArrayList(InboundMessage).init(allocator),
            .outbound = std.ArrayList(OutboundMessage).init(allocator),
            .mutex = .{},
            .cond_inbound = .{},
            .cond_outbound = .{},
            .allocator = allocator,
        };
        return self;
    }

    /// Clean up message bus
    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.inbound.items) |*msg| {
            msg.deinit(self.allocator);
        }
        self.inbound.deinit();

        for (self.outbound.items) |*msg| {
            msg.deinit(self.allocator);
        }
        self.outbound.deinit();

        self.allocator.destroy(self);
    }

    /// Publish inbound message
    pub fn publishInbound(self: *Self, message: InboundMessage) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        try self.inbound.append(message);
        self.cond_inbound.signal();
    }

    /// Consume inbound message (blocking)
    pub fn consumeInbound(self: *Self) ?InboundMessage {
        self.mutex.lock();
        defer self.mutex.unlock();

        while (self.inbound.items.len == 0) {
            self.cond_inbound.wait(&self.mutex);
        }

        return self.inbound.orderedRemove(0);
    }

    /// Try consume inbound message (non-blocking)
    pub fn tryConsumeInbound(self: *Self) ?InboundMessage {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.inbound.items.len == 0) {
            return null;
        }

        return self.inbound.orderedRemove(0);
    }

    /// Publish outbound message
    pub fn publishOutbound(self: *Self, message: OutboundMessage) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        try self.outbound.append(message);
        self.cond_outbound.signal();
    }

    /// Consume outbound message (blocking)
    pub fn consumeOutbound(self: *Self) ?OutboundMessage {
        self.mutex.lock();
        defer self.mutex.unlock();

        while (self.outbound.items.len == 0) {
            self.cond_outbound.wait(&self.mutex);
        }

        return self.outbound.orderedRemove(0);
    }

    /// Try consume outbound message (non-blocking)
    pub fn tryConsumeOutbound(self: *Self) ?OutboundMessage {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.outbound.items.len == 0) {
            return null;
        }

        return self.outbound.orderedRemove(0);
    }
};

test "message bus" {
    const allocator = std.testing.allocator;

    const bus = try MessageBus.init(allocator);
    defer bus.deinit();

    // Test inbound
    const msg = InboundMessage{
        .channel = try allocator.dupe(u8, "test"),
        .sender_id = try allocator.dupe(u8, "user1"),
        .chat_id = try allocator.dupe(u8, "chat1"),
        .content = try allocator.dupe(u8, "Hello"),
        .session_key = try allocator.dupe(u8, "session1"),
    };

    try bus.publishInbound(msg);

    const received = bus.tryConsumeInbound();
    try std.testing.expect(received != null);
    if (received) |r| {
        try std.testing.expectEqualStrings("Hello", r.content);
        var mutable_r = r;
        mutable_r.deinit(allocator);
    }
}
