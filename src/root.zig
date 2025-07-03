const std = @import("std");
const Allocator = std.mem.Allocator;

pub const GraphError = error {
    NodeNotFound,
    EdgeNotFound,
};

pub fn Graph(comptime T: type, comptime W: type, comptime capacity: u32) type {

    return struct {
        const Self = @This();

        allocator: Allocator,
        node_count: usize,
        edge_count: usize,
        nodes: [capacity]*Node,
        edges: [capacity]*Edge,

        const Node = struct {
            id: usize,
            value: T,
        };

        const Edge = struct {
            from: *Node,
            to: *Node,
            weight: ?W,
        };



        pub fn init(allocator: Allocator) Self {
            return Self {
                .allocator = allocator,
                .nodes = undefined,
                .edges = undefined,
                .node_count = 0,
                .edge_count = 0,
            };
        }

        pub fn deinit(self: Self) void {
            for (0..self.edge_count) |i| {
                self.allocator.destroy(self.edges[i]);
            }
            for (0..self.node_count) |i| {
                self.allocator.destroy(self.nodes[i]);
            }
        }

        pub fn newNode(self: *Self, value: T) error{IndexOutOfBounds, OutOfMemory}!void {
            
            if (self.nodes.len <= self.node_count) return error.IndexOutOfBounds;
            
            // create és la funció que voliem, no alloc
            const node_ptr: *Node = try self.allocator.create(Node);
            
            node_ptr.* = .{
                .id = self.node_count,
                .value = value,
            };

            self.nodes[self.node_count] = node_ptr;
            self.node_count += 1;
        }

        fn getNodeByValue(self: Self, value: T) !usize{
            for (0..self.node_count) |i| {
                const node = self.nodes[i];
                if (node.value == value) {
                    return i;
                }
            }

            return GraphError.NodeNotFound;
        }

        pub fn getNodes(self: *Self) []*Node {
            return self.nodes[0..self.node_count];
        }


        pub fn newEdge(self: *Self, value_from: T, value_to: T, weight: ?W) !void {

            if (self.edges.len <= self.edge_count) return error.IndexOutOfBounds; 
            const node_from = try self.getNodeByValue(value_from);
            const node_to = try self.getNodeByValue(value_to);

            const edge_ptr: *Egde = try self.allocator.create(Edge);
            
            edge_ptr.from = self.nodes[node_from];
            edge_ptr.to = self.nodes[node_to];

            edge_ptr.weight = null;

            if (weight) |w| {
                edge_ptr.weight = w;
            }

            self.edges[self.edge_count] = edge_ptr;

            self.edge_count += 1;
        }

        fn getEdgeExact(self: Self, value_from : T, value_to: T) !usize {
            for(0..self.edge_count) |i| {
                const edge = self.edges[i];
                if (edge.from.value == value_from and edge.to.value == value_to) 
                    return i;
            }

            return GraphError.EdgeNotFound;
        }

        fn getEdge(self: Self, value: T) !usize {
            for (0..self.edge_count) |i| {
                const edge = self.edges[i];
                if (edge.from.value == value or edge.to.value == value)
                    return i;
            }
            return GraphError.EdgeNotFound;
        }

        pub fn removeEdgeExact(self: *Self, value_from: T, value_to: T ) !void {

            const edge_index = try self.getEdgeExact(value_from, value_to);  // test
            if (edge_index < self.edge_count) {

                // 1) Para este caso es facil. Copias hacia delante al principio y ya esta.
                // [ 0 ... count]
                //   ^
                //
                //  2) Hay que copiar la array [indice + 1..count] en la subarray [indice.. count-1]
                // [ 0 .. index .. count ]
                //         ^
                //
                //         Mirando en retrospectiva el caso 1) y 2) son lo mismo!
                //
                //  3) El mas facil, simplemente restas la cantidad que hay y lo "eliminas"
                // [ 0 ... len ]
                //          ^

                // Primero liberamos la memoria.
                self.allocator.destroy(self.edges[edge_index]);

                // copyForwards(type, dest, source) copia los valores de
                // source en dest. Aunque haya overlapping no pasa nada.
                std.mem.copyForwards(
                    *Edge,
                    self.edges[edge_index.. self.edge_count-1],
                    self.edges[edge_index + 1.. self.edge_count],
                );
            }

            self.edge_count -= 1;
        }

        pub fn removeEdge(self: *Self, value: T ) !void {
            const edge_index = try self.getEdge(value);
            if (edge_index < self.edge_count) {
                self.allocator.destroy(self.edges[edge_index]);
                std.mem.copyForwards(
                    *Edge,
                    self.edges[edge_index..self.edge_count - 1],
                    self.edges[edge_index + 1..self.edge_count],

                );
            }
            self.edge_count -= 1;
        }

        pub fn removeNode(self: *Self, value: T) !void {
            const node_index = try self.getNodeByValue(value);

            // Delete all edges
            const node_value = self.nodes[node_index].value;
            while (self.hasEdge(node_value)) {
                try self.removeEdge(node_value);
            }

            if (node_index < self.node_count) {
                // Liberamos la memoria
                self.allocator.destroy(self.nodes[node_index]);

                // Restructuramos la array
                std.mem.copyForwards(
                    *Node,
                    self.nodes[node_index .. self.node_count - 1 ],
                    self.nodes[node_index + 1 .. self.node_count],
                );
            }
            self.node_count -= 1;

        }

        pub fn hasNode(self: Self, value: T) bool {
            for (0..self.node_count) |i| {
                if (self.nodes[i].value == value)
                    return true;
            }

            return false;
        }

        pub fn hasEdgeExact(self: Self, value_from: T, value_to: T) bool {
            for (0..self.edge_count) |i| {
                const edge = self.edges[i];
                if (edge.from.value == value_from and edge.to.value == value_to)
                    return true;
            }
            return false;
        }

        pub fn hasEdge(self: Self, value: T) bool {
            for (0..self.edge_count) |i| {
                const edge = self.edges[i];
                if (edge.from.value == value or edge.to.value == value)
                    return true;
            }
            return false;
        }

        fn printNodes(self: Self) void {
            for (0..self.node_count) |i| {
                const node = self.nodes[i];
                std.debug.print("Node in position {} has id {} and value {}\n", .{i, node.id, node.value});
            }
        }

        fn printEdges(self: Self) void {
            for (0..self.edge_count) |i| {
                const edge = self.edges[i];
                std.debug.print("Edge in position {} goes from {} to {}\n", .{i, edge.from, edge.to});
            }
        }

        pub fn printGraph(self: Self) void {
            self.printNodes();
            self.printEdges();
        }

        pub fn getEdges(self: *Self) []*Edge {
            return self.edges[0..self.edge_count];
        }
    };
}


