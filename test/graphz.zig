test "Graph init and deinit" {
    const len: usize = 8;
    const allocator = std.testing.allocator;
    const graph = Graph(u8, f16, len).init(allocator);
    defer graph.deinit();
}

test "Graph: adds nodes" {
    const len: usize = 8;
    const allocator = std.testing.allocator;
    var graph = Graph(u8, f16, len).init(allocator);
    defer graph.deinit();
    try graph.newNode(10);
    try graph.newNode(11);
    try graph.newNode(12);

    const nodes = graph.getNodes();
    try expect(nodes.len == 3);
    try expect(graph.hasNode(10));
    try expect(graph.hasNode(11));
    try expect(graph.hasNode(12));
    try expect(!graph.hasNode(9));
}

test "Graph: remove nodes" {
    const len: usize = 8;
    const allocator = std.testing.allocator;
    var graph = Graph(u8, f16, len).init(allocator);
    defer graph.deinit();
    try graph.newNode(10);
    try graph.newNode(20);
    try graph.newNode(30);
    try graph.newNode(40);
    try graph.newNode(50);

    var nodes = graph.getNodes();
    try expect(nodes.len == 5);
   
    // Remove first node (index 0) -- Case 1)
    try graph.removeNode(10);
    nodes = graph.getNodes();
    try expect(nodes.len == 4);
    try expect(!graph.hasNode(10));
    try expect(graph.hasNode(20));
    try expect(graph.hasNode(30));
    try expect(graph.hasNode(40));
    try expect(graph.hasNode(50));

    // Remove last node (index 4) -- Case 3)
    try graph.removeNode(50);
    nodes = graph.getNodes();
    try expect(nodes.len == 3);
    try expect(!graph.hasNode(10));
    try expect(graph.hasNode(20));
    try expect(graph.hasNode(30));
    try expect(graph.hasNode(40));
    try expect(!graph.hasNode(50));

    // Remove middle node (index 1) -- Case 2)
    try graph.removeNode(30);
    nodes = graph.getNodes();
    try expect(nodes.len == 2);
    try expect(!graph.hasNode(10));
    try expect(graph.hasNode(20));
    try expect(!graph.hasNode(30));
    try expect(graph.hasNode(40));
    try expect(!graph.hasNode(50));
}

test "Graph: add edges" {
    const len = 8;
    const allocator = std.testing.allocator;
    var graph = Graph(u8, f16, len).init(allocator);
    defer graph.deinit();

    try graph.newNode(10);
    try graph.newNode(20);
    try graph.newNode(30);
    try graph.newNode(40);

    try expect(graph.getNodes().len == 4);

    try graph.newEdge(10, 20, null);
    try graph.newEdge(20, 10, null);
    try graph.newEdge(20, 30, null);

    try expect(graph.getEdges().len == 3);
}

test "Graph: remove edges" {
    const len = 8;
    const allocator = std.testing.allocator;
    var graph = Graph(u8, f16, len).init(allocator);
    defer graph.deinit();

    try graph.newNode(10);
    try graph.newNode(20);
    try graph.newNode(30);
    try graph.newNode(40);

    try expect(graph.getNodes().len == 4);

    try graph.newEdge(10, 20, null);
    try graph.newEdge(20, 10, null);
    try graph.newEdge(20, 30, null);
    try graph.newEdge(20, 40, null);
    try graph.newEdge(40, 20, null);

    try expect(graph.getEdges().len == 5);


    // Remove first edge (index 0) -- Case 1
    try graph.removeEdgeExact(10, 20);
    try expect(graph.getEdges().len == 4);
    try expect(!graph.hasEdgeExact(10, 20));
    try expect(graph.hasEdgeExact(20, 10));
    try expect(graph.hasEdgeExact(20, 30));
    try expect(graph.hasEdgeExact(20, 40));
    try expect(graph.hasEdgeExact(40, 20));

    // Remove last edge (index 4) -- Case 3
    try graph.removeEdgeExact(40, 20);
    try expect(graph.getEdges().len == 3);
    try expect(!graph.hasEdgeExact(10, 20));
    try expect(graph.hasEdgeExact(20, 10));
    try expect(graph.hasEdgeExact(20, 30));
    try expect(graph.hasEdgeExact(20, 40));
    try expect(!graph.hasEdgeExact(40, 20));

    // Remove middle edge (index 2) -- Case 2
    try graph.removeEdgeExact(20, 30);
    try expect(graph.getEdges().len == 2);
    try expect(!graph.hasEdgeExact(10, 20));
    try expect(graph.hasEdgeExact(20, 10));
    try expect(!graph.hasEdgeExact(20, 30));
    try expect(graph.hasEdgeExact(20, 40));
    try expect(!graph.hasEdgeExact(40, 20));

}

test "Graph: remove nodes and its edges automatically" {
    const len = 8;
    const alloc = std.testing.allocator;
    var graph = Graph(u8, f16, len).init(alloc);
    defer graph.deinit();

    try graph.newNode(1);
    try graph.newNode(2);
    try graph.newNode(3);

    try graph.newEdge(1,2, null);
    try graph.newEdge(2,3, null);
    try graph.newEdge(3,1, null);

    try expect(graph.getNodes().len == 3);
    try expect(graph.getEdges().len == 3);

    try graph.removeNode(1);
    try expect(graph.getNodes().len == 2);
    std.debug.print("Edges len: {}\n",.{graph.getEdges().len});
    try expect(graph.getEdges().len == 1);

    try expect(!graph.hasNode(1));
    try expect(graph.hasNode(2));
    try expect(graph.hasNode(3));

    try expect(!graph.hasEdgeExact(1,2));
    try expect(graph.hasEdgeExact(2,3));
    try expect(!graph.hasEdgeExact(3,1));

}
