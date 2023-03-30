const std = @import("std");

pub fn module(b: *std.Build) *std.Build.Module {
    return b.createModule(.{
        .source_file = .{ .path = (comptime srcPath()) ++ "/src/turnip.zig" },
        .dependencies = &.{
            .{ .name = "libsquash", .module = squash_module(b) }
        },
    });
}

pub fn squash_module(b: *std.Build) *std.Build.Module {
    return b.createModule(.{
        .source_file = .{ .path = (comptime srcPath()) ++ "/vendor/libsquash.zig" },
    });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "turnip",
        .root_source_file = .{ .path = "examples/embedded.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("turnip", module(b));

    squashLibrary(b, exe, target, optimize);
    // xxHashLibrary(b, exe, target, optimize);

    exe.addIncludePath(srcPath() ++ "/vendor/squashfs-tools");
    exe.linkLibC();
    exe.main_pkg_path = ".";
    exe.install();

    squashFsTool(b, target, optimize);

    const run_cmd = exe.run();

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing.
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "examples/embedded.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe_tests.main_pkg_path = ".";
    squashLibrary(b, exe_tests, target, optimize);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

pub fn xxHashLibrary(b: *std.Build, exe: *std.Build.CompileStep, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {
    const lib = b.addStaticLibrary(.{
        .name = "xxhashlib",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(srcPath() ++ "/vendor/xxHash");
    lib.addIncludePath("/usr/include");
    lib.addIncludePath("/usr/include/x86_64-linux-gnu");
    lib.addLibraryPath("/vendor/xxHash/cmake_unofficial");
    lib.disable_sanitize_c = true;

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    if (optimize == .ReleaseFast) c_flags.append("-Os") catch @panic("error");
    c_flags.append("-DXSUM_NO_MAIN") catch @panic("error");

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        "/vendor/xxHash/cli/xsum_os_specific.c",
        "/vendor/xxHash/cli/xsum_bench.c",
        "/vendor/xxHash/cli/xsum_output.c",
        "/vendor/xxHash/cli/xsum_sanity_check.c"
    }) catch @panic("error");
    for (sources.items) |src| {
        lib.addCSourceFile(b.fmt("{s}{s}", .{srcPath(), src}), c_flags.items);
    }
    exe.linkLibrary(lib);
}

pub fn squashLibrary(b: *std.Build, exe: *std.Build.CompileStep, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {
    const lib = b.addStaticLibrary(.{
        .name = "libsquash",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath(srcPath() ++ "/vendor/libsquash/include");
    lib.addIncludePath("/usr/include");
    lib.addIncludePath("/usr/include/x86_64-linux-gnu");
    lib.addIncludePath("/opt/homebrew/opt/zlib/include");
    lib.addLibraryPath("/opt/homebrew/opt/zlib/lib");
    lib.disable_sanitize_c = true;

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    if (optimize == .ReleaseFast) c_flags.append("-Os") catch @panic("error");

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        "/vendor/libsquash/src/cache.c",
        "/vendor/libsquash/src/decompress.c",
        "/vendor/libsquash/src/dir.c",
        "/vendor/libsquash/src/dirent.c",
        "/vendor/libsquash/src/extract.c",
        "/vendor/libsquash/src/fd.c",
        "/vendor/libsquash/src/file.c",
        "/vendor/libsquash/src/fs.c",
        "/vendor/libsquash/src/hash.c",
        "/vendor/libsquash/src/mutex.c",
        "/vendor/libsquash/src/nonstd-makedev.c",
        "/vendor/libsquash/src/nonstd-stat.c",
        "/vendor/libsquash/src/private.c",
        "/vendor/libsquash/src/readlink.c",
        "/vendor/libsquash/src/scandir.c",
        "/vendor/libsquash/src/stack.c",
        "/vendor/libsquash/src/stat.c",
        "/vendor/libsquash/src/table.c",
        "/vendor/libsquash/src/traverse.c",
        "/vendor/libsquash/src/util.c",
    }) catch @panic("error");
    for (sources.items) |src| {
        lib.addCSourceFile(b.fmt("{s}{s}", .{srcPath(), src}), c_flags.items);
    }

    exe.linkLibC();
    if (target.isLinux() or target.isWindows())
        exe.linkSystemLibrary("zlib")
    else
        exe.linkSystemLibrary("z");

    exe.linkLibrary(lib);
}

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
    }) catch @panic("error");
    for (sources.items) |src| {
        exe.addCSourceFile(b.fmt("{s}{s}", .{ srcPath(), src }), c_flags.items);
    }

    exe.linkLibC();
    if (target.isLinux() or target.isWindows())
        exe.linkSystemLibrary("zlib")
    else
        exe.linkSystemLibrary("z");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const assets_step = b.step("assets", "Package the assets");
    assets_step.dependOn(&run_cmd.step);
}

inline fn srcPath() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse @panic("error");
}
