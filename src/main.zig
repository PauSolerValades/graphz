const std = @import("std");
const Graph = @import("graphz_lib");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var graph = Graph.Graph(u16, f32).init(allocator);
    defer graph.deinit();

    try graph.newNode(2);
    try graph.newNode(3);

    try graph.newEdge(2, 3, null);

    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});

    try graph.removeEdge(2,3);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});

    try graph.newEdge(2, 3, null);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});

    try graph.removeNode(2);
    

}

















