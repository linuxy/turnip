const std = @import("std");
pub const c = @import("libsquash");

pub const Turnip = struct {
    fs: c.sqfs,
    data: [*]const u8,
    opened: bool,

    pub fn init() Turnip {
        var image: Turnip = .{
            .fs = std.mem.zeroes(c.sqfs),
            .data = undefined,
            .opened = false,
        };
        return image;
    }

    pub fn loadImage(self: *Turnip, data_ptr: [*]const u8, offset: usize) anyerror!void {
        self.data = data_ptr;
        var err = ec(c.sqfs_open_image(&self.fs, self.data, offset));
        switch(err) {
            error.Ok => self.opened = true,
            else => return err,
        }
    }

    pub fn read(self: *Turnip, fd: i32, buffer: [:0]u8, buffsize: c_long) anyerror!isize {
        var size = c.squash_read(fd, @ptrCast(?*anyopaque, buffer), buffsize);

        if(size < 0)
            return error.FileReadError;

        _ = self;
        return size;
    }

    pub fn open(self: *Turnip, path: [*]const u8) anyerror!i32 {
        var fd = c.squash_open(&self.fs, path);

        if(fd < 0)
            return error.FileOpenError;

        return fd;
    }

    pub fn close(self: *Turnip, fd: i32) anyerror!void {
        var ret = c.squash_close(fd);
        _ = self;

        if(ret < 0)
            return error.FileCloseError;
    }

    pub fn deinit(self: *Turnip) void {
        if(self.opened)
            c.sqfs_destroy(&self.fs);

        self.fs = std.mem.zeroes(c.sqfs);
        self.data = undefined;
        self.opened = false;
    }
};

pub fn ec(code: c_uint) anyerror {
    switch(code) {
        0 => return error.Ok,
        1 => return error.Error,
        2 => return error.BadFormat,
        3 => return error.BadVersion,
        4 => return error.BadCompressor,
        5 => return error.Unsupported,
        else => return error.Unknown,
    }
}