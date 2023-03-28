const std = @import("std");

const c = @cImport({
    @cDefine("_GNU_SOURCE", "");
    @cDefine("_FILE_OFFSET_BITS", "64");
    @cDefine("COMP_DEFAULT", "\"gzip\"");
    @cDefine("GZIP_SUPPORT", "");
    @cDefine("XATTR_SUPPORT", "");
    @cDefine("REPRODUCIBLE_DEFAULT", "");
    @cDefine("NOAPPEND_DEFAULT", "");
    @cInclude("dirent.h");
    @cInclude("sys/stat.h");
    @cInclude("regex.h");
    @cInclude("sys/types.h");
    @cInclude("squashfs-tools/squashfs_fs.h");
    @cInclude("squashfs-tools/mksquashfs.h");
});

pub fn main() !void {
    const args = &[_:null]?[*:0]const u8{ "mksquashfs", "assets", "assets.squashfs", "-noappend", };
    const yarg = @intToPtr([*c][*c]u8, @ptrToInt(args));
    _ = c.cmain(4,yarg);
}