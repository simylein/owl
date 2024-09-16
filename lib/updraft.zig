const std = @import("std");

pub fn style(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<style>");

    try global(buffer);
    try small(buffer);
    try medium(buffer);
    try large(buffer);
    try giant(buffer);
    try dark(buffer);

    try buffer.appendSlice("</style>");
}

fn global(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("body{-webkit-font-smoothing: antialiased;-moz-osx-font-smoothing: grayscale;font-family: -apple-system, BlinkMacSystemFont, Helvetica, Arial, Roboto, Oxygen, sans-serif}");

    try buffer.appendSlice(".w-full{width:100%}");
    try buffer.appendSlice(".h-8{height:32px}");

    try buffer.appendSlice(".m-0{margin:0}");
    try buffer.appendSlice(".mx-4{margin-left:16px;margin-right:16px}");
    try buffer.appendSlice(".my-6{margin-top:24px;margin-bottom:24px}");

    try buffer.appendSlice(".p-4{padding:16px}");

    try buffer.appendSlice(".gap-0\\.5{gap:2px}");
    try buffer.appendSlice(".gap-2{gap:8px}");
    try buffer.appendSlice(".gap-4{gap:16px}");

    try buffer.appendSlice(".hidden{display:none}");

    try buffer.appendSlice(".flex{display:flex}");
    try buffer.appendSlice(".flex-col{flex-direction:column}");
    try buffer.appendSlice(".justify-between{justify-content:space-between}");

    try buffer.appendSlice(".grid{display:grid}");
    try buffer.appendSlice(".grid-columns-32{grid-template-columns:repeat(32,minmax(0,1fr))}");

    try buffer.appendSlice(".text-base{font-size:16px}");
    try buffer.appendSlice(".text-xl{font-size:20px}");
    try buffer.appendSlice(".font-normal{font-weight:400}");
    try buffer.appendSlice(".font-semibold{font-weight:600}");
    try buffer.appendSlice(".font-bold{font-weight:700}");

    try buffer.appendSlice(".rounded{border-radius:4px}");
    try buffer.appendSlice(".rounded-sm{border-radius:2px}");

    try buffer.appendSlice(".black{color:#000000}");
    try buffer.appendSlice(".white{color:#ffffff}");
    try buffer.appendSlice(".neutral-400{color:#a3a3a3}");
    try buffer.appendSlice(".neutral-500{color:#737373}");
    try buffer.appendSlice(".red-600{color:#dc2626}");
    try buffer.appendSlice(".orange-600{color:#ea580c}");
    try buffer.appendSlice(".yellow-600{color:#ca8a04}");
    try buffer.appendSlice(".green-600{color:#16a34a}");

    try buffer.appendSlice(".bg-white{background-color:#ffffff}");
    try buffer.appendSlice(".bg-neutral-100{background-color:#f5f5f5}");
    try buffer.appendSlice(".bg-neutral-300{background-color:#d4d4d4}");
    try buffer.appendSlice(".bg-neutral-400{background-color:#a3a3a3}");
    try buffer.appendSlice(".bg-red-400{background-color:#f87171}");
    try buffer.appendSlice(".bg-red-500{background-color:#ef4444}");
    try buffer.appendSlice(".bg-orange-400{background-color:#fb923c}");
    try buffer.appendSlice(".bg-orange-500{background-color:#f97316}");
    try buffer.appendSlice(".bg-yellow-400{background-color:#facc15}");
    try buffer.appendSlice(".bg-yellow-500{background-color:#eab308}");
    try buffer.appendSlice(".bg-green-400{background-color:#4ade80}");
    try buffer.appendSlice(".bg-green-500{background-color:#22c55e}");
}

fn small(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(min-width:512px){");

    try buffer.appendSlice(".sm\\:mx-8{margin-left:32px;margin-right:32px}");
    try buffer.appendSlice(".sm\\:my-9{margin-top:36px;margin-bottom:36px}");

    try buffer.appendSlice(".sm\\:gap-4{gap:16px}");
    try buffer.appendSlice(".sm\\:gap-8{gap:32px}");

    try buffer.appendSlice(".sm\\:block{display:block}");
    try buffer.appendSlice(".sm\\:inline{display:inline}");

    try buffer.appendSlice(".sm\\:grid-columns-48{grid-template-columns:repeat(48,minmax(0,1fr))}");

    try buffer.appendSlice("}");
}

fn medium(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(min-width:768px){");

    try buffer.appendSlice(".md\\:mx-16{margin-left:64px;margin-right:64px}");
    try buffer.appendSlice(".md\\:my-12{margin-top:48px;margin-bottom:48px}");

    try buffer.appendSlice(".md\\:block{display:block}");

    try buffer.appendSlice(".md\\:grid-columns-64{grid-template-columns:repeat(64,minmax(0,1fr))}");

    try buffer.appendSlice("}");
}

fn large(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(min-width:1024px){");

    try buffer.appendSlice(".lg\\:block{display:block}");

    try buffer.appendSlice(".lg\\:grid-columns-80{grid-template-columns:repeat(80,minmax(0,1fr))}");

    try buffer.appendSlice("}");
}

fn giant(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(min-width:1280px){");

    try buffer.appendSlice(".xl\\:block{display:block}");

    try buffer.appendSlice(".xl\\:grid-columns-96{grid-template-columns:repeat(96,minmax(0,1fr))}");

    try buffer.appendSlice("}");
}

fn dark(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(prefers-color-scheme:dark){");

    try buffer.appendSlice(".dark\\:white{color:#ffffff}");
    try buffer.appendSlice(".dark\\:neutral-500{color:#737373}");
    try buffer.appendSlice(".dark\\:neutral-400{color:#a3a3a3}");
    try buffer.appendSlice(".dark\\:red-500{color:#ef4444}");
    try buffer.appendSlice(".dark\\:orange-500{color:#f97316}");
    try buffer.appendSlice(".dark\\:yellow-500{color:#eab308}");
    try buffer.appendSlice(".dark\\:green-500{color:#22c55e}");

    try buffer.appendSlice(".dark\\:bg-black{background-color:#000000}");
    try buffer.appendSlice(".dark\\:bg-neutral-600{background-color:#525252}");
    try buffer.appendSlice(".dark\\:bg-neutral-700{background-color:#404040}");
    try buffer.appendSlice(".dark\\:bg-neutral-900{background-color:#171717}");
    try buffer.appendSlice(".dark\\:bg-red-600{background-color:#dc2626}");
    try buffer.appendSlice(".dark\\:bg-red-700{background-color:#b91c1c}");
    try buffer.appendSlice(".dark\\:bg-orange-600{background-color:#ea580c}");
    try buffer.appendSlice(".dark\\:bg-orange-700{background-color:#c2410c}");
    try buffer.appendSlice(".dark\\:bg-yellow-600{background-color:#ca8a04}");
    try buffer.appendSlice(".dark\\:bg-yellow-700{background-color:#a16207}");
    try buffer.appendSlice(".dark\\:bg-green-600{background-color:#16a34a}");
    try buffer.appendSlice(".dark\\:bg-green-700{background-color:#15803d}");

    try buffer.appendSlice("}");
}
