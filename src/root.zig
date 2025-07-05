const std = @import("std"); 
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const HashMap = std.HashMap;
const CAPACITY = 64;

pub const GraphError = error {
    NodeNotFound,
    EdgeNotFound,
    RepeatedNodeInsertion,
    RepeatedEdgeInsertion,
};
/// Graph implemenation in Zig that gives you the functionality
/// to do anything you'd like to do with a graph.
pub fn Graph(comptime T: type, comptime W: type) type {

    return struct {
        const Self = @This();

        /// How to allocate memory is up to the consumer. Zig style.
        allocator: Allocator,

        /// HashMap of all Nodes in the graph. 
        /// Instead of having a separate `edges` list each Node
        /// has two lists: the edges coming from them and edges going towards them.
        /// Check out below in the `Node` struct
        nodes: AutoHashMap(T, *Node),
        

        // el chatty diu una cosa intel·ligent: lo de tenir els punters de edges guardat a dues llistes dona problemes al fer-los-hi
        // free al deinit, si t'hi pares a pensar. És com que no queda clar qui té l'ownership dels punters. Ho podriem centralitzar
        // tot en una arraylist aquí dalt per fer l'alliberament més fàcil i seguir també guardant els problemes allà.

        /// Structure definition of a `Node`. 
        const Node = struct {
            value: T,
            edges_out: std.ArrayListAligned(*Edge, null), // Edges that comes from the actual node and goes to another node.
            edges_in: std.ArrayListAligned(*Edge, null), // Edges that goes towards the actual node from any other node.
        };


        /// Structure definition of an `Edge`.
        const Edge = struct {
            to: *Node, // The node where the edge is directed to.
            from: *Node, // The node where the edge comes from.
            weight: ?W, // Weight parameters. The `type` is computed at compilation time  It can be anything, and as such, it is also `Optional`
        };

        pub fn init(allocator: Allocator) Self {
            return Self {
                .allocator = allocator,
                .nodes = AutoHashMap(T, *Node).init(allocator),                
            };
        }
        
        pub fn deinit(self: *Self) void {
            var iterator = self.nodes.valueIterator();


            //TODO: Idea -> Why dont we just call `removeNode()` and pass the Node value?
            // PAU: those are two get on the hash, i felt it was better to just remove it all
            // no només felt better, cridar removeNode fa que això passi de O(n) a O(n*(hash access)). en canvi aquí no :(
            while (iterator.next()) |node| {
                //const node = entry.value_ptr.*;
                // TODO: no entenc perque això necessita 
                // la derreferència explícita, però això
                // passa tots els test, no memory leak
                for (node.*.edges_in.items) |edge_ptr| {
                    self.allocator.destroy(edge_ptr);
                } 
                
                // oju! si poses això estàs doble freeing!
                //for (node.*.edges_out.items) |edge_ptr| {
                //    self.allocator.destroy(edge_ptr);
                //}

                node.*.edges_in.deinit();
                node.*.edges_out.deinit();
                self.allocator.destroy(node.*);
            }

            self.nodes.deinit();
        }
        
        pub fn newNode(self: *Self, value: T) !void {
            
            if(self.nodes.contains(value)) {
                std.debug.print("No repeated values are allowed\n", .{});
                return GraphError.RepeatedNodeInsertion;
            } 
            const node_ptr: *Node = try self.allocator.create(Node);
            
            node_ptr.* = .{ 
                .value = value, 
                .edges_in = try ArrayList(*Edge).initCapacity(self.allocator, CAPACITY), 
                .edges_out = try ArrayList(*Edge).initCapacity(self.allocator, CAPACITY),
            };
            
            try self.nodes.put(value, node_ptr); 
        }
       
        /// Removes the Node with value `value` from the Graph.
        /// It also removes all the edges associated with that
        /// Node, either if they come from the Node or goes towards the Node.
        ///
        /// It checks the Node with value `value` exists.
        pub fn removeNode(self: *Self, value: T) !void {
            const node: *Node = try self.getNode(value);
            defer _ = self.nodes.remove(value); // delete from the dictionary
            
            // Remove all edges that comes from this node
            for (node.*.edges_out.items) |edge_ptr| {
                // Delete the out edges and remove them
                const to_value = edge_ptr.to.value;
                try self.removeEdge(value, to_value); //TODO: HECTOOOOOR lo de reutilizar funcions està molt bé però això no és O(n^2)??? en plan, per això jo ho feia manipulant directalement, això és bonic però tremendament ineficient
            }

            // Remove all edges that goes to this node
            for (node.*.edges_in.items) |edge_ptr| {
                const from_value = edge_ptr.from.value;

                // Notice how now the `value` is in the `to` position
                // when removing edges.
                // We want to remove the edge that points towards this node.
                try self.removeEdge(from_value, value); 
            }

            // delete the inner arraylist, with no elements 
            node.edges_in.deinit();
            node.edges_out.deinit();
            
            // delete the node
            self.allocator.destroy(node);

        }

        /// Creates a directed edge that goes from the Node with value `from` 
        /// and towards the Node with value `to`.
        ///
        /// It checks both `from` and `to` Nodes exist.
        ///
        /// It adds the edge in both nodes, this is to say:
        ///     - Adds it in the `edges_out` of the Node with value `from`.
        ///     - Adds it in the `edges_in` of the Node with value `to`.
        /// The edge is the same for both Nodes, it has the same reference.
        pub fn newEdge(self: *Self, from: T, to: T, weight: ?W) !void {
            var from_node = try self.getNode(from);
            var to_node = try self.getNode(to);

            // we check for the same edge in both nodes
            const has_edge: bool = try self.hasEdge(from,to);
            if (has_edge)  {
                std.debug.print("The edge {any}->{any} is already in the graph\n", .{from, to});
                return GraphError.RepeatedEdgeInsertion;
            } 

            // create requested edge with original direction
            const edge_ptr: *Edge = try self.allocator.create(Edge);

            edge_ptr.* = .{
                .from = from_node,
                .to = to_node,
                .weight = weight,
            };

            try from_node.edges_out.append(edge_ptr);
            try to_node.edges_in.append(edge_ptr);
        }

        // TODO: fer l'arraylist amb cerca binària per optimitzar-ho
        pub fn removeEdge(self: *Self, from: T, to: T) !void {
            const from_node: *Node = try self.getNode(from); // Node where the Edge to remove is stored
            var edge_inout: ?*Edge = null;
            var edge_outin: ?*Edge = null;

            for (0.., from_node.*.edges_out.items) |idx, edge| {
                if (edge.to.value == to) {
                    edge_inout = from_node.*.edges_out.swapRemove(idx);
                    break;
                }
            }
            
            // if edge is not in from->to, then it is not in the to->from 
            if (edge_inout == null) return GraphError.EdgeNotFound;
            
            const to_node: *Node = try self.getNode(to); // Node where the Edge to remove is stored
            for (0.., to_node.*.edges_in.items) |idx, edge| {
                // Let's remove only THE SAME edge in terms of reference.
                if (edge == edge_inout) {
                    edge_outin = to_node.*.edges_in.swapRemove(idx);
                    break;
                }
            }
            
            if (edge_outin == edge_inout) {
                self.allocator.destroy(edge_outin.?);
            }

        }

        pub fn hasEdge(self: Self, from: T, to: T) !bool {
            const from_node = try self.getNode(from);
            for(from_node.edges_out.items) |edge| {
                if (edge.to.value == to) return true;
            }

            return false;
        }

        pub fn getEdge(self:Self, from: T, to: T) !*Edge {
            const opt_from_node = self.getNode(from);
            if (opt_from_node) |*node| {
                for(node.*.edges_out.items) |edge| {
                    if (edge.to.value == to) return edge;
                }
            } 
            return GraphError.EdgeNotFound;
        }

        fn getEdgeIndex(self:Self, from: T, to: T) !usize {
            const opt_from_node = self.getNode(from);
            if (opt_from_node) |*node| {
                for(0..,node.*.edges_out.items) |i, edge| {
                    if (edge.to.value == to) return i;
                }
            } 
            return GraphError.EdgeNotFound;
        }

        fn getNode(self: Self, value: T) !*Node {
            const node_ptr: ?*Node = self.nodes.get(value);
            if (node_ptr) |node| {
                return node;
            }
            else return GraphError.NodeNotFound;
        }
    };
}


