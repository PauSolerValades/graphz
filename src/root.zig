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

pub fn Graph(comptime T: type, comptime W: type) type {

    return struct {
        const Self = @This();

        allocator: Allocator,
        nodes: AutoHashMap(T, *Node),

        const Node = struct {
            value: T,
            edges_out: std.ArrayListAligned(*Edge, null),
            edges_in: std.ArrayListAligned(*Edge, null),
        };

        const Edge = struct {
            to: *Node, 
            weight: ?W,
        };

        pub fn init(allocator: Allocator) Self {
            return Self {
                .allocator = allocator,
                .nodes = AutoHashMap(T, *Node).init(allocator),                
            };
        }
        
        pub fn deinit(self: *Self) void {
            var iterator = self.nodes.valueIterator();
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
            
            // manage some allocator fail state freeing all available memory 
            errdefer {
                node_ptr.edges_in.deinit();
                node_ptr.edges_out.deinit();
                self.allocator.destroy(node_ptr); 
            }
            
            node_ptr.* = .{ 
                .value = value, 
                .edges_in = try ArrayList(*Edge).initCapacity(self.allocator, CAPACITY), 
                .edges_out = try ArrayList(*Edge).initCapacity(self.allocator, CAPACITY),
            };
            
            try self.nodes.put(value, node_ptr);

        }
        
        pub fn removeNode(self: *Self, value: T) !void {
            const node: *Node = try self.getNode(value);
            defer _ = self.nodes.remove(value); // delete from the dictionary
            
            // delete all the references arriving to this node
            // this will also delete all the references going into the node           
            for (node.*.edges_in.items) |edge_ptr| {
                self.allocator.destroy(edge_ptr);
            }
            node.edges_in.deinit();

            // delete the outer arraylist, with nothing
            node.edges_out.deinit();
            
            // delete the node
            self.allocator.destroy(node);

        }

        pub fn newEdge(self: *Self, from: T, to: T, weight: ?W) !void {
            var from_node = try self.getNode(from);
            var to_node = try self.getNode(to);

            // we check for the same edge in both nodes
            if (self.hasEdge(from, to))  {
                std.debug.print("The edge {any}->{any} is already in the graph\n", .{from, to});
                return GraphError.RepeatedEdgeInsertion;
            } 
            // create requested edge with original direction
            const edge_ptr: *Edge = try self.allocator.create(Edge);

            edge_ptr.* = .{
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
                if (edge.to.value == to) {
                    edge_outin = to_node.*.edges_in.swapRemove(idx);
                    break;
                }
            }
            
            if (edge_outin == edge_inout) {
                self.allocator.destroy(edge_outin.?);
            }

        }

        pub fn hasEdge(self: Self, from: T, to: T) bool {
            const from_node = self.nodes.get(from) orelse return false;
            for(from_node.edges_out.items) |edge| {
                if (edge.to.value == to) return true;
            }

            return false;
        }

        pub fn getEdge(self:Self, from: T, to: T) !*Edge {
            const opt_from_node = self.nodes.get(from);
            if (opt_from_node) |*node| {
                for(node.*.edges_out.items) |edge| {
                    if (edge.to.value == to) return edge;
                }
            } 
            return GraphError.EdgeNotFound;
        }

        pub fn getEdgeIndex(self:Self, from: T, to: T) !usize {
            const opt_from_node = self.nodes.get(from);
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

const except = std.testing.except;

test "Graph: init and deinit empty graph" {
    const talloc = std.testing.allocator;
    var graph = Graph(u8, f16).init(talloc);
    defer graph.deinit(); 
}

test "Graph: Adding and removing node" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    try graph.newNode(1);
    try graph.removeNode(1);
    
     
}

test "Graph: deinit non empty graph" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    try graph.newNode(1);
 
}

test "Graph: adding and removing multiple nodes" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    const nodes = [_]u32{1,2,3,4,5,6,7,8,9,0};

    for (nodes) |i| {
        try graph.newNode(i);
    }
    
    for (nodes) |i| {
        try graph.removeNode(i);
    }
} 

test "Graph: adding and not removing multiple nodes" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    const nodes = [_]u32{1,2,3,4,5,6,7,8,9,0};

    for (nodes) |i| {
        try graph.newNode(i);
    }
}

test "Graph: adding and removing edge" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    try graph.newNode(1);
    try graph.newNode(2);

    try graph.newEdge(1,2,null);
    try graph.removeEdge(1,2);
}

test "Graph: adding and not removing edge" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    try graph.newNode(1);
    try graph.newNode(2);

    try graph.newEdge(1,2,null);
}

test "Graph: complete two node graph" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();
    
    try graph.newNode(1);
    try graph.newNode(2);
    
    try graph.newEdge(1,2, null);
    try graph.newEdge(2,1, null);
}

test "Graph: auto-complete two node graph" {
     const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();
    
    try graph.newNode(1);
    try graph.newNode(2);
    
    try graph.newEdge(1,2, null);
    try graph.newEdge(2,1, null);
    try graph.newEdge(1,1, null);
    try graph.newEdge(2,2, null);
}

// aquest test no va lmao!
test "Graph: delete edges associated to a node" {
     const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();
    
    try graph.newNode(1);
    try graph.newNode(2);
    
    try graph.newEdge(1,2, null);
    try graph.newEdge(2,1, null);
    try graph.newEdge(1,1, null);
    try graph.newEdge(2,2, null);

    try graph.removeNode(2);
    
    try std.testing.expectEqual(graph.nodes.get(1).?.edges_in.items.len, 1);
    try std.testing.expectEqual(graph.nodes.get(1).?.edges_out.items.len, 1);
    try std.testing.expect(!graph.hasEdge(1, 2));
    try std.testing.expect(!graph.hasEdge(2, 1));
    try std.testing.expect(!graph.hasEdge(2, 2));

    try std.testing.expect(graph.hasEdge(1, 1));
}

test "Graph: 10-node autocomplete graph" {
    const talloc = std.testing.allocator;
    var graph = Graph(u32, f16).init(talloc);
    defer graph.deinit();

    const nodes = [_]u32{1,2,3,4,5,6,7,8,9,0};

    for (nodes) |i| {
        try graph.newNode(i);
    }
    
    for (nodes, 0..) |i_node, i| {
        for (nodes[i + 1..]) |j_node| {
            try graph.newEdge(i_node, j_node, null);
            try graph.newEdge(j_node, i_node, null);
        }
    }   
} 

//TODO: missing tests:
// 1. errors: duplicated nodes, duplicated edges
// 2. errors: node and edge not found on removal
// 3. node removal with existing edges (kinda done but does not work)
// 4.
