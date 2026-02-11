const std = @import("std");

// Placeholder for heartbeat service
pub const HeartbeatService = struct {
    pub fn init(allocator: std.mem.Allocator) !*HeartbeatService {
        _ = allocator;
        return error.NotImplemented;
    }
};