// TODO: I think we should change the way we focus our test
// and try to use the "zig" way. Take a look at how the std.ArrayList does the test.
// Instead of focusing on cases, it focus on functions. From the basics to the most complex.
// For example a test could be "Graph.init", or "Graph.newNode()".
//
//
// like:
// 1. init
// 2. deinit
// 3. addNode -> multiple instances checking if the node has actually appended. check the error
// 4. addEdge -> check if actually the edge is correct. check the duplicate error
// 5. hasEdge -> check if some are actually there. check the not found error
// 6. removeNode -> check if all the edges and nodes are actually deleted
// 7. removeEgde -> check if all the edges are deleted.

const testing = std.testing;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

test "init" {
    {
        var graph = Graph(u32, f16).init(std.testing.allocator);
        defer graph.deinit();

        // list should be at zero capacity
        try expect(graph.nodes.count() == 0); 
    }

}

test "addNodes" {
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);

        const node = graph.nodes.get(1);
        try expect(node != null);
        try expectEqual(node.?.value, 1);
        try expectEqual(node.?.edges_in.items.len, 0);
        try expectEqual(node.?.edges_out.items.len, 0);
    }
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try expectError(GraphError.RepeatedNodeInsertion, graph.newNode(1));
    }
    {   // insert lots of nodes
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit(); 
        const nodes = [_]u32{1,2,3,4,5,6,7,8,9,0};
        
        for (nodes) |i| {
            try graph.newNode(i);
        }
    }
}

