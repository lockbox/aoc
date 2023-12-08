const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day08.txt");
const TEST_PART1_DATA =
    \\RL
    \\
    \\AAA = (BBB, CCC)
    \\BBB = (DDD, EEE)
    \\CCC = (ZZZ, GGG)
    \\DDD = (DDD, DDD)
    \\EEE = (EEE, EEE)
    \\GGG = (GGG, GGG)
    \\ZZZ = (ZZZ, ZZZ)
;

const TEST_PART2_DATA =
    \\LR
    \\
    \\11A = (11B, XXX)
    \\11B = (XXX, 11Z)
    \\11Z = (11B, XXX)
    \\22A = (22B, XXX)
    \\22B = (22C, 22C)
    \\22C = (22Z, 22Z)
    \\22Z = (22B, 22B)
    \\XXX = (XXX, XXX)
;

const LRNode = struct {
    left: []const u8,
    right: []const u8,
};

const Puzzle = struct {
    directions: []const u8,
    nodes: StrMap(LRNode),
    next_idx: usize = 0,

    inline fn nextDirection(self: *Puzzle) u8 {
        const val = self.directions[self.next_idx];
        self.next_idx = (self.next_idx + 1) % self.directions.len;

        return val;
    }
};

fn getPuzzle(data: []const u8) !Puzzle {
    var iterator = tokenizeSca(u8, data, '\n');
    var nodes: StrMap(LRNode) = StrMap(LRNode).init(gpa);

    // first line is the directions
    const directions = iterator.next().?;

    // now parse all the nodes
    while (iterator.next()) |line| {
        // get the node, and add it
        const new_node = line[0..3];
        const l_node = line[7..10];
        const r_node = line[12..15];

        try nodes.put(new_node, .{ .left = l_node, .right = r_node });
    }

    return Puzzle{
        .directions = directions,
        .nodes = nodes,
    };
}

fn part1(p: *Puzzle) !usize {
    var current_node = p.nodes.getEntry("AAA").?;
    var steps: usize = 0;

    while (!std.mem.eql(u8, current_node.key_ptr.*, "ZZZ")) {
        const path_choices = current_node.value_ptr;

        // follow the directions
        const next_direction = p.nextDirection();
        current_node = if (next_direction == 'L') blk: {
            break :blk p.nodes.getEntry(path_choices.left).?;
        } else if (next_direction == 'R') blk: {
            break :blk p.nodes.getEntry(path_choices.right).?;
        } else {
            unreachable;
        };

        steps += 1;
    }

    return steps;
}

fn allEndZ(l: *const List(StrMap(LRNode).Entry)) bool {
    for (l.items) |entry| {
        if (entry.key_ptr.*[2] != 'Z') {
            return false;
        }
    }

    return true;
}

inline fn updateCurrentNodes(p: *Puzzle, l: *List(StrMap(LRNode).Entry)) void {
    const direction = p.nextDirection();
    var i: usize = 0;

    while (i < l.items.len) {
        const entry_idx = i;
        const entry = l.items[entry_idx];
        const value = entry.value_ptr;
        const key = entry.key_ptr;

        if (key.*[2] == 'Z' and value.left[2] == 'Z' and value.right[2] == 'Z') {
            print("Node{{p: `{s}`, L: `{s}`, R: `{s}`}}\n", .{key.*, value.left, value.right},);
            _ = l.swapRemove(entry_idx);
            continue;
        }

        if (direction == 'L') {
            l.items[entry_idx] = p.nodes.getEntry(value.left).?;
        } else if (direction == 'R') {
            l.items[entry_idx] = p.nodes.getEntry(value.right).?;
        } else {
            unreachable;
        }

        i += 1;
    }
}

fn initStartNodes(p: *const Puzzle, l: *List(StrMap(LRNode).Entry)) !void {
    var keys = p.nodes.keyIterator();

    while (keys.next()) |key| {
        if (key.*[2] == 'A') {
            try l.append(p.nodes.getEntry(key.*).?);
        }
    }

    print("`{}` Concurrent search paths\n", .{l.items.len});
}

fn lcm(a: usize, b: usize) usize {
    return (a * b) / std.math.gcd(a,b);
}

fn lcmMany(list: []usize) usize {
    var out: usize = list[0];
    var idx: usize = 1;

    while (idx < list.len) {
        const num1 = out;
        const num2 = list[idx];

        const out_lcm = lcm(num1, num2);
        out = out_lcm;

        idx += 1;
    }

    return out;
}

// 15746133679061
fn part2(p: *Puzzle) !usize {
    var current_nodes = List(StrMap(LRNode).Entry).init(gpa);
    defer current_nodes.deinit();
    var steps: usize = 0;

    try initStartNodes(p, &current_nodes);
    var thread_steps: []usize = try gpa.alloc(usize, current_nodes.items.len);
    defer gpa.free(thread_steps);

    // keep following directions until all Z
    while (!allEndZ(&current_nodes)) {
        // now update
        updateCurrentNodes(p, &current_nodes);
        steps += 1;

        // if a node is at Z, call it done and remove it at step count
        var i: usize = 0;
        while (i < current_nodes.items.len) {
            const node = current_nodes.items[i];

            if (node.key_ptr.*[2] == 'Z') {
                thread_steps[thread_steps.len - current_nodes.items.len] = steps;
                _ = current_nodes.swapRemove(i);
                continue;
            }

            i += 1;
        }


    }

    // we have the exits of all threads, so now lcm them to find their exit cycle
    for (thread_steps) |s| {
        print("Got s: `{}`\n", .{s});
    }
    const answer = lcmMany(thread_steps);

    return answer;
}

pub fn main() !void {
    var test_part1_puzzle = try getPuzzle(TEST_PART1_DATA);
    var test_part2_puzzle = try getPuzzle(TEST_PART2_DATA);
    var real_puzzle = try getPuzzle(DATA);

    print("[Test Data] Part 1: `{}`\n", .{try part1(&test_part1_puzzle)});
    print("[Real Data] Part 1: `{}`\n", .{try part1(&real_puzzle)});
    print("[Test Data] Part 2: `{}`\n", .{try part2(&test_part2_puzzle)});
    print("[Real Data] Part 2: `{}`\n", .{try part2(&real_puzzle)});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
