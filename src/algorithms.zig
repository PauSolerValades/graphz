const std = @import("std");
const Graph = @import("graphz_lib");

// aquest patró és increïble
// Col·loques les funcions que vols usar per a obtenir les coses
// en un struct d'opcions, i després les fas servir amb aquella crida
pub const DijkstraOptions = struct {
    get_weight: fn (edge_payload: anytype) anyerror!f64,
//    get_distance: fn (node_payload: anytype) anyerror!f64,
//    set_data: fn (node_payload: anytype, distance: f64, predecessor: anytype) anyerror!void,
};

pub const WeightedEdge = struct { weight: f64 };
pub const DijkstraNode = struct { distance: f64, prev: ?u32 };

pub fn get_weight(egde: WeightedEdge) f64 {
    return edge.payload.weight;
}

pub const dijkstra_options = DijkstraOptions {
    .get_weight = get_weight,
//    .get_distance = |payload: DijkstraNode| payload.distance,
//    .set_data = |payload: *DijkstraNode, d, p| { payload.dist = d; payload.prev = p; },
};


pub fn dijkstra(
    graph: anytype, 
    comptime options: DijkstraOptions,
    start_node: anytype,
) !void {

    const weight = try options.get_weight(edge);
    std.debug.print("{f}\n", .{weight});
    try options.set_data(node_payload, new_dist, predecessor_id);
}

// hauriem d'implementar això per veure realment quines opcions ens falten a la API concretament
