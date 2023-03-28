const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "turnip",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    //xxHashLibrary(exe, optimize);
    exe.addIncludePath(srcPath() ++ "/vendor/squashfs-tools");
    squashFsTool(b, target, optimize);
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing.
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

// pub fn xxHashLibrary(step: *std.build.CompileStep, optimize: std.builtin.OptimizeMode) void {
//     const b = step.builder;
//     const lib = b.addStaticLibrary(.{
//         .name = "xxhashlib",
//         .target = step.target,
//         .optimize = step.optimize,
//     });
//     lib.addIncludePath(srcPath() ++ "/vendor/xxHash");
//     lib.addIncludePath("/usr/include");
//     lib.addIncludePath("/usr/include/x86_64-linux-gnu");
//     lib.addLibraryPath("/vendor/xxHash/cmake_unofficial");
//     lib.disable_sanitize_c = true;

//     var c_flags = std.ArrayList([]const u8).init(b.allocator);
//     if (optimize == .ReleaseFast) c_flags.append("-Os") catch @panic("error");
//     c_flags.append("-DXSUM_NO_MAIN") catch @panic("error");

//     var sources = std.ArrayList([]const u8).init(b.allocator);
//     sources.appendSlice(&.{
//         "/vendor/xxHash/cli/xsum_os_specific.c",
//         "/vendor/xxHash/cli/xsum_bench.c",
//         "/vendor/xxHash/cli/xsum_output.c",
//         "/vendor/xxHash/cli/xsum_sanity_check.c"
//     }) catch @panic("error");
//     for (sources.items) |src| {
//         lib.addCSourceFile(b.fmt("{s}{s}", .{srcPath(), src}), c_flags.items);
//     }
//     step.linkLibrary(lib);
// }

pub fn squashFsTool(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "mksquashfs",
        .root_source_file = .{ .path = "tools/mksquashfs.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(srcPath() ++ "/vendor/squashfs-tools");
    exe.addIncludePath("/usr/include");
    exe.addIncludePath("/usr/include/x86_64-linux-gnu");
    exe.addIncludePath("/opt/homebrew/opt/zlib/include");
    exe.addLibraryPath("/vendor/squashfs-tools");
    exe.addLibraryPath("/opt/homebrew/opt/zlib/lib");
    exe.disable_sanitize_c = true;

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    if (optimize == .ReleaseFast) c_flags.append("-Os") catch @panic("error");
    c_flags.append("-D_FILE_OFFSET_BITS=64") catch @panic("error");
    c_flags.append("-D_GNU_SOURCE") catch @panic("error");
    c_flags.append("-DCOMP_DEFAULT=\"gzip\"") catch @panic("error");
    c_flags.append("-DGZIP_SUPPORT") catch @panic("error");
    c_flags.append("-DXATTR_SUPPORT") catch @panic("error");
    c_flags.append("-DREPRODUCIBLE_DEFAULT") catch @panic("error");
    c_flags.append("-DNOAPPEND_DEFAULT") catch @panic("error");

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        "/vendor/squashfs-tools/squashfs-tools/mksquashfs.c",
        "/vendor/squashfs-tools/squashfs-tools/read_fs.c",
        "/vendor/squashfs-tools/squashfs-tools/action.c",
        "/vendor/squashfs-tools/squashfs-tools/swap.c",
        "/vendor/squashfs-tools/squashfs-tools/pseudo.c",
        "/vendor/squashfs-tools/squashfs-tools/compressor.c",
        "/vendor/squashfs-tools/squashfs-tools/sort.c",
        "/vendor/squashfs-tools/squashfs-tools/progressbar.c",
        "/vendor/squashfs-tools/squashfs-tools/info.c",
        "/vendor/squashfs-tools/squashfs-tools/restore.c",
        "/vendor/squashfs-tools/squashfs-tools/process_fragments.c",
        "/vendor/squashfs-tools/squashfs-tools/caches-queues-lists.c",
        "/vendor/squashfs-tools/squashfs-tools/reader.c",
        "/vendor/squashfs-tools/squashfs-tools/tar.c",
        "/vendor/squashfs-tools/squashfs-tools/date.c",
        "/vendor/squashfs-tools/squashfs-tools/gzip_wrapper.c",
        "/vendor/squashfs-tools/squashfs-tools/xattr.c",
        "/vendor/squashfs-tools/squashfs-tools/read_xattrs.c",
        "/vendor/squashfs-tools/squashfs-tools/tar_xattr.c",
        "/vendor/squashfs-tools/squashfs-tools/pseudo_xattr.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquashfs.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-1.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-2.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-3.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-4.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-123.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-34.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-1234.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquash-12.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquashfs_info.c",
        // "/vendor/squashfs-tools/squashfs-tools/unsquashfs_xattr.c"
    }) catch @panic("error");
    for (sources.items) |src| {
        exe.addCSourceFile(b.fmt("{s}{s}", .{ srcPath(), src }), c_flags.items);
    }

    exe.linkLibC();
    if (target.isLinux() or target.isWindows())
        exe.linkSystemLibrary("zlib")
    else
        exe.linkSystemLibrary("z");

    exe.setOutputDir("zig-out/tools");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const assets_step = b.step("assets", "Package the assets");
    assets_step.dependOn(&run_cmd.step);
}

inline fn srcPath() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse @panic("error");
}
