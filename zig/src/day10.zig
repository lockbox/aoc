const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day10.txt");
const TEST_DATA =
    \\7-F7-
    \\.FJ|7
    \\SJLL7
    \\|F--J
    \\LJ.LJ
;

const TEST_PART2_DATA =
    \\.F----7F7F7F7F-7....
    \\.|F--7||||||||FJ....
    \\.||.FJ||||||||L7....
    \\FJL7L7LJLJ||LJ.L-7..
    \\L--J.L7...LJS7F-7L7.
    \\....F-J..F7FJ|L7L7L7
    \\....L7.F7||L7|.L7L7|
    \\.....|FJLJ|FJ|F7|.LJ
    \\....FJL-7.||.||||...
    \\....L---J.LJ.LJLJ...
;

const PathError = error{
    BadDirection,
};
const Coor = struct {
    x: usize,
    y: usize,

    fn dirFromCoor(self: *const Coor, other: *const Coor) Direction {
        if (self.x == other.x) {
            if (self.y > other.y) {
                return .south;
            } else {
                return .north;
            }
        } else if (self.y == other.y) {
            if (self.x > other.x) {
                return .west;
            } else {
                return .east;
            }
        } else {
            @panic("no common axes between coordinates");
        }
    }

    fn applyDir(self: *Coor, dir: Direction) !void {
        switch (dir) {
            .north => switch (self.y) {
                0 => return error.OverFlow,
                else => self.y -= 1,
            },
            .south => self.y += 1,
            .east => self.x += 1,
            .west => switch (self.x) {
                0 => return error.Overflow,
                else => self.x -= 1,
            },
            else => unreachable,
        }
    }
};
const Direction = enum {
    south,
    north,
    east,
    west,
    none,
};

const Pipe = enum(u8) {
    @"|",
    @"-",
    L,
    J,
    @"7",
    F,
    @".",
    S,

    fn fromU8(d: u8) Pipe {
        return switch (d) {
            '|' => .@"|",
            '-' => .@"-",
            'L' => .L,
            'J' => .J,
            '7' => .@"7",
            'F' => .F,
            '.' => .@".",
            'S' => .S,
            else => unreachable,
        };
    }

    // which direction you came from will tell you where to go next
    fn nextDirection(self: *const Pipe, d: *const Direction) Direction {
        return switch (self.*) {
            .@"|" => switch (d.*) {
                .north => .north,
                .south => .south,
                else => unreachable,
            },
            .J => switch (d.*) {
                .south => .west,
                .east => .north,
                else => unreachable,
            },
            .@"-" => switch (d.*) {
                .east => .east,
                .west => .west,
                else => unreachable,
            },
            .L => switch (d.*) {
                .south => .east,
                .west => .north,
                else => unreachable,
            },
            .@"7" => switch (d.*) {
                .north => .west,
                .east => .south,
                else => unreachable,
            },
            .F => switch (d.*) {
                .north => .east,
                .west => .south,
                else => unreachable,
            },
            .@"." => .none,
            .S => .none,
        };
    }
};

fn validNeighborPipes(start: *const Coor, board: *const List([]Pipe)) List(Coor) {
    var valid_neighbors = List(Coor).init(gpa);

    // above (north)
    if (start.y > 0) {
        const prev = board.items[start.y - 1][start.x];
        if (prev == .@"|" or prev == .@"7" or prev == .F) {
            valid_neighbors.append(Coor{ .x = start.x, .y = start.y - 1 }) catch @panic("OOM");
        }
    }

    // below (south)
    if (start.y < board.items.len - 1) {
        const prev = board.items[start.y + 1][start.x];
        if (prev == .@"|" or prev == .L or prev == .J) {
            valid_neighbors.append(Coor{ .x = start.x, .y = start.y + 1 }) catch @panic("OOM");
        }
    }

    // left (west)
    if (start.x > 0) {
        const prev = board.items[start.y][start.x - 1];
        if (prev == .@"-" or prev == .L or prev == .F) {
            valid_neighbors.append(Coor{ .x = start.x - 1, .y = start.y }) catch @panic("OOM");
        }
    }

    // right (east)
    if (start.x < board.items[0].len - 1) {
        const prev = board.items[start.y][start.x + 1];
        if (prev == .@"-" or prev == .J or prev == .@"7") {
            valid_neighbors.append(Coor{ .x = start.x + 1, .y = start.y }) catch @panic("OOM");
        }
    }

    return valid_neighbors;
}

