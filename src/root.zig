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
        nodes: AutoHashMap(T, *Node),         //stores the nodes

        const Node = struct {
            value: T,
            nh: std.ArrayListAligned(*Edge, null),
        };

        const Edge = struct {
            next: *Node, 
            weight: ?W,
        };

        pub fn init(allocator: Allocator) Self {
            return Self {
                .allocator = allocator,
                .nodes = AutoHashMap(T, *Node).init(allocator),                
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
               .nh = try ArrayList(*Edge).initCapacity(self.allocator, CAPACITY), 
            };

            try self.nodes.put(value, node_ptr);

            return;
        }
        
        pub fn removeNode(self: *Self, value: T) !void {
            const node_ptr: *Node = try self.getNode(value);
            node_ptr.nh.clearAndFree();
            node_ptr.nh.deinit();
            self.allocator.destroy(node_ptr);
        }

        pub fn newEdge(self: *Self, from: T, to: T, weight: ?W) !void {
            var from_node = try self.getNode(from);
            const to_node = try self.getNode(to);
            if (self.hasEdge(from, to)) return GraphError.RepeatedEdgeInsertion;

            const edge_ptr: *Edge = try self.allocator.create(Edge);

            edge_ptr.* = .{
                .next = to_node,
                .weight = weight,
            };

            try from_node.nh.append(edge_ptr);
        }


        pub fn removeEdge(self: *Self, from: T, to: T) !void{
            const node: *Node = try self.getNode(from); // Node where the Edge to remove is stored
            for (0.., node.*.nh.items) |idx, edge| {
                if (edge.next.value == to) {
                    self.allocator.destroy(node.*.nh.swapRemove(idx));
                    return;
                }
            }

            return GraphError.EdgeNotFound;
        }

        pub fn hasEdge(self: Self, from: T, to: T) bool {
            const from_node = self.nodes.get(from) orelse return false;
            for(from_node.nh.items) |item| {
                if (item.next.value == to) return true;
            }

            return false;
        }

        pub fn getEdge(self:Self, from: T, to: T) !*Edge {
            const opt_from_node = self.nodes.get(from);
            if (opt_from_node) |*node| {
                for(node.*.nh.items) |edge| {
                    if (edge.next.value == to) return edge;
                }
            } 
            return GraphError.EdgeNotFound;
        }

        pub fn getEdgeIndex(self:Self, from: T, to: T) !usize {
            const opt_from_node = self.nodes.get(from);
            if (opt_from_node) |*node| {
                for(0..,node.*.nh.items) |i, edge| {
                    if (edge.next.value == to) return i;
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


