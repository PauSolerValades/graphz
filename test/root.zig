const std = @import("std");
const except = std.testing.except;
const Graph = @import("graphz_lib");

test "Graph: init and deinit" {
    const talloc = std.testing.allocator;
    const graph = Graph.Graph(u8, f16).init(talloc);
    defer graph.deinit(); 
}
