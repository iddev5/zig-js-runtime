const std = @import("std");
const js = @import("js-runtime");

fn zigFunc(args: js.Object, _: u32) js.Value {
    const val1 = args.getIndex(0);
    _ = js.global().get("console").value(.object, null).call("log", &.{val1});
    return js.Value{ .tag = .num, .val = .{ .num = 20.2 } };
}

pub fn main() !void {
    const global = js.global();
    const func = js.createFunction(zigFunc);

    const navigator = global.get("navigator").value(.object, null).get("gpu").value(.object, null);
    const promise = navigator.call("requestAdapter", &.{});
    _ = promise.value(.object, null).call("then", &.{func.toValue()});

    _ = func.invoke(&.{js.createNumber(10.1)});
    global.set("func", func.toValue());
}
