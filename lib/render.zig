const std = @import("std");
const database = @import("database.zig");
const updraft = @import("updraft.zig");
const utils = @import("utils.zig");

pub fn head(status: u9, content: []const u8, length: usize) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    const text = switch (status) {
        200 => "OK",
        404 => "Not Found",
        else => return error.UnknownStatus,
    };

    const status_line = try utils.format("HTTP/1.1 {d} {s}\r\n", .{ status, text });
    defer std.heap.c_allocator.free(status_line);
    try buffer.appendSlice(status_line);
    const content_type = try utils.format("content-type:{s}\r\n", .{content});
    defer std.heap.c_allocator.free(content_type);
    try buffer.appendSlice(content_type);
    const content_length = try utils.format("content-length:{d}\r\n", .{length});
    defer std.heap.c_allocator.free(content_length);
    try buffer.appendSlice(content_length);
    try buffer.appendSlice("\r\n");

    return buffer.toOwnedSlice();
}

pub fn home(data: *const database.Data) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("<!doctype html>");
    try buffer.appendSlice("<html lang=\"en\">");

    try buffer.appendSlice("<head>");
    try buffer.appendSlice("<meta charset=\"utf-8\">");
    try buffer.appendSlice("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0\">");
    try buffer.appendSlice("<meta name=\"description\" content=\"historical uptime for apps with telemetry\">");
    try buffer.appendSlice("<title>owl uptime</title>");

    try updraft.style(&buffer);

    try buffer.appendSlice("</head>");

    try buffer.appendSlice("<body class=\"m-0 black dark:white bg-neutral-100 dark:bg-neutral-900\">");
    try buffer.appendSlice("<main class=\"flex gap-4 sm:gap-8 flex-col mx-4 my-6 sm:mx-8 sm:my-9 md:mx-16 md:my-12\">");
    try overview(data, &buffer);
    try buffer.appendSlice("<div class=\"flex gap-2 sm:gap-4 flex-col\">");
    for (data.apps.items) |app| {
        try container(app, &buffer);
    }
    try buffer.appendSlice("</div>");
    try buffer.appendSlice("</main>");
    try buffer.appendSlice("</body>");

    try buffer.appendSlice("</html>");

    return buffer.toOwnedSlice();
}

pub fn robots() ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("User-agent:*\n");
    try buffer.appendSlice("Allow:*\n");

    return buffer.toOwnedSlice();
}

pub fn notFound() ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("<!doctype html>");
    try buffer.appendSlice("<html lang=\"en\">");

    try buffer.appendSlice("<head>");
    try buffer.appendSlice("<meta charset=\"utf-8\">");
    try buffer.appendSlice("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0\">");
    try buffer.appendSlice("<meta name=\"description\" content=\"we could not find the page you were looking for\">");
    try buffer.appendSlice("<title>404 Not Found</title>");

    try buffer.appendSlice("<style>");

    try buffer.appendSlice("body{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale;font-family:-apple-system,BlinkMacSystemFont,Helvetica,Arial,Roboto,Oxygen,sans-serif}");
    try buffer.appendSlice(".min-h-dvh{min-height:100dvh}");
    try buffer.appendSlice(".flex{display:flex}");
    try buffer.appendSlice(".flex-col{flex-direction:column}");
    try buffer.appendSlice(".items-center{align-items:center}");
    try buffer.appendSlice(".justify-center{justify-content:center}");
    try buffer.appendSlice(".m-0{margin:0}");
    try buffer.appendSlice(".m-4{margin:16px}");
    try buffer.appendSlice(".mb-2{margin-bottom:8px}");
    try buffer.appendSlice(".p-4{padding:16px}");
    try buffer.appendSlice(".rounded{border-radius:4px}");
    try buffer.appendSlice(".text-base{font-size:16px}");
    try buffer.appendSlice(".text-2xl{font-size:24px}");
    try buffer.appendSlice(".font-normal{font-weight:400}");
    try buffer.appendSlice(".font-bold{font-weight:700}");
    try buffer.appendSlice(".no-underline{text-decoration-line:none}");
    try buffer.appendSlice(".black{color:#000}");
    try buffer.appendSlice(".blue-600{color:#2563eb}");
    try buffer.appendSlice(".bg-white{background-color:#fff}");
    try buffer.appendSlice(".bg-neutral-100{background-color:#f5f5f5}");

    try buffer.appendSlice("@media(min-width:512px){");
    try buffer.appendSlice(".sm\\:m-16{margin:64px}");
    try buffer.appendSlice(".sm\\:mb-4{margin-bottom:16px}");
    try buffer.appendSlice(".sm\\:mb-3{margin-bottom:12px}");
    try buffer.appendSlice(".sm\\:p-8{padding:32px}");
    try buffer.appendSlice(".sm\\:text-3xl{font-size:30px}");
    try buffer.appendSlice("}");

    try buffer.appendSlice("@media(prefers-color-scheme:dark){");
    try buffer.appendSlice(".dark\\:white{color:#fff}");
    try buffer.appendSlice(".dark\\:blue-400{color:#60a5fa}");
    try buffer.appendSlice(".dark\\:bg-black{background-color:#000}");
    try buffer.appendSlice(".dark\\:bg-neutral-900{background-color:#171717}");
    try buffer.appendSlice("}");

    try buffer.appendSlice("</style>");

    try buffer.appendSlice("</head>");

    try buffer.appendSlice("<body class=\"min-h-dvh flex flex-col items-center justify-center m-0 black dark:white bg-neutral-100 dark:bg-neutral-900\">");
    try buffer.appendSlice("<main class=\"m-4 sm:m-16 p-4 sm:p-8 rounded bg-white dark:bg-black\">");

    try buffer.appendSlice("<h1 class=\"m-0 mb-2 sm:mb-4 text-2xl sm:text-3xl font-bold\">404 - Not Found</h1>");
    try buffer.appendSlice("<p class=\"m-0 mb-2 sm:mb-3\">We could not find the page you were looking for.</p>");
    try buffer.appendSlice("<a href=\"/\" class=\"no-underline text-base font-normal blue-600 dark:blue-400\">Take me home</a>");

    try buffer.appendSlice("</main>");
    try buffer.appendSlice("</body>");

    try buffer.appendSlice("</html>");

    return buffer.toOwnedSlice();
}