test "removeNodes" {
    {
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.removeNode(1);

        const node = graph.nodes.get(1);
        try expect(node == null);
        try expect(graph.nodes.count() == 0);
    }
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try expectError(GraphError.NodeNotFound, graph.removeNode(1));
        try expect(graph.nodes.count() == 0);
    }
    {
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit(); 
        const nodes = [_]u32{1,2,3,4,5,6,7,8,9,0};

        for (nodes) |i| {
            try graph.newNode(i);
        }

        for (nodes) |i| {
            try graph.removeNode(i);
        }
    }
}

test "newEdge" {
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.newNode(2);

        try graph.newEdge(1,2,null);
        
        const node1 = graph.nodes.get(1);
        const node2 = graph.nodes.get(2);

        try expect(node1.?.edges_in.items.len == 0);
        try expect(node1.?.edges_out.items.len == 1);
        try expect(node2.?.edges_in.items.len == 1);
        try expect(node2.?.edges_out.items.len == 0);

    }
    { //from yourelf to yourself
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);

        try graph.newEdge(1,1,null);
        
        const node1 = graph.nodes.get(1);

        try expect(node1.?.edges_in.items.len == 1);
        try expect(node1.?.edges_out.items.len == 1);
    }
    { // non exising nodes -> node not found 
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.newNode(2);

        const node1 = graph.nodes.get(1);

        try expectError(GraphError.NodeNotFound, graph.newEdge(1,3,null));
        try expect(node1.?.edges_in.items.len == 0);
        try expect(node1.?.edges_out.items.len == 0);
    }
 
}

test "removeEdge" {
    { // remove a normal edge
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.newNode(2);
        try graph.newEdge(1,2,null);
        
        try graph.removeEdge(1,2);
        
        const node1 = graph.nodes.get(1);
        const node2 = graph.nodes.get(2);
        
        try expect(node1.?.edges_in.items.len == 0);
        try expect(node1.?.edges_out.items.len == 0);
        try expect(node2.?.edges_in.items.len == 0);
        try expect(node2.?.edges_out.items.len == 0);
    }
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);

        try graph.newEdge(1,1,null);
        try graph.removeEdge(1,1);

        const node1 = graph.nodes.get(1);
        
        try expect(node1.?.edges_in.items.len == 0);
        try expect(node1.?.edges_out.items.len == 0);
    }
    { // remove an Edge with a non existing node 
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit();

        try expectError(GraphError.NodeNotFound, graph.removeEdge(1,2));
    }
    { // remove an non existing edge
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit();
        
        try graph.newNode(1);
        try graph.newNode(2);
        
        try expectError(GraphError.EdgeNotFound, graph.removeEdge(1,2));
    }
}

test "hasEdge" {
    { 
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.newNode(2);
        try graph.newEdge(1,2,null);
        
        const b = try graph.hasEdge(1,2); 
        try expect(b);
        
    }
    {
        const talloc = std.testing.allocator;
        var graph = Graph(u32, f16).init(talloc);
        defer graph.deinit();

        try graph.newNode(1);
        try graph.newNode(2);
        try graph.newEdge(2,1,null);
       
        const b = try graph.hasEdge(1,2); 
        try expect(!b);
    }
    { // remove an Edge with a non existing node 
        var graph = Graph(u32, f16).init(testing.allocator);
        defer graph.deinit();
    
        try expectError(GraphError.NodeNotFound, graph.hasEdge(1,2));
    }
}


