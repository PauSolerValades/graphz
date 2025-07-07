# GraphZ - A High-Performance Directed Graph implementation in Zig

GraphZ is a Zig implementation of a computational graph directed structure. Its focus is to enable efficient and high perfomance algorithms to be performed over it. The library supports graph with information on the Node and on the Edge which must be provided at compile time to allow as much flexibility as possible.

The following code snippet provides an example of the main calls of the library assuming no extra payload in the nodes and the graphs. 

``` zig
const std = @import("std");
const Graph = @import("graphz_lib");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var graph = Graph.Graph(u16, void, void).init(allocator);
    defer graph.deinit();
    
    //add some nodes
    try graph.newNode(1, null);
    try graph.newNode(2, null);
    try graph.newNode(3, null);
    
    //add some edges 
    try graph.newEdge(1,1, null);
    try graph.newEdge(1,2, null);
    try graph.newEdge(2,3, null);
    try graph.newEdge(1,3, null);
    try graph.newEdge(3,1, null);
    
    _ = try graph.hasEdge(2,3); //true
    _ = try graph.hasEdge(2,1); //false
    
    // attempting to ask for an non existant node will yield an error 
    std.testing.expectError(Graph.GraphError.NodeNotFound, graph.hasEdge(4,1));
    
    // neighbors of 1 
    const n1 = try graph.getNeighbors(allocator, 1); // 1,2,3
    defer allocator.free(n1);
    
    // can also be asked without dynamic memory
    var buffer: [10]u16 = undefined;
    const n1_buff = try graph.getNeighbots(&buffer, 1);
    std.testing.expectEqualSlice(u16, n1_buff, &[]u16{1,2,3});

    // remove edge 2->3. Retuns null as the struct is void
    _ = try graph.removeEdge(2,3);
    
    // remove node 2. this removes all the nodes to 2 and out from 2
    _ = try graph.removeNode(1);
    _ = try graph.hasEdge(1,1); //false
    _ = try graph.hasEdge(1,2); //false
    _ = try graph.hasEdge(1,3); //false}

```

Additionally, the following code provides an example with complex information stored in the node and the edges.

```
    const Edge = struct {
        weight: f16,
        capacity: f16,
    };

    // f16 in node is the demand of a node
    // the types must be provided on graph creation and cannot be changed
    var graph = Graph(u8, f16, Edge).init(testing.allocator);
    defer graph.deinit();

    try graph.newNode(1, 8);
    try graph.newNode(2, -8);
    
    const p12: Edge= .{ .weight = 10, .capacity = 1};
    try graph.newEdge(1,2, p12);

```

## Implementation Details

+ `Graph` stores the nodes on a `AutoHashMap` to provide a fast look up.
+ `Node` contains two array lists of `*Edge`, edges into the node and edges outward other nodes (the neighbours $N_G(n)$ of the node n). This allows for fast traversal of the graph due to easy access to the edges of the node, as well as efficent deletion of both nodes and edges. TODO: give the choice of the `edges_in` and `edges_out` to be a AutoHashMap for graphs with many more edges than links.
+ The `removeSmth()` returns the type/struct provided in the method

## Disclaimer

This project has been developed by @SalOrak and @PauSolerValades with no higher puropose than to understand better the zig programming language. If you happen to stumble upon this code and wan to use it or contribute to it, feel free to do it and tell us :) 
