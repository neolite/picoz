const std = @import("std");

// Placeholder for cron service
pub const CronService = struct {
    pub fn init(allocator: std.mem.Allocator) !*CronService {
        _ = allocator;
        return error.NotImplemented;
    }
};
