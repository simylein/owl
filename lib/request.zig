const std = @import("std");
const logger = @import("logger.zig");
const utils = @import("utils.zig");

pub const Request = struct {
    method: []u8,
    pathname: []u8,
    search: []u8,
    protocol: []u8,

    pub fn deinit(self: Request) void {
        std.heap.c_allocator.free(self.method);
        std.heap.c_allocator.free(self.pathname);
        std.heap.c_allocator.free(self.search);
        std.heap.c_allocator.free(self.protocol);
    }
};

pub fn parse(connection: std.net.Server.Connection) !Request {
    var buffer: [255]u8 = undefined;
    const read = try connection.stream.read(&buffer);
    logger.debug("read {d} bytes from {}", .{ read, connection.address });

    var index: u8 = 0;
    while (index < read) : (index += 1) {
        const byte = buffer[index];
        if (byte >= 'A' and byte <= 'Z') {
            buffer[index] += 32;
        }
    }

    var iterator = utils.Iterator.init(buffer[0..read]);

    var method_index: u3 = 0;
    var pathname_index: u6 = 0;
    var search_index: u7 = 0;
    var protocol_index: u4 = 0;

    var stage: u3 = 0;

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
    const method = try std.heap.c_allocator.alloc(u8, method_index);
    errdefer std.heap.c_allocator.free(method);
    std.mem.copyForwards(u8, method, try iterator.slice(method_index));

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
    const pathname = try std.heap.c_allocator.alloc(u8, pathname_index);
    errdefer std.heap.c_allocator.free(pathname);
    std.mem.copyForwards(u8, pathname, try iterator.slice(pathname_index));

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
    const search = try std.heap.c_allocator.alloc(u8, search_index);
    errdefer std.heap.c_allocator.free(search);
    std.mem.copyForwards(u8, search, try iterator.slice(search_index));

    while (stage == 3 and protocol_index < std.math.maxInt(@TypeOf(protocol_index))) : (protocol_index += 1) {
        const byte = iterator.next() orelse return error.HTTPVersionNotSupported;
        if (byte == '\n') {
            stage = 4;
            break;
        }
    }
    const protocol = try std.heap.c_allocator.alloc(u8, protocol_index);
    errdefer std.heap.c_allocator.free(protocol);
    std.mem.copyForwards(u8, protocol, try iterator.slice(protocol_index));

    if (stage != 4) {
        return error.BadRequest;
    }

    return .{ .method = method, .pathname = pathname, .search = search, .protocol = protocol };
}
