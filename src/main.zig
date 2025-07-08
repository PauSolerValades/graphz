const std = @import("std");
const Graph = @import("graphz_lib");
const algorithms = @import("algorithms.zig");

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
    try std.testing.expectError(Graph.GraphError.NodeNotFound, graph.hasEdge(4,1));
    
    // neighbors of 1 
    const n1 = try graph.getNeighbors(allocator, 1); // 1,2,3
    defer allocator.free(n1);
    
    // can also be asked without dynamic memory
    var buffer: [10]u16 = undefined;
    const n1_buff = try graph.getNeighborsBuffer(&buffer, 1);
    try std.testing.expectEqualSlices(u16, n1_buff, &[_]u16{1,2,3});

    // remove edge 2->3. Retuns null as the struct is void
    _ = try graph.removeEdge(2,3);
    
    // remove node 2. this removes all the nodes to 2 and out from 2
    _ = try graph.removeNode(1);
    _ = try graph.hasEdge(1,1); //false
    _ = try graph.hasEdge(1,2); //false
    _ = try graph.hasEdge(1,3); //false 
    
    try algorithms.dijkstra(graph, Graph.DijkstraOptions, 1);

}

















