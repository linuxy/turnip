# turnip
An embedded virtual file system for games and other projects

Builds against zig 0.11.0-dev.2477+2ee328995+

```git clone --recursive https://github.com/linuxy/turnip.git```

Example integration:
https://github.com/linuxy/coyote-snake/tree/turnip

To package assets in folder assets (zig-out output):
* `zig build assets`

To build examples
* `zig build -Dexamples=true`

To build coyote-snake example (from branch)
* `zig build -Dgame=true`

Integrating Turnip in your project

build.zig
```Zig
const std = @import("std");
const turnip = @import("vendor/turnip/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    turnip.squashFsTool(b, target, optimize);

    if(b.option(bool, "game", "Build game") == true)
        buildGame(b, target, optimize);
}

pub fn buildGame(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {

    const exe = b.addExecutable(.{
        .root_source_file = .{ .path = "src/coyote-snake.zig"},
        .optimize = optimize,
        .target = target,
        .name = "snake",
    });

    exe.linkLibC();

    //Turnip
    exe.addModule("turnip", turnip.module(b));
    exe.main_pkg_path = ".";
    turnip.squashLibrary(b, exe, target, optimize);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

game.zig
```Zig
const Turnip = @import("turnip").Turnip;

var embedded_assets = @embedFile("../zig-out/assets.squashfs");

//Initialize & load turnip assets
self.assets = Turnip.init();
try self.assets.loadImage(embedded_assets, 0);

//Read texture from virtual FS
pub inline fn loadTexture(game: *Game, path: []const u8) !?*c.SDL_Texture {
    var buffer: [1024:0]u8 = std.mem.zeroes([1024:0]u8);
    var fd = try game.assets.open(@ptrCast([*]const u8, path));

    var data: []u8 = &std.mem.zeroes([0:0]u8);
    var size: c_int = 0;
    while(true) {
        var sz = @intCast(c_int, try game.assets.read(fd, &buffer, 1024));

        if(sz < 1)
            break;

        data = try std.mem.concat(allocator, u8,  &[_][]const u8{ data, &buffer });
        size += sz;
    }
    defer allocator.free(data);

    var texture = c.IMG_LoadTexture_RW(game.renderer, c.SDL_RWFromMem(@ptrCast(?*anyopaque, data), size), 1) orelse
    {
        c.SDL_Log("Unable to load image: %s", c.SDL_GetError());
        return error.SDL_LoadTexture_RWFailed;
    };

    try game.assets.close(fd);

    return texture;
}

```
