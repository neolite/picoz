const std = @import("std");

// Placeholder for voice transcriber
pub const VoiceTranscriber = struct {
    pub fn init(allocator: std.mem.Allocator) !*VoiceTranscriber {
        _ = allocator;
        return error.NotImplemented;
    }
};