fn overview(data: *const database.Data, buffer: *std.ArrayList(u8)) !void {
    var unknown: u8 = 0;
    var offline: u8 = 0;
    var online: u8 = 0;

    for (data.apps.items) |app| {
        switch (app.latest.healthyness) {
            0 => unknown += 1,
            1 => offline += 1,
            2 => offline += 1,
            3 => offline += 1,
            4 => online += 1,
            else => break,
        }
    }

    const color = try colorizeOverview(unknown, offline, online, data.apps.items.len);
    defer std.heap.c_allocator.free(color);

    const header = try utils.format("<div class=\"p-4 rounded white dark:neutral-100 {s}\">", .{color});
    defer std.heap.c_allocator.free(header);

    const message = try contextualizeOverview(unknown, offline, online, data.apps.items.len);
    defer std.heap.c_allocator.free(message);

    const text = try utils.format("<h1 class=\"m-0 text-xl font-bold\">{s}</h1>", .{message});
    defer std.heap.c_allocator.free(text);

    try buffer.appendSlice(header);
    try buffer.appendSlice(text);
    try buffer.appendSlice("</div>");
}

fn colorizeOverview(unknown: u8, offline: u8, online: u8, total: usize) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (unknown == total) {
        try buffer.appendSlice("bg-neutral-400 dark:bg-neutral-600");
    } else if (online == total) {
        try buffer.appendSlice("bg-green-500 dark:bg-green-700");
    } else if (unknown + offline == 1 and total > 1) {
        try buffer.appendSlice("bg-yellow-500 dark:bg-yellow-700");
    } else if (unknown + offline > 1 and unknown + offline < total) {
        try buffer.appendSlice("bg-orange-500 dark:bg-orange-700");
    } else {
        try buffer.appendSlice("bg-red-500 dark:bg-red-700");
    }

    return buffer.toOwnedSlice();
}

fn contextualizeOverview(unknown: u8, offline: u8, online: u8, total: usize) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (unknown == total) {
        try buffer.appendSlice("system states unknown");
    } else if (online == total) {
        try buffer.appendSlice("all systems operational");
    } else if (unknown + offline == 1 and total > 1) {
        try buffer.appendSlice("one system offline");
    } else if (unknown + offline > 1 and unknown + offline < total) {
        try buffer.appendSlice("several systems offline");
    } else {
        try buffer.appendSlice("all systems unreachable");
    }

    return buffer.toOwnedSlice();
}

