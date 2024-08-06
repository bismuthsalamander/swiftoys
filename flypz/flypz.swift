enum Checker: CustomStringConvertible {
    case X
    case O

    var description: String {
        return self == .X ? "X" : "O"
    }
    var flipped: Checker {
        return self == .X ? .O : .X
    }
    var opponent: Checker {
        return self.flipped
    }
}

enum Cell: CustomStringConvertible, Equatable {
    case Empty
    case Occupied(Checker)
    var description: String {
        switch self {
            case .Empty:
                return " "
            case .Occupied(let ch):
                return ch.description
        }
    }

    var flipped: Cell {
        switch self {
            case .Empty:
                return self
            case .Occupied(let ch):
                return .Occupied(ch.flipped)
        }
    }

    var empty: Bool {
        return self == .Empty
    }
}

enum Move: Equatable {
    case Pass
    case Play(Coordinate)

    var description: String {
        switch self {
            case .Pass:
                return "PASS"
            case .Play(let c):
                return "@\(c)"
        }
    }
}

struct Coordinate: Equatable, CustomStringConvertible {
    var x: Int
    var y: Int
    static let cols = "abcdefgh"

    static func + (left: Coordinate, right: Direction) -> Coordinate {
        return Coordinate(x: left.x + right.dx, y: left.y + right.dy)
    }

    var description: String {
        return String(Coordinate.cols[Coordinate.cols.index(Coordinate.cols.startIndex, offsetBy: x)]) + String(y+1)
    }
}

struct Direction {
    var dx: Int
    var dy: Int

    init(_ dx: Int, _ dy: Int) {
        self.dx = dx
        self.dy = dy
    }

    static let UP = Direction(0, -1)
    static let DOWN = Direction(0, 1)
    static let LEFT = Direction(-1, 0)
    static let RIGHT = Direction(1, 0)
    static let UPLEFT = Direction(-1, -1)
    static let UPRIGHT = Direction(1, -1)
    static let DOWNLEFT = Direction(-1, 1)
    static let DOWNRIGHT = Direction(1, 1)
    static let DIRS = [UP, DOWN, LEFT, RIGHT, UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT]
}

class Board: CustomStringConvertible {
    var cells: [[Cell]]
    var counts: [Checker: Int] = [Checker.X: 0, Checker.O: 0]
    var countX = 0
    var countY = 0

    init() {
        self.cells = Array(repeating: Array(repeating: Cell.Empty, count: 8), count:8)
        self[3, 3] = Cell.Occupied(.O)
        self[4, 4] = Cell.Occupied(.O)
        self[3, 4] = Cell.Occupied(.X)
        self[4, 3] = Cell.Occupied(.X)
    }

    func isValid(_ c: Coordinate) -> Bool {
        return c.x >= 0 && c.y >= 0 && c.x < 8 && c.y < 8
    }

    subscript(x: Int, y: Int) -> Cell {
        get {
            return self.cells[y][x]
        }
        set {
            if case .Occupied(let ch) = self[x, y] {
                self.counts[ch]! -= 1
            }
            if case .Occupied(let ch) = newValue {
                self.counts[ch]! += 1
            }
            self.cells[y][x] = newValue
        }
    }

    subscript(_ c: Coordinate) -> Cell {
        get {
            return self[c.x, c.y]
        }
        set {
            self[c.x, c.y] = newValue
        }
    }

    var description: String {
        var out = "  \(Coordinate.cols)\n +--------+\n"
        for y in (0...7) {
            out += "\(y+1)|"
            for x in 0...7 {
                out += self[x, y].description
            }
            out += "|\(y+1)\n"
        }
        out += " +--------+\n  \(Coordinate.cols)"
        
        return out
    }

    var isFull: Bool {
        return counts[Checker.X]! + counts[Checker.O]! == self.numCells
    }

    var numCells: Int {
        return 8*8
    }
}

class Game: CustomStringConvertible {
    var board: Board
    var toPlay: Checker?
    var legalMoves: [Move] = []
    var consecutivePasses = 0

    init() {
        self.board = Board()
        self.toPlay = Checker.X
        self.updateLegalMoves()
    }

    func updateLegalMoves() {
        self.legalMoves = []
        guard let ch = toPlay else {
            return
        }
        for y in 0...7 {
            for x in 0...7 {
                if !board[x, y].empty {
                    continue
                }
                let coord = Coordinate(x: x, y: y)
                var legal = false
                for dir in Direction.DIRS {
                    if countFlipped(at: coord, ch: ch, dir: dir) > 0 {
                        legal = true
                        break
                    }
                }
                if legal {
                    legalMoves.append(Move.Play(coord))
                }    
            }
        }
        if legalMoves.count == 0 {
            legalMoves.append(Move.Pass)
        }
    }

    func countFlipped(at: Coordinate, ch: Checker, dir: Direction) -> Int {
        var count = 0
        var at = at + dir
        while board.isValid(at) {
            switch board[at] {
                case .Empty:
                    return 0
                case .Occupied(let chFound):
                    if chFound == ch {
                        return count
                    }
                    count += 1
            }
            at = at + dir
        }
        // If we got here, we never found the second flanking checker
        return 0
    }

    func playMove(_ m: Move) {
        guard let player = toPlay else {
            // TODO: panic instead?
            return
        }
        if case .Play(let at) = m {
            board[at] = .Occupied(player)
            for dir in Direction.DIRS {
                print("Dir \(dir)")
                var toFlip: [Coordinate] = []
                var target = at + dir
                checkCell: while board.isValid(target) {
                    switch board[target] {
                    case .Empty:
                        toFlip.removeAll()
                        print("Found an empty cell")
                        break checkCell
                    case .Occupied(let chFound):
                        if chFound == player {
                            print("Found flanking checker")
                            break checkCell
                        }
                        toFlip.append(target)
                    }
                    target = target + dir
                }
                print("Flipping \(toFlip.count)")
                for flipped in toFlip {
                    board[flipped] = board[flipped].flipped
                }
            }
            consecutivePasses = 0
        } else {
            consecutivePasses += 1
        }
        if board.isFull || consecutivePasses == 2 {
            toPlay = nil
        } else {
            toPlay = player.opponent
        }
    }

    var description: String {
        var out = board.description
        if let ch = self.toPlay {
            out += "\n\(ch) to play"
        }
        out += "\nX: \(self.board.counts[Checker.X]!) O: \(self.board.counts[Checker.O]!)"
        out += "\nLegal moves:"
        for m in self.legalMoves {
            out += " \(m)"
        }
        return out
    }
}
var g = Game()
print(g)
g.playMove(Move.Play(Coordinate(x: 3, y: 2)))
print(g)
print(Move.Pass == Move.Play(Coordinate(x: 2, y: 4)))
print(Move.Pass == Move.Pass)
print(Move.Play(Coordinate(x: 3, y: 4)) == Move.Play(Coordinate(x: 2, y: 4)))
print(Move.Play(Coordinate(x: 3, y: 4)) == Move.Play(Coordinate(x: 3, y: 4)))
// print(b.cells[0][0])
// b.cells[0][0] = Cell.Occupied(Checker.X)
// print(b.cells[0][0])
// b.cells[0][0] = b.cells[0][0].flipped
// print(b.cells[0][0])