fn findLoop(start: *const Coor, board: *const List([]Pipe)) List(Coor) {
    const start_paths = validNeighborPipes(start, board);
    defer start_paths.deinit();

    for (start_paths.items) |coor| {
        var path = List(Coor).init(gpa);
        path.append(Coor{ .x = start.x, .y = start.y }) catch @panic("OOM");

        var path_dir = coor.dirFromCoor(start);
        var location: Coor = .{ .x = start.x, .y = start.y };
        //print("Start{{ .x={}, .y={} }}\n", .{ start.x, start.y });
        //print("Start direction: {}\n", .{path_dir});

        while (path_dir != .none) {
            location.applyDir(path_dir) catch break;
            path.append(Coor{ .x = location.x, .y = location.y }) catch @panic("OOM");

            // get next direction
            path_dir = board.items[location.y][location.x].nextDirection(&path_dir);
        }

        // we hit a `.` or `S`
        if (board.items[location.y][location.x] == .S) {
            return path;
        } else {
            path.deinit();
        }
    } else {
        return List(Coor).init(gpa);
    }
}

fn part1(data: []const u8) !usize {
    var board = List([]Pipe).init(gpa);
    var iterator = tokenizeSca(u8, data, '\n');
    var start: ?Coor = null;

    var y: usize = 0;

    while (iterator.next()) |line| {
        var pipes = try gpa.alloc(Pipe, line.len);
        errdefer gpa.free(pipes);
        var x: usize = 0;

        for (line) |c| {
            pipes[x] = Pipe.fromU8(c);

            if (c == 'S') {
                start = Coor{ .x = x, .y = y };
            }

            x += 1;
        }

        try board.append(pipes);
        // inc counters
        y += 1;
    }

    if (start == null) @panic("no start");

    // now traverse in all pipe directions from start
    const path = findLoop(&start.?, &board);
    defer path.deinit();

    for (board.items) |l| {
        gpa.free(l);
    }

    // don't tcount the start
    const path_len = path.items.len - 1;
    return path_len / 2;
}

fn part2(data: []const u8) !usize {
    var board = List([]Pipe).init(gpa);
    var iterator = tokenizeSca(u8, data, '\n');
    var start: ?Coor = null;

    var y: usize = 0;

    while (iterator.next()) |line| {
        var pipes = try gpa.alloc(Pipe, line.len);
        errdefer gpa.free(pipes);
        var x: usize = 0;

        for (line) |c| {
            pipes[x] = Pipe.fromU8(c);

            if (c == 'S') {
                start = Coor{ .x = x, .y = y };
            }

            x += 1;
        }

        try board.append(pipes);
        // inc counters
        y += 1;
    }

    if (start == null) @panic("no start");

    // now traverse in all pipe directions from start
    const path = findLoop(&start.?, &board);
    defer path.deinit();

    for (board.items) |l| {
        gpa.free(l);
    }

    // now calculate the areas contained in the shoelace area
    const shoelace_area = pathToShoelace(&path);

    return shoelace_area;
}

fn pathToShoelace(path: *const List(Coor)) usize {
    const path_len = path.items.len - 1;
    const half_path_len: isize = @intCast(@divFloor(path_len, 2));

    var twice_enclosed_area: isize = 0;
    // iterate over all the traversal pairs
    for (0..path.items.len - 1) |idx| {
        const curr = path.items[idx];
        const next = path.items[idx + 1];

        const x_0: isize = @intCast(curr.x);
        const x_1: isize = @intCast(next.x);
        const y_0: isize = @intCast(curr.y);
        const y_1: isize = @intCast(next.y);

        // sum the determinant of the pairs
        twice_enclosed_area += (y_0 + y_1) * (x_0 - x_1);
    }

    // sum of the determinant of the points is == 2A
    const area: isize = @divFloor(twice_enclosed_area, 2);

    return @abs(area - (half_path_len - 1));
}

pub fn main() !void {
    print("[Test Data]: Part1: `{}`\n", .{try part1(TEST_DATA)}); // 8
    print("[Real Data]: Part1: `{}`\n", .{try part1(DATA)});
    print("[Test Data]: Part2: `{}`\n", .{try part2(TEST_PART2_DATA)}); // 8
    print("[Real Data]: Part2: `{}`\n", .{try part2(DATA)});
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
