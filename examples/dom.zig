const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    const global = js.global();
    const document = global.get("document");

    const object1 = js.Object.initString("h1");
    const object2 = js.Object.initString("Hello World");

    const h1 = document.call("createElement", &.{object1});
    h1.set("innerText", &object2);

    _ = document.get("body").call("appendChild", &.{h1});
}
