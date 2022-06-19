const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    if (true) unreachable;

    const global = js.global();
    const xyz = global.get("xyz").value(.func, null);
    global.set("xyz_result", xyz.invoke(&.{}));
}
