const std = @import("std");
const Allocator = std.mem.Allocator;

const js = struct {
    extern fn zigCreateMap() u32;
    extern fn zigCreateArray() u32;
    extern fn zigGetProperty(id: u64, name: [*]const u8, len: u32, ret_ptr: *anyopaque) void;
    extern fn zigSetProperty(id: u64, name: [*]const u8, len: u32, set_ptr: *const anyopaque) void;
    extern fn zigDeleteProperty(id: u64, name: [*]const u8, len: u32) void;
    extern fn zigGetIndex(id: u64, index: u32, ret_ptr: *anyopaque) void;
    extern fn zigSetIndex(id: u64, index: u32, set_ptr: *const anyopaque) void;
    extern fn zigDeleteIndex(id: u64, index: u32) void;
    extern fn zigFunctionCall(id: u64, name: [*]const u8, len: u32, args: ?*const anyopaque, args_len: u32, ret_ptr: *anyopaque) void;
    extern fn zigCleanupObject(id: u64) void;
};

pub const Object = extern struct {
    tag: Tag,
    val: extern union {
        ref: u64,
        num: f64,
        bool: bool,
        str: extern struct {
            len: u32,
            str: [*]const u8,
        },
    },

    pub const Tag = enum(u8) { ref, num, bool, str, nulled, undef };

    pub fn initMap() Object {
        return .{ .tag = .ref, .val = .{ .ref = js.zigCreateMap() } };
    }

    pub fn initArray() Object {
        return .{ .tag = .ref, .val = .{ .ref = js.zigCreateArray() } };
    }

    pub fn initString(string: []const u8) Object {
        return .{ .tag = .str, .val = .{ .str = .{ .len = string.len, .str = string.ptr } } };
    }

    pub fn deinit(obj: *const Object) void {
        js.zigCleanupObject(obj.val.ref);
    }

    pub fn get(obj: *const Object, prop: []const u8) Object {
        var ret: Object = undefined;
        js.zigGetProperty(obj.val.ref, prop.ptr, @intCast(u32, prop.len), &ret);
        return ret;
    }

    pub fn set(obj: *const Object, prop: []const u8, value: *const Object) void {
        js.zigSetProperty(obj.val.ref, prop.ptr, @intCast(u32, prop.len), value);
    }

    pub fn delete(obj: *const Object, prop: []const u8) void {
        js.zigDeleteProperty(obj.val.ref, prop.ptr, @intCast(u32, prop.len));
    }

    pub fn getIndex(obj: *const Object, index: u32) Object {
        var ret: Object = undefined;
        js.zigGetIndex(obj.val.ref, index, &ret);
        return ret;
    }

    pub fn setIndex(obj: *const Object, index: u32, value: *const Object) void {
        js.zigSetIndex(obj.val.ref, index, value);
    }

    pub fn deleteIndex(obj: *const Object, index: u32) void {
        js.zigDeleteIndex(obj.val.ref, index);
    }

    pub fn call(obj: *const Object, fun: []const u8, args: []const Object) Object {
        var ret: Object = undefined;
        js.zigFunctionCall(obj.val.ref, fun.ptr, fun.len, args.ptr, args.len, &ret);
        return ret;
    }
};

pub fn global() Object {
    return Object{ .tag = .ref, .val = .{ .ref = 0 } };
}
