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
};

pub fn Graph(comptime T: type, comptime W: type) type {

    return struct {
        const Self = @This();

        allocator: Allocator,
        nodes: AutoHashMap(T, Node),         //stores the nodes

        const Node = struct {
            value: T,
            nh: std.ArrayListAligned(Edge, null),
        };

        const Edge = struct {
            next: *Node, 
            weight: ?W,
        };

        pub fn init(allocator: Allocator) Self {
            return Self {
                .allocator = allocator,
                .nodes = AutoHashMap(T, Node).init(allocator),                
            };
        }
        
        pub fn newNode(self: *Self, value: T) !void {
            
            if(self.nodes.contains(value)) {
                std.debug.print("No repeated values are allowed\n", .{});
                return GraphError.RepeatedNodeInsertion;
            } 
            const node_ptr: *Node = try self.allocator.create(Node);

            node_ptr.* = .{
               .value = value,
               .nh = try ArrayList(Edge).initCapacity(self.allocator, CAPACITY), 
            };

            try self.nodes.put(value, node_ptr.*);

            return;
        }

        pub fn newEdge(self: *Self, from: T, to: T, weight: ?W) !void {
            var from_node = try self.getNode(from);
            const to_node = try self.getNode(to);

            const edge_ptr: *Edge = try self.allocator.create(Edge);
            edge_ptr.* = .{
                .next = to_node,
                .weight = weight,
            };

            try from_node.nh.append(edge_ptr.*);

        }

        fn getNode(self: Self, value: T) !*Node {
            const node_ptr: ?*Node = self.nodes.getPtr(value);
            if (node_ptr) |node| {
                return node;
            }
            else return GraphError.NodeNotFound;

        }

    };
}


