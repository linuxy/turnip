const std = @import("std");
const c = @import("turnip").c;
const turnip = @import("turnip").Turnip;

const assert = std.debug.assert;

var embedded_assets = @embedFile("../zig-out/assets.squashfs");

pub fn main() !void {
    var assets = turnip.init();
    defer assets.deinit();

    try assets.loadImage(embedded_assets, 0);
    var buffer: [3:0]u8 = std.mem.zeroes([3:0]u8);
    var fd = try assets.open("/test2");
    defer assets.close(fd) catch unreachable;

    assert(fd > 0);

    var rsize = try assets.read(fd, &buffer, 3);
    assert(rsize == 3);
    assert(std.mem.eql(u8, &buffer, "moo"));
}

test "open/close image" {
    var assets = turnip.init();
    defer assets.deinit();

    try assets.loadImage(embedded_assets, 0);
}

test "read image" {
    var assets = turnip.init();
    defer assets.deinit();

    try assets.loadImage(embedded_assets, 0);
    var buffer: [3:0]u8 = std.mem.zeroes([3:0]u8);
    var fd = try assets.open("/test2");
    defer assets.close(fd) catch unreachable;

    assert(fd > 0);

    var rsize = try assets.read(fd, &buffer, 3);
    assert(rsize == 3);
    assert(std.mem.eql(u8, &buffer, "moo"));
}