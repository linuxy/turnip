const std = @import("std");
const c = @import("turnip").c;
const turnip = @import("turnip").Turnip;

const assert = std.debug.assert;

var embedded_assets = @embedFile("../zig-out/assets.squashfs");

pub fn main() !void {
    var fs: c.sqfs = std.mem.zeroes(c.sqfs);
    var ret = c.sqfs_open_image(&fs, embedded_assets, 0);
    defer c.sqfs_destroy(&fs);

    assert(ret == c.SQFS_OK);

    var fd = c.squash_open(&fs, "/test2");
    assert(fd > 0);

    var buffer: [3]u8 = std.mem.zeroes([3]u8);
    var rsize = c.squash_read(fd, @ptrCast(?*anyopaque, &buffer), 3);

    assert(rsize == 3);
    assert(std.mem.eql(u8, &buffer, "moo"));

    var ret_c = c.squash_close(fd);
    assert(ret_c == 0);

    var asset = turnip.init();
    defer asset.deinit();

    try asset.loadImage(embedded_assets, 0);
    var abuffer: [3]u8 = std.mem.zeroes([3]u8);
    var fd = try asset.open("/test2");
    assert(fd > 0);

    var arsize = asset.read(fd, &buffer, 3);
}

test "open/close image" {
    var fs: c.sqfs = std.mem.zeroes(c.sqfs);
    var ret = c.sqfs_open_image(&fs, embedded_assets, 0);
    defer c.sqfs_destroy(&fs);

    assert(ret == c.SQFS_OK);
}

test "read image" {
    var fs: c.sqfs = std.mem.zeroes(c.sqfs);
    var ret = c.sqfs_open_image(&fs, embedded_assets, 0);
    defer c.sqfs_destroy(&fs);

    assert(ret == c.SQFS_OK);

    var fd = c.squash_open(&fs, "/test2");
    assert(fd > 0);

    var buffer: [3]u8 = std.mem.zeroes([3]u8);
    var rsize = c.squash_read(fd, @ptrCast(?*anyopaque, &buffer), 3);

    assert(rsize == 3);
    assert(std.mem.eql(u8, &buffer, "moo"));

    var ret_c = c.squash_close(fd);
    assert(ret_c == 0);
}