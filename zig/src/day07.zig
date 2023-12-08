const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day07.txt");
const TEST_DATA =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;

const Card = enum(u8) {
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    T,
    J,
    Q,
    K,
    A,

    fn fromU8(input: u8) Card {
        return switch (input) {
            '2' => .@"2",
            '3' => .@"3",
            '4' => .@"4",
            '5' => .@"5",
            '6' => .@"6",
            '7' => .@"7",
            '8' => .@"8",
            '9' => .@"9",
            'T' => .T,
            'J' => .J,
            'Q' => .Q,
            'K' => .K,
            'A' => .A,
            else => unreachable,
        };
    }
};

/// is a less than b
//fn cardLessThan(a: u8, b: u8) bool {
//    if (b == a) return false;
//    const card_a = Card.fromU8(a);
//    const card_b = Card.fromU8(b);
//
//    return std.sort.asc(u8)({}, @intFromEnum(card_a), @intFromEnum(card_b));
//}
const Ordering = enum {
    less,
    equal,
    greater,
};
fn cardPart2Compare(a: Card, b: Card) Ordering {
    if (a == b) return .equal;

    // a != b, so b is larger than J
    if (a == .J) {
        return .less;
        // a != b, so a is larger than b
    } else if (b == .J) {
        return .greater;
    } else {
        const a_val = @intFromEnum(a);
        const b_val = @intFromEnum(b);

        if (a_val < b_val) {
            return .less;
        } else if (b_val < a_val) {
            return .greater;
        } else {
            return .equal;
        }
    }

    unreachable;
}

test "cardPart2Compare" {
    assert(.less == cardPart2Compare(.J, .@"2"));
    assert(.greater == cardPart2Compare(.@"2", .J));
    assert(.less == cardPart2Compare(.@"2", .@"3"));
    assert(.equal == cardPart2Compare(.@"2", .@"2"));
    assert(.equal == cardPart2Compare(.J, .J));
}

// all cards same
fn isFiveOfAKind(cards: [5]Card) bool {
    if (cards[0] == cards[1] and cards[0] == cards[2] and cards[0] == cards[3] and cards[0] == cards[4]) {
        return true;
    }
    return false;
}

fn isFiveOfAKindPart2(cards: [5]Card) bool {
    // all cards are same
    if (cards[0] == cards[1] and cards[0] == cards[2] and cards[0] == cards[3] and cards[0] == cards[4]) {
        return true;
    }

    // find non joker cards since we have at least one
    // at this point in the function, then loop through all
    // the other cards to find a match
    for (0..5) |i| {
        if (cards[i] == .J) continue;

        const not_joker = cards[i];
        for (0..5) |j| {
            if (i == j) continue;

            const maybe_match_card = cards[j];

            // only accept a joker or the same non-joker card,
            // break out of inner loop when we find a nogood
            if (maybe_match_card != .J and
                maybe_match_card != not_joker)
            {
                break;
            }
        } else {
            return true;
        }
    } else {
        return false;
    }
}

test "isFiveOfAKindPart2" {
    var cards: [5]Card = .{.K} ** 5;
    assert(isFiveOfAKindPart2(cards));

    cards[0] = .J;
    assert(isFiveOfAKindPart2(cards));
    cards[0] = .K;

    cards[1] = .J;
    assert(isFiveOfAKindPart2(cards));
    cards[1] = .K;

    cards[2] = .J;
    assert(isFiveOfAKindPart2(cards));
    cards[2] = .K;

    cards[3] = .J;
    assert(isFiveOfAKindPart2(cards));
    cards[3] = .K;

    cards[4] = .J;
    assert(isFiveOfAKindPart2(cards));
}

// all cards unique
fn isHighCard(cards: [5]Card) bool {
    for (0..cards.len - 1) |i| {
        const a = cards[i];
        for (0..cards.len) |j| {
            if (i == j) continue;

            const b = cards[j];

            if (a == b) return false;
        }
    } else {
        return true;
    }

    unreachable;
}

fn isFourOfAKind(cards: [5]Card) bool {
    for (0..5) |not_idx| {
        const match_idx = (not_idx + 1) % 5;

        if (cards[not_idx] != cards[match_idx] and
            cards[match_idx] == cards[(match_idx + 1) % 5] and
            cards[match_idx] == cards[(match_idx + 2) % 5] and
            cards[match_idx] == cards[(match_idx + 3) % 5])
        {
            return true;
        }
    } else {
        return false;
    }

    unreachable;
}

test "isFourOfAKind" {
    var cards: [5]Card = .{.@"2"} ** 5;
    assert(!isFourOfAKind(cards));

    cards[0] = .@"3";
    assert(isFourOfAKind(cards));
    cards[0] = .@"2";

    cards[1] = .@"3";
    assert(isFourOfAKind(cards));
    cards[1] = .@"2";

    cards[2] = .@"3";
    assert(isFourOfAKind(cards));
    cards[2] = .@"2";

    cards[3] = .@"3";
    assert(isFourOfAKind(cards));
    cards[3] = .@"2";

    cards[4] = .@"3";
    assert(isFourOfAKind(cards));
}

fn isFourOfAKindPart2(cards: [5]Card) bool {
    for (0..5) |card_idx| {
        const card = cards[card_idx];

        if (card == .J) continue;

        var matches: usize = 0;
        for (0..5) |match_idx| {
            const maybe_match = cards[match_idx];

            if (maybe_match == .J or maybe_match == card) {
                matches += 1;
            }
        }

        if (matches == 4) return true;
    } else {
        return false;
    }

    unreachable;
}

fn isThreeOfAKindPart2(cards: [5]Card) bool {
    for (0..5) |card_idx| {
        const card = cards[card_idx];

        if (card == .J) continue;

        var matches: usize = 0;
        for (0..5) |match_idx| {
            const maybe_match = cards[match_idx];

            if (maybe_match == .J or maybe_match == card) {
                matches += 1;
            }
        }

        if (matches == 3) return true;
    } else {
        return false;
    }

    unreachable;
}

test "isFourOfAKindPart2" {
    var cards: [5]Card = .{.@"2"} ** 5;
    assert(!isFourOfAKindPart2(cards));

    cards[0] = .@"3";
    assert(isFourOfAKindPart2(cards));
    cards[0] = .@"2";

    cards[1] = .@"3";
    assert(isFourOfAKindPart2(cards));
    cards[1] = .@"2";

    cards[2] = .@"3";
    assert(isFourOfAKindPart2(cards));
    cards[2] = .@"2";

    cards[3] = .@"3";
    assert(isFourOfAKindPart2(cards));
    cards[3] = .@"2";

    cards[4] = .@"3";
    assert(isFourOfAKindPart2(cards));
    cards[4] = .@"2";

    cards[0] = .@"3";
    cards[1] = .J;
    assert(isFourOfAKindPart2(cards));
    cards[0] = .@"2";
    cards[1] = .@"2";

    cards[1] = .@"3";
    cards[2] = .J;
    assert(isFourOfAKindPart2(cards));
    cards[1] = .@"2";
    cards[2] = .@"2";

    cards[2] = .@"3";
    cards[3] = .J;
    assert(isFourOfAKindPart2(cards));
    cards[2] = .@"2";
    cards[3] = .@"2";

    cards[3] = .@"3";
    cards[4] = .J;
    assert(isFourOfAKindPart2(cards));
    cards[3] = .@"2";
    cards[4] = .@"2";

    cards[4] = .@"3";
    cards[0] = .J;
    assert(isFourOfAKindPart2(cards));
}

const CardsCommitted = struct {
    /// has a special hand already been found
    found: bool,
    /// indecies match the indecies in the higher `cards`
    committed: [5]bool,
};

fn threeKindSearch(cards: [5]Card) CardsCommitted {
    // only need to base from 3 to get all combo's
    for (0..3) |base_idx| {
        var match_idx: ?usize = null;

        const base = cards[base_idx];

        for (0..5) |other_idx| {
            if (base_idx == other_idx) continue;

            const other = cards[other_idx];

            if (base == other) {
                if (match_idx) |prev_match_idx| {
                    var committed = [5]bool{ false, false, false, false, false };
                    committed[base_idx] = true;
                    committed[prev_match_idx] = true;
                    committed[other_idx] = true;

                    return CardsCommitted{
                        .found = true,
                        .committed = committed,
                    };
                } else {
                    // set second to this currently found
                    match_idx = other_idx;
                }
            }
        }
    }

    // did not find what we're looking for
    return CardsCommitted{ .found = false, .committed = .{ false, false, false, false, false } };
}

fn threeKindSearchPart2(cards: [5]Card) CardsCommitted {
    for (0..5) |base_idx| {
        var match_idx: ?usize = null;
        const base = cards[base_idx];
        if (base == .J) continue; // no joker as the base

        for (0..5) |other_idx| {
            if (base_idx == other_idx) continue;

            const other = cards[other_idx];

            if (base == other or other == .J) {
                if (match_idx) |prev_match_idx| {
                    // we have found the third match @ `other_idx`
                    var committed: [5]bool = .{false} ** 5;
                    committed[base_idx] = true;
                    committed[prev_match_idx] = true;
                    committed[other_idx] = true;

                    return CardsCommitted{
                        .found = true,
                        .committed = committed,
                    };
                } else {
                    // set second match
                    match_idx = other_idx;
                }
            }
        }
    }

    // did not find what we're looking for
    return CardsCommitted{ .found = false, .committed = .{ false, false, false, false, false } };
}

// looks for matching pairs in cards that are not
// already committed, returning the result
fn pairFromCommitted(cards: [5]Card, c: CardsCommitted) CardsCommitted {
    var committed: [5]bool = .{false} ** 5;
    for (0..5) |base_idx| {
        if (c.committed[base_idx]) continue;

        const base = cards[base_idx];

        for (0..5) |other_idx| {
            if (other_idx == base_idx) continue;
            if (c.committed[other_idx]) continue;

            const other = cards[other_idx];

            if (base == other) {

                // set all the proper commits
                @memcpy(&committed, &c.committed);
                committed[base_idx] = true;
                committed[other_idx] = true;

                return CardsCommitted{ .found = true, .committed = committed };
            }
        }
    }

    // did not find a match
    return CardsCommitted{ .found = false, .committed = committed };
}

fn pairFromCommittedPart2(cards: [5]Card, c: CardsCommitted) CardsCommitted {
    var committed: [5]bool = .{false} ** 5;
    for (0..5) |base_idx| {
        if (c.committed[base_idx]) continue;

        const base = cards[base_idx];
        if (base == .J) continue;

        for (0..5) |other_idx| {
            if (other_idx == base_idx) continue;
            if (c.committed[other_idx]) continue;

            const other = cards[other_idx];

            if (base == other or other == .J) {

                // set all the proper commits
                @memcpy(&committed, &c.committed);
                committed[base_idx] = true;
                committed[other_idx] = true;
                return CardsCommitted{ .found = true, .committed = committed };
            }
        }
    }

    // did not find a match
    return CardsCommitted{ .found = false, .committed = committed };
}

const HandType = enum(u8) {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    fn fromHandPart1(cards: [5]Card) HandType {
        // five of a kind
        if (isFiveOfAKind(cards)) {
            return .five_of_a_kind;
        }

        // four of a kind
        if (isFourOfAKind(cards)) {
            return .four_of_a_kind;
        }

        // high card
        if (isHighCard(cards)) {
            return .high_card;
        }

        const committed: CardsCommitted = threeKindSearch(cards);
        if (committed.found) {
            // we potentially have a full house via 2 of a kind
            const pair_result: CardsCommitted = pairFromCommitted(cards, committed);
            if (pair_result.found) {
                return .full_house;
            } else {
                return .three_of_a_kind;
            }
        }

        // now look for pairs
        const first_pair: CardsCommitted = pairFromCommitted(cards, committed);
        if (first_pair.found) {
            const second_pair: CardsCommitted = pairFromCommitted(cards, first_pair);
            if (second_pair.found) {
                return .two_pair;
            } else {
                return .one_pair;
            }
        }

        unreachable;
    }

    fn fromHandPart2(cards: [5]Card) HandType {
        // five of a kind
        if (isFiveOfAKindPart2(cards)) {
            return .five_of_a_kind;
        }

        if (isFourOfAKindPart2(cards)) {
            return .four_of_a_kind;
        }

        const committed: CardsCommitted = threeKindSearchPart2(cards);
        if (committed.found) {
            const pair_result: CardsCommitted = pairFromCommittedPart2(cards, committed);
            if (pair_result.found) {
                return .full_house;
            } else {
                return .three_of_a_kind;
            }
        }

        // now look for pairs
        const first_pair: CardsCommitted = pairFromCommittedPart2(cards, committed);
        if (first_pair.found) {
            const second_pair: CardsCommitted = pairFromCommittedPart2(cards, first_pair);
            if (second_pair.found) {
                return .two_pair;
            } else {
                return .one_pair;
            }
        }

        // high card
        if (isHighCard(cards)) {
            return .high_card;
        }
        unreachable;
    }
};

test "fromHandPart1" {
    const HIGH_CARD = [_]Card{ .@"2", .@"3", .@"4", .@"5", .@"6" };
    const ONE_PAIR = [_]Card{ .@"2", .@"2", .@"3", .@"4", .@"5" };
    const TWO_PAIR = [_]Card{ .@"2", .@"2", .@"3", .@"3", .@"4" };
    const FULL_HOUSE = [_]Card{ .@"2", .@"3", .@"3", .@"3", .@"2" };
    const THREE_OF_KIND = [_]Card{ .@"2", .@"2", .@"2", .@"3", .@"4" };
    const FOUR_OF_KIND = [_]Card{ .A, .A, .@"8", .A, .A };
    const FIVE_OF_KIND = [_]Card{ .@"2", .@"2", .@"2", .@"2", .@"2" };

    // assert
    assert(.high_card == HandType.fromHandPart1(HIGH_CARD));
    assert(.one_pair == HandType.fromHandPart1(ONE_PAIR));
    assert(.two_pair == HandType.fromHandPart1(TWO_PAIR));
    assert(.three_of_a_kind == HandType.fromHandPart1(THREE_OF_KIND));
    assert(.four_of_a_kind == HandType.fromHandPart1(FOUR_OF_KIND));
    assert(.five_of_a_kind == HandType.fromHandPart1(FIVE_OF_KIND));
    assert(.full_house == HandType.fromHandPart1(FULL_HOUSE));
}

test "fromHandPart2" {
    const HIGH_CARD = [_]Card{ .@"2", .@"3", .@"4", .@"5", .@"6" };
    const ONE_PAIR = [_]Card{ .@"2", .@"2", .@"3", .@"4", .@"5" };
    const TWO_PAIR = [_]Card{ .@"2", .@"2", .@"3", .@"3", .@"4" };
    const FULL_HOUSE = [_]Card{ .@"2", .@"3", .@"3", .@"3", .@"2" };
    const THREE_OF_KIND = [_]Card{ .@"2", .@"2", .@"2", .@"3", .@"4" };
    const FOUR_OF_KIND = [_]Card{ .A, .A, .@"8", .A, .A };
    const FIVE_OF_KIND = [_]Card{ .@"2", .@"2", .@"2", .@"2", .@"2" };
    const HIGH_CARD_J = [_]Card{ .@"2", .@"3", .@"4", .@"5", .@"6" };
    const ONE_PAIR_J = [_]Card{ .@"2", .J, .@"3", .@"4", .@"5" };
    const TWO_PAIR_J = [_]Card{ .@"2", .@"2", .@"3", .@"3", .@"4" };
    const FULL_HOUSE_J = [_]Card{ .@"2", .@"3", .@"3", .@"3", .@"2" };
    const THREE_OF_KIND_J = [_]Card{ .@"2", .@"2", .@"2", .@"3", .@"4" };
    const FOUR_OF_KIND_J = [_]Card{ .T, .@"5", .@"5", .J, .@"5" };
    const FIVE_OF_KIND_J = [_]Card{ .@"2", .@"2", .@"2", .@"2", .@"2" };
    // assert
    assert(.high_card == HandType.fromHandPart2(HIGH_CARD));
    assert(.one_pair == HandType.fromHandPart2(ONE_PAIR));
    assert(.two_pair == HandType.fromHandPart2(TWO_PAIR));
    assert(.three_of_a_kind == HandType.fromHandPart2(THREE_OF_KIND));
    assert(.four_of_a_kind == HandType.fromHandPart2(FOUR_OF_KIND));
    assert(.five_of_a_kind == HandType.fromHandPart2(FIVE_OF_KIND));
    assert(.full_house == HandType.fromHandPart2(FULL_HOUSE));
    assert(.high_card == HandType.fromHandPart2(HIGH_CARD_J));
    assert(.one_pair == HandType.fromHandPart2(ONE_PAIR_J));
    assert(.two_pair == HandType.fromHandPart2(TWO_PAIR_J));
    assert(.three_of_a_kind == HandType.fromHandPart2(THREE_OF_KIND_J));
    assert(.four_of_a_kind == HandType.fromHandPart2(FOUR_OF_KIND_J));
    assert(.five_of_a_kind == HandType.fromHandPart2(FIVE_OF_KIND_J));
    assert(.full_house == HandType.fromHandPart2(FULL_HOUSE_J));
}

const Hand = struct {
    cards: []const u8,
    hand: [5]Card,
    bid: usize,
    hand_type: HandType,

    inline fn winnings(self: *const Hand, rank: usize) usize {
        return rank * self.bid;
    }

    fn new(cards: []const u8, bid: usize, part: usize) Hand {
        const hand = [5]Card{
            Card.fromU8(cards[0]),
            Card.fromU8(cards[1]),
            Card.fromU8(cards[2]),
            Card.fromU8(cards[3]),
            Card.fromU8(cards[4]),
        };

        const hand_type = if (part == 1) blk: {
            break :blk HandType.fromHandPart1(hand);
        } else blk: {
            break :blk HandType.fromHandPart2(hand);
        };

        return Hand{
            .cards = cards,
            .hand = hand,
            .bid = bid,
            .hand_type = hand_type,
        };
    }
};

fn intoHands(data: []const u8, part: usize) !List(Hand) {
    var hands = List(Hand).init(gpa);
    var iterator = tokenizeSca(u8, data, '\n');

    // to parse each line, each line is split into "hand bid"
    while (iterator.next()) |line| {
        const sep = indexOf(u8, line, ' ').?;

        try hands.append(
            Hand.new(
                line[0..sep],
                try parseInt(usize, line[sep + 1 ..], 10),
                part,
            ),
        );
    }

    return hands;
}

fn handLessThan(context: void, a: Hand, b: Hand) bool {
    _ = context;
    if (a.hand_type == b.hand_type) {
        // complicated
        for (0..5) |card_idx| {
            const a_card: u8 = @intFromEnum(a.hand[card_idx]);
            const b_card: u8 = @intFromEnum(b.hand[card_idx]);

            // cards are the same
            if (a_card == b_card) continue;

            if (a_card < b_card) {
                return true;
            } else if (a_card > b_card) {
                return false;
            } else {
                continue;
            }
        } else {
            // something is wrong -- cards are even??
            unreachable;
        }
    } else {
        return std.sort.asc(u8)({}, @intFromEnum(a.hand_type), @intFromEnum(b.hand_type));
    }

    unreachable;
}

fn handLessThanPart2(context: void, a: Hand, b: Hand) bool {
    _ = context;
    if (a.hand_type == b.hand_type) {
        // complicated
        for (0..5) |card_idx| {
            const a_card = a.hand[card_idx];
            const b_card = b.hand[card_idx];

            // cards are the same
            switch (cardPart2Compare(a_card, b_card)) {
                .equal => continue,
                .greater => return false,
                .less => return true,
            }
        } else {
            // something is wrong -- cards are even??
            unreachable;
        }
    } else {
        return std.sort.asc(u8)({}, @intFromEnum(a.hand_type), @intFromEnum(b.hand_type));
    }

    unreachable;
}

fn part1(data: []const u8) !usize {
    const hands = try intoHands(data, 1);

    // sort according to part1 rules
    std.sort.heap(Hand, hands.items, {}, handLessThan);

    var winnings: usize = 0;

    for (hands.items, 1..) |hand, rank| {
        winnings += hand.winnings(rank);
    }

    return winnings;
}

fn part2(data: []const u8) !usize {
    const hands = try intoHands(data, 2);

    // sort according to part1 rules
    std.sort.heap(Hand, hands.items, {}, handLessThanPart2);

    var winnings: usize = 0;

    for (hands.items, 1..) |hand, rank| {
        winnings += hand.winnings(rank);
    }

    return winnings;
}

// no:
// - 254714365 <
pub fn main() !void {
    print("[Test Data]: Part1: `{}`\n", .{try part1(TEST_DATA)});
    print("[Real Data]: Part1: `{}`\n", .{try part1(DATA)});
    print("[Test Data]: Part2: `{}`\n", .{try part2(TEST_DATA)});
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
