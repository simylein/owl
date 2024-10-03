const std = @import("std");
const logger = @import("logger.zig");
const utils = @import("utils.zig");

pub const Request = struct {
    buffer: []const u8,
    method: []const u8,
    pathname: []const u8,
    search: []const u8,
    protocol: []const u8,

    pub fn deinit(self: Request) void {
        std.heap.c_allocator.free(self.buffer);
    }
};

pub fn parse(connection: *const std.net.Server.Connection) !Request {
    const buffer = try std.heap.c_allocator.alloc(u8, 255);
    const read = try connection.stream.read(buffer);
    logger.debug("read {d} bytes from {}", .{ read, connection.address });

    var index: u8 = 0;
    while (index < read) : (index += 1) {
        const byte = buffer[index];
        if (byte >= 'A' and byte <= 'Z') {
            buffer[index] += 32;
        }
    }

    var stage: u3 = 0;
    var iterator = utils.Iterator.init(buffer[0..read]);

    var method_index: u3 = 0;
    while (stage == 0 and method_index < std.math.maxInt(@TypeOf(method_index))) : (method_index += 1) {
        const byte = iterator.next() orelse return error.NotImplemented;
        if (byte == ' ') {
            stage = 1;
            break;
        }
        if (byte == '\n') {
            stage = 4;
            break;
        }
    }
    const method = try iterator.slice(method_index);

    var pathname_index: u6 = 0;
    while (stage == 1 and pathname_index < std.math.maxInt(@TypeOf(pathname_index))) : (pathname_index += 1) {
        const byte = iterator.next() orelse return error.URITooLong;
        if (byte == '?') {
            stage = 2;
            break;
        }
        if (byte == ' ') {
            stage = 3;
            break;
        }
        if (byte == '\n') {
            stage = 4;
            break;
        }
    }
    const pathname = try iterator.slice(pathname_index);

    var search_index: u7 = 0;
    while (stage == 2 and search_index < std.math.maxInt(@TypeOf(search_index))) : (search_index += 1) {
        const byte = iterator.next() orelse return error.URITooLong;
        if (byte == ' ') {
            stage = 3;
            break;
        }
        if (byte == '\n') {
            stage = 4;
            break;
        }
    }
    const search = try iterator.slice(search_index);

    var protocol_index: u4 = 0;
    while (stage == 3 and protocol_index < std.math.maxInt(@TypeOf(protocol_index))) : (protocol_index += 1) {
        const byte = iterator.next() orelse return error.HTTPVersionNotSupported;
        if (byte == '\n') {
            stage = 4;
            break;
        }
    }
    const protocol = try iterator.slice(protocol_index);

    if (stage != 4) {
        return error.BadRequest;
    }

    return .{ .buffer = buffer, .method = method, .pathname = pathname, .search = search, .protocol = protocol };
}
