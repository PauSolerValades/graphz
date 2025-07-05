# GraphZ - A High-Performance Directed Graph implementation in Zig

GraphZ is a Zig implementation of a computational graph directed structure. Its focus is to enable efficient and high perfomance algorithms to be performed over it. 

The following code snippet provides creation and deletion of both nodes and edges with the following syntax:

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

    std.debug.print("Edge 2->3 exists? --> {}\n", .{try graph.hasEdge(2,3)});
    
    // remove edge 2,3
    try graph.removeEdge(2,3);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{try graph.hasEdge(2,3)});

    try graph.newEdge(2, 3, null);
    std.debug.print("Edge 2->3 exists? --> {}\n", .{try graph.hasEdge(2,3)});
    
    // remove node 2
    try graph.removeNode(2);
}

```
If a node with edges to it is deleted, all the edges into and outward that node will be deleted as well. 

```
    var graph = Graph.Graph(u16, f32).init(allocator);
    defer graph.deinit(); 

    // create nodes    
    try graph.newNode(1);
    try graph.newNode(2);

    try graph.newEdge(1,2, null);
    try graph.newEdge(1,1, null);
    
    try graph.removeNode(2);
    //only edge remaning is 1->1

```

Edges support weights with `comptime` types, therefore a stuct with as many elements as wanted can be created (do it at your own risk, it is still not tested).

## Inner Implementation

The `Graph` stores the nodes on a `AutoHashMap` to provide easy access to them. 

`Node` contains two array lists of `*Edge`, edges into the node and edges outward other nodes (the neighbours $N_G(n)$ of the node n). This allows for fast traversal of the graph due to easy access to the edges of the node, as well as efficent deletion of both nodes and edges. TODO: give the choice of the `edges_in` and `edges_out` to be a AutoHashMap for graphs with many more edges than links.


Authors: @SalOrak @PauSolerValades 