fn container(app: database.App, buffer: *std.ArrayList(u8)) !void {
    const content = try utils.format("<div id=\"{d}\" class=\"flex gap-2 flex-col p-4 rounded bg-white dark:bg-black\">", .{app.id});
    defer std.heap.c_allocator.free(content);
    try buffer.appendSlice(content);

    try buffer.appendSlice("<div class=\"w-full flex gap-4 sm:gap-8 justify-between\">");

    const status = switch (app.latest.healthyness) {
        0 => "unknown",
        1 => "offline",
        2 => "unstable",
        3 => "recovery",
        4 => "online",
        else => "",
    };
    const status_color = switch (app.latest.healthyness) {
        0 => "neutral-500 dark:neutral-400",
        1 => "red-600 dark:red-500",
        2 => "orange-600 dark:orange-500",
        3 => "yellow-600 dark:yellow-500",
        4 => "green-600 dark:green-500",
        else => "",
    };
    const latency = utils.nanoseconds(app.latest.latency) catch "???ns";
    defer std.heap.c_allocator.free(latency);

    const left = try utils.format("<p class=\"m-0 font-normal\">{s} <span class=\"font-semibold {s}\">{s}</span> <span class=\"hidden sm:inline font-semibold neutral-400 dark:neutral-500\">{s}</span></p>", .{ app.name, status_color, status, latency });
    defer std.heap.c_allocator.free(left);
    try buffer.appendSlice(left);

    var total_healthy: f32 = 0;
    var total_count: f32 = 0;
    for (app.days) |day| {
        const healthy: f32 = @floatFromInt(day.healthy);
        const count: f32 = @floatFromInt(day.healthy + day.unhealthy);
        total_healthy += healthy;
        total_count += count;
    }
    const percent: f32 = if (total_count != 0) (total_healthy / total_count) * 100 else 0;
    const percent_color = try colorizeUptime(.{ .value = percent, .count = total_count, .healthy = total_healthy });
    defer std.heap.c_allocator.free(percent_color);

    const right = try utils.format("<p class=\"m-0 font-normal\">uptime <span class=\"font-semibold {s}\" title=\"{d:.3}% ({d}/{d})\">{d:.2}%</span></p>", .{ percent_color, percent, total_healthy, total_count, percent });
    defer std.heap.c_allocator.free(right);
    try buffer.appendSlice(right);

    try buffer.appendSlice("</div>");

    try timeline(app.days, buffer);
    try graph(app.days, buffer);

    try buffer.appendSlice("</div>");
}

fn timeline(days: [96]database.Day, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<div class=\"grid gap-0.5 grid-columns-32 sm:grid-columns-48 md:grid-columns-64 lg:grid-columns-80 xl:grid-columns-96\">");

    var index: u7 = 0;
    while (index < days.len) : (index += 1) {
        const percent = percentage(days[index]);
        const display = try visibility(index);
        defer std.heap.c_allocator.free(display);
        const color = try colorizeDay(percent);
        defer std.heap.c_allocator.free(color);
        const slice = try utils.format("<div class=\"{s} h-8 rounded-sm {s}\" title=\"{d:.2}% ({d}/{d})\"></div>", .{ display, color, percent.value, percent.healthy, percent.count });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    try buffer.appendSlice("</div>");
}

const Percentage = struct {
    value: f32,
    count: f32,
    healthy: f32,
};

fn percentage(day: database.Day) Percentage {
    const healthy: f32 = @floatFromInt(day.healthy);
    const count: f32 = @floatFromInt(day.healthy + day.unhealthy);
    const value: f32 = if (count != 0) (healthy / count) * 100 else 0;
    return Percentage{ .value = value, .count = count, .healthy = healthy };
}

fn visibility(index: u7) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (index < 16) {
        try buffer.appendSlice("hidden xl:block");
    } else if (index < 32) {
        try buffer.appendSlice("hidden lg:block");
    } else if (index < 48) {
        try buffer.appendSlice("hidden md:block");
    } else if (index < 64) {
        try buffer.appendSlice("hidden sm:block");
    } else if (index < 80) {
        try buffer.appendSlice("block");
    }

    return buffer.toOwnedSlice();
}

