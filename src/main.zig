const std = @import("std");
const Graph = @import("graphz_lib");

pub fn main() void {
    std.debug.print("Hello Grpah", .{});
    const allocator = std.heap.page_allocator;
    _ = Graph.Graph(u16, f32).init(allocator);

}
