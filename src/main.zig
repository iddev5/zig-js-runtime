const std = @import("std");
const Allocator = std.mem.Allocator;

const js = struct {
    extern fn zigGetProperty(id: u64, name: [*]const u8, len: u32, ret_ptr: *anyopaque) void;
    extern fn zigSetProperty(id: u64, name: [*]const u8, len: u32, set_ptr: *const anyopaque) void;
    extern fn zigGetIndex(id: u64, index: u32, ret_ptr: *anyopaque) void;
    extern fn zigSetIndex(id: u64, index: u32, set_ptr: *const anyopaque) void;
};

pub const Object = extern struct {
    tag: u8,
    val: extern union {
        ref: u64,
        num: f64,
        bool: u8,
        str: extern struct {
            len: u32,
            str: [*]const u8,
        },
    },

    pub const Tag = enum(u8) { ref, num, bool, str };

    pub fn get(obj: *const Object, prop: []const u8) Object {
        var ret: Object = undefined;
        js.zigGetProperty(obj.val.ref, prop.ptr, @intCast(u32, prop.len), &ret);
        return ret;
    }

    pub fn set(obj: *const Object, prop: []const u8, value: *const Object) void {
        js.zigSetProperty(obj.val.ref, prop.ptr, @intCast(u32, prop.len), value);
    }

    pub fn getIndex(obj: *const Object, index: u32) Object {
        var ret: Object = undefined;
        js.zigGetIndex(obj.val.ref, index, &ret);
        return ret;
    }

    pub fn setIndex(obj: *const Object, index: u32, value: *const Object) void {
        js.zigSetIndex(obj.val.ref, index, value);
    }

    pub fn call(obj: *const Object, fun: []const u8, args: []const Object) !void {
        _ = obj;
        _ = fun;
        _ = args;
    }
};

pub fn global() Object {
    return Object{ .tag = 0, .val = .{ .ref = 0 } };
}
