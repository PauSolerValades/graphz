const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const HashMap = std.HashMap;

pub const GraphError = error {
    NodeNotFound,
    EdgeNotFound,
};

pub fn Graph(comptime T: type, comptime W: type) type {

    return struct {
        const Self = @This();

        allocator: Allocator,
        nodes: AutoHashMap(T, Node),         //stores the nodes

        const Node = struct {
            value: T,
            nh: ArrayList(Edge),
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


    };
}


