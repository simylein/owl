const std = @import("std");

pub const Response = struct {
    buffer: []const u8,
    status: u9,
    content: []const u8,

    pub fn deinit(self: Response) void {
        std.heap.c_allocator.free(self.buffer);
    }
};
