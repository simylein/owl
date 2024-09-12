const std = @import("std");
const config = @import("config.zig");
const database = @import("database.zig");

pub const Day = struct {
    timestamp: u64,
    healthy: u16,
    unhealthy: u16,
};

pub const Uptime = struct {
    app: config.App,
    days: [96]Day,
};

pub fn calculate(apps: std.ArrayList(config.App), data: *database.Data) !std.ArrayList(Uptime) {
    var uptimes = std.ArrayList(Uptime).init(std.heap.c_allocator);

    for (apps.items) |app| {
        var days: [96]Day = undefined;
        var index: u7 = 0;
        while (index < days.len) : (index += 1) {
            days[index] = Day{ .timestamp = std.math.maxInt(u64), .healthy = 0, .unhealthy = 0 };
        }
        try uptimes.append(.{ .app = app, .days = days });
    }

    for (data.statuses.items) |status| {
        const day: u7 = 0; // TODO: figure out index from timestamp
        if (uptimes.items[status.app_id].days[day].timestamp > status.timestamp) {
            uptimes.items[status.app_id].days[day].timestamp = status.timestamp;
        }
        if (status.healthy) {
            uptimes.items[status.app_id].days[day].healthy += 1;
        } else {
            uptimes.items[status.app_id].days[day].unhealthy += 1;
        }
    }

    return uptimes;
}
