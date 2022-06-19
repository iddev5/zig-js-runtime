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
    extern fn zigGetString(val_id: u64, ptr: [*]const u8) void;
    extern fn zigDeleteIndex(id: u64, index: u32) void;
    extern fn zigFunctionCall(id: u64, name: [*]const u8, len: u32, args: ?*const anyopaque, args_len: u32, ret_ptr: *anyopaque) void;
    extern fn zigFunctionInvoke(id: u64, args: ?*const anyopaque, args_len: u32, ret_ptr: *anyopaque) void;
    extern fn zigCleanupObject(id: u64) void;
};

pub const Value = extern struct {
    tag: ValueTag,
    val: extern union {
        ref: u64,
        num: f64,
        bool: bool,
        str: extern struct {
            len: u32,
            str: [*]const u8,
        },
    },

    const ValueTag = enum(u8) {
        ref,
        num,
        bool,
        str_in,
        str_out,
        nulled,
        undef,
        func_js,
    };

    pub const Tag = enum {
        object,
        num,
        bool,
        str,
        nulled,
        undef,
        func,
    };

    pub fn is(val: *const Value, comptime tag: Tag) bool {
        return switch (tag) {
            .object => val.tag == .object,
            .num => val.tag == .num,
            .bool => val.tag == .bool,
            .str => val.tag == .str_in or val.tag == .str_out,
            .nulled => val.tag == .nulled,
            .undef => val.tag == .undef,
            .func => val.tag == .func_js,
        };
    }

    pub fn value(val: *const Value, comptime tag: Tag, allocator: ?std.mem.Allocator) switch (tag) {
        .object => Object,
        .num => f64,
        .bool => bool,
        .str => std.mem.Allocator.Error![]const u8,
        .func => Function,
        .nulled, .undef => @compileError("Cannot get null or undefined as a value"),
    } {
        return switch (tag) {
            .object => Object{ .ref = val.val.ref },
            .num => val.val.num,
            .bool => val.val.bool,
            .str => blk: {
                if (val.tag == .str_in) {
                    const slice: []const u8 = undefined;
                    slice.len = val.val.str.len;
                    slice.ptr = val.val.str.str;
                    break :blk try allocator.?.dupe(u8, slice);
                } else {
                    var slice = try allocator.?.alloc(u8, val.val.str.len);
                    js.zigGetString(@intCast(u64, @ptrToInt(val.val.str.str)), slice.ptr);
                    break :blk slice;
                }
            },
            .func => Function{ .ref = val.val.ref },
            else => unreachable,
        };
    }
};

pub const Object = struct {
    ref: u64,

    pub fn deinit(obj: *const Object) void {
        js.zigCleanupObject(obj.ref);
    }

    pub fn toValue(obj: *const Object) Value {
        return .{ .tag = .ref, .val = .{ .ref = obj.ref } };
    }

    pub fn get(obj: *const Object, prop: []const u8) Value {
        var ret: Value = undefined;
        js.zigGetProperty(obj.ref, prop.ptr, @intCast(u32, prop.len), &ret);
        return ret;
    }

    pub fn set(obj: *const Object, prop: []const u8, value: Value) void {
        js.zigSetProperty(obj.ref, prop.ptr, @intCast(u32, prop.len), &value);
    }

    pub fn delete(obj: *const Object, prop: []const u8) void {
        js.zigDeleteProperty(obj.ref, prop.ptr, @intCast(u32, prop.len));
    }

    pub fn getIndex(obj: *const Object, index: u32) Value {
        var ret: Object = undefined;
        js.zigGetIndex(obj.ref, index, &ret);
        return ret;
    }

    pub fn setIndex(obj: *const Object, index: u32, value: Value) void {
        js.zigSetIndex(obj.ref, index, &value);
    }

    pub fn deleteIndex(obj: *const Object, index: u32) void {
        js.zigDeleteIndex(obj.ref, index);
    }

    pub fn call(obj: *const Object, fun: []const u8, args: []const Value) Value {
        var ret: Value = undefined;
        js.zigFunctionCall(obj.ref, fun.ptr, fun.len, args.ptr, args.len, &ret);
        return ret;
    }
};

pub const Function = struct {
    ref: u64,

    pub fn deinit(obj: *const Object) void {
        js.zigCleanupObject(obj.ref);
    }

    pub fn invoke(func: *const Function, args: []const Value) Value {
        var ret: Value = undefined;
        js.zigFunctionInvoke(func.ref, args.ptr, args.len, &ret);
        return ret;
    }
};

pub fn global() Object {
    return Object{ .ref = 0 };
}

pub fn createMap() Object {
    return .{ .ref = js.zigCreateMap() };
}

pub fn createArray() Object {
    return .{ .ref = js.zigCreateArray() };
}

pub fn createString(string: []const u8) Value {
    return .{ .tag = .str_in, .val = .{ .str = .{ .len = string.len, .str = string.ptr } } };
}

pub fn createNumber(num: f64) Value {
    return .{ .tag = .num, .val = .{ .num = num } };
}

pub fn createBool(val: bool) Value {
    return .{ .tag = .bool, .val = .{ .bool = val } };
}

pub fn createNull() Value {
    return .{ .tag = .nulled, .val = undefined };
}

pub fn createUndefined() Value {
    return .{ .tag = .undef, .val = undefined };
}
