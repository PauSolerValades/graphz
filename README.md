# GraphZ - A Directed Graph implementation in Zig

GraphZ is a Zig implementation of a computational graph directed structure.

The code provides creation and deletion of both nodes and edges with the following syntax:

``` zig

const std = @import("std");
const Graph = @import("graphz_lib");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var graph = Graph.Graph(u16, f32).init(allocator);
    defer graph.deinit(); 

    // create nodes    
    try graph.newNode(2);
    try graph.newNode(3);

    try graph.newEdge(2, 3, null);

    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});
    
    // remove edge 2,3
    try graph.removeEdge(2,3);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});

    try graph.newEdge(2, 3, null);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{graph.hasEdge(2,3)});
    
    // remove node 2
    try graph.removeNode(2);
}

```

Edges support weights with `comptime` types, therefore a stuct with as many elements as wanted can be created (do it at your own risk we have not tried it).

Authors: @SalOrak @PauSolerValades 