fn colorizeDay(percent: Percentage) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (percent.value == 0 and percent.count == 0) {
        try buffer.appendSlice("bg-neutral-300 dark:bg-neutral-700");
    } else if (percent.value > 99.9) {
        try buffer.appendSlice("bg-green-400 dark:bg-green-600");
    } else if (percent.value > 99) {
        try buffer.appendSlice("bg-yellow-400 dark:bg-yellow-600");
    } else if (percent.value > 98) {
        try buffer.appendSlice("bg-orange-400 dark:bg-orange-600");
    } else {
        try buffer.appendSlice("bg-red-400 dark:bg-red-600");
    }

    return buffer.toOwnedSlice();
}

fn colorizeUptime(percent: Percentage) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (percent.value == 0 and percent.count == 0) {
        try buffer.appendSlice("neutral-500 dark:neutral-400");
    } else if (percent.value > 99.9) {
        try buffer.appendSlice("green-600 dark:green-500");
    } else if (percent.value > 99) {
        try buffer.appendSlice("yellow-600 dark:yellow-500");
    } else if (percent.value > 98) {
        try buffer.appendSlice("orange-600 dark:orange-500");
    } else {
        try buffer.appendSlice("red-600 dark:red-500");
    }

    return buffer.toOwnedSlice();
}

fn graph(days: [96]database.Day, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<div class=\"w-full h-8\">");
    try buffer.appendSlice("<svg class=\"w-full h-full dark:invert\" viewBox=\"0 0 100 100\" preserveAspectRatio=\"none\">");

    try buffer.appendSlice("<line x1=\"0\" y1=\"33.5\" x2=\"100\" y2=\"33.5\" stroke=\"#737373\" stroke-width=\"1\"/>");
    try buffer.appendSlice("<line x1=\"0\" y1=\"66.5\" x2=\"100\" y2=\"66.5\" stroke=\"#737373\" stroke-width=\"1\"/>");
    try buffer.appendSlice("<line x1=\"0\" y1=\"99.5\" x2=\"100\" y2=\"99.5\" stroke=\"#737373\" stroke-width=\"1\"/>");

    const xl_points = try coordinates(days[0..96]);
    defer std.heap.c_allocator.free(xl_points);
    try polyline(xl_points, "hidden xl:block", buffer);

    const lg_points = try coordinates(days[16..96]);
    defer std.heap.c_allocator.free(lg_points);
    try polyline(lg_points, "hidden lg:max-xl:block", buffer);

    const md_points = try coordinates(days[32..96]);
    defer std.heap.c_allocator.free(md_points);
    try polyline(md_points, "hidden md:max-lg:block", buffer);

    const sm_points = try coordinates(days[48..96]);
    defer std.heap.c_allocator.free(sm_points);
    try polyline(sm_points, "hidden sm:max-md:block", buffer);

    const points = try coordinates(days[64..96]);
    defer std.heap.c_allocator.free(points);
    try polyline(points, "hidden max-sm:block", buffer);

    try buffer.appendSlice("</svg>");
    try buffer.appendSlice("</div>");
}

fn coordinates(days: []const database.Day) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    var min_average: f32 = 0;
    var max_average: f32 = 0;
    for (days) |day| {
        const latency: f32 = @floatFromInt(day.latency);
        const count: f32 = @floatFromInt(day.healthy + day.unhealthy);
        if (latency == 0 or count == 0) {
            continue;
        }
        const average = latency / count;
        if (average > max_average or max_average == 0) {
            max_average = average;
        }
        if (average < min_average or min_average == 0) {
            min_average = average;
        }
    }

    var index: u7 = 0;
    while (index < days.len) : (index += 1) {
        const latency: f32 = @floatFromInt(days[index].latency);
        const count: f32 = @floatFromInt(days[index].healthy + days[index].unhealthy);
        if (latency == 0 or count == 0) {
            continue;
        }
        const average = latency / count;
        const fraction = ((average - min_average) / (max_average - min_average)) * 97;
        const len: f32 = @floatFromInt(days.len);
        const ind: f32 = @floatFromInt(index);
        const slice = try utils.format("{d:.2},{d:.0} ", .{ ind / len * 100 + (100 / len / 2), 99 - fraction });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    return buffer.toOwnedSlice();
}

fn polyline(points: []u8, display: []const u8, buffer: *std.ArrayList(u8)) !void {
    const slice = try utils.format("<polyline class=\"{s}\" fill=\"none\" stroke=\"#000000\" stroke-width=\"1\" vector-effect=\"non-scaling-stroke\" points=\"{s}\"/>", .{ display, points });
    defer std.heap.c_allocator.free(slice);
    try buffer.appendSlice(slice);
}
