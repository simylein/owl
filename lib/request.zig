const std = @import("std");
const logger = @import("logger.zig");
const utils = @import("utils.zig");

pub const Request = struct {
    buffer: []const u8,
    method: []const u8,
    pathname: []const u8,
    search: []const u8,
    protocol: []const u8,
    header: []const u8,

    pub fn deinit(self: Request) void {
        std.heap.c_allocator.free(self.buffer);
    }
};

pub fn parse(connection: *const std.net.Server.Connection) !Request {
    const buffer = try std.heap.c_allocator.alloc(u8, 1240);
    const read = try connection.stream.read(buffer);
    logger.debug("read {d} bytes from {}", .{ read, connection.address });

    var stage: u4 = 0;
    var iterator = utils.Iterator.init(buffer[0..read]);

    var method_index: u3 = 0;
    while (stage == 0 and method_index < std.math.maxInt(@TypeOf(method_index))) : (method_index += 1) {
        const byte = iterator.next() orelse break;
        if (byte >= 'A' and byte <= 'Z') {
            buffer[iterator.index - 1] += 32;
        }
        if (byte == ' ') {
            stage = 1;
        }
    }
    const method = try iterator.slice(method_index, 1);
    if (stage == 0 or !std.mem.eql(u8, method, "get")) {
        return error.NotImplemented;
    }

    var pathname_index: u6 = 0;
    while (stage == 1 and pathname_index < std.math.maxInt(@TypeOf(pathname_index))) : (pathname_index += 1) {
        const byte = iterator.next() orelse break;
        if (byte == '?') {
            stage = 2;
        }
        if (byte == ' ') {
            stage = 3;
        }
    }
    const pathname = try iterator.slice(pathname_index, 1);
    if (stage == 1) {
        return error.URITooLong;
    }

    var search_index: u7 = 0;
    while (stage == 2 and search_index < std.math.maxInt(@TypeOf(search_index))) : (search_index += 1) {
        const byte = iterator.next() orelse break;
        if (byte == ' ') {
            stage = 3;
        }
    }
    const search = try iterator.slice(search_index, 1);
    if (stage == 2) {
        return error.URITooLong;
    }

    var protocol_index: u4 = 0;
    while ((stage == 3 or stage == 4) and protocol_index < std.math.maxInt(@TypeOf(protocol_index))) : (protocol_index += 1) {
        const byte = iterator.next() orelse break;
        if (byte >= 'A' and byte <= 'Z') {
            buffer[iterator.index - 1] += 32;
        }
        if (byte == '\r') {
            stage = 4;
        }
        if (byte == '\n') {
            stage = 5;
        }
    }
    const protocol = try iterator.slice(protocol_index, 2);
    if (stage == 3) {
        return error.HTTPVersionNotSupported;
    }
    if (stage == 4) {
        return error.BadRequest;
    }

    var key = true;
    var header_index: u10 = 0;
    while ((stage >= 5 and stage <= 9) and header_index < std.math.maxInt(@TypeOf(header_index))) : (header_index += 1) {
        const byte = iterator.next() orelse break;
        if (key and byte >= 'A' and byte <= 'Z') {
            buffer[iterator.index - 1] += 32;
        }
        if (byte == ':') {
            key = false;
        }
        if (byte == '\r' or byte == '\n') {
            key = true;
            stage += 1;
        } else {
            stage = 5;
        }
    }
    const header = try iterator.slice(header_index, 4);
    if (stage >= 5 and stage <= 7) {
        return error.RequestHeaderFieldsTooLarge;
    }
    if (stage != 9) {
        return error.BadRequest;
    }

    return .{ .buffer = buffer, .method = method, .pathname = pathname, .search = search, .protocol = protocol, .header = header };
}
