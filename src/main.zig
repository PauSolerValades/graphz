const std = @import("std");
const Graph = @import("graphz_lib");

pub fn main() !void {
    std.debug.print("Hello Grpah", .{});
    const allocator = std.heap.page_allocator;
    var graph = Graph.Graph(u16, f32).init(allocator);
    
    try graph.newNode(2);
    try graph.newNode(3);


    try graph.newEdge(2, 3, null);
    try graph.newEdge(4, 3, null); // Should be an error

}
