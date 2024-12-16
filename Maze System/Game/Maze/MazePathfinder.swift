//
//  MazePathfinder.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

enum PathMethod: String, CaseIterable, Codable {
    case astar, bidir, jps, dij
    
    var displayName: String {
        switch self {
        case .astar: return "A Star"
        case .bidir: return "Bidirectional A Star"
        case .jps: return "Jump Point Search"
        case .dij: return "Dijkstra"
        }
    }
}

// Heap
struct Heap<T> {
    private var elements: [T]
    private let priority: (T, T) -> Bool
    
    init(elements: [T] = [], priority: @escaping (T, T) -> Bool) {
        self.elements = elements
        self.priority = priority
        buildHeap()
    }
    
    mutating func push(_ value: T) {
        elements.append(value)
        siftUp(from: elements.count - 1)
    }
    
    mutating func pop() -> T? {
        guard !elements.isEmpty else { return nil }
        elements.swapAt(0, elements.count - 1)
        let value = elements.removeLast()
        siftDown(from: 0)
        return value
    }
    
    var isEmpty: Bool { elements.isEmpty }
    
    func contains(_ value: T) -> Bool where T: Equatable {
        elements.contains(value)
    }
    
    private mutating func buildHeap() {
        for index in (0..<(elements.count / 2)).reversed() {
            siftDown(from: index)
        }
    }
    
    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = (child - 1) / 2
        while child > 0 && priority(elements[child], elements[parent]) {
            elements.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }
    
    private mutating func siftDown(from index: Int) {
        var parent = index
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var candidate = parent
            if left < elements.count && priority(elements[left], elements[candidate]) {
                candidate = left
            }
            if right < elements.count && priority(elements[right], elements[candidate]) {
                candidate = right
            }
            if candidate == parent { return }
            elements.swapAt(parent, candidate)
            parent = candidate
        }
    }
}

extension Maze {
    func findPath(method: PathMethod, from start: Position, to end: Position) -> [Position]? {
        guard start.mazeID == self.id, end.mazeID == self.id else {
            print("The start or end point is not in the current maze.")
            return nil
        }
        
        switch method {
        case .astar: return findPathAStar(from: start, to: end)
        case .bidir: return findPathBiDirectional(from: start, to: end)
        case .jps: return findPathJPS(from: start, to: end)
        case .dij: return findPathDijkstra(from: start, to: end)
        }
    }
}

// Shared Method
extension Maze {
    func isWalkable(at position: Position, isEndPosition: Bool = false) -> Bool {
        let nodeType = self[position.x, position.y]
        if isEndPosition {
            return nodeType == .path || nodeType == .task || nodeType == .portal || nodeType == .endPoint
        } else {
            return nodeType == .path || nodeType == .task
        }
    }
    
    func reconstructPath(cameFrom: [Position: Position], current: Position) -> [Position] {
        var path = [current]
        var node = current
        while let previous = cameFrom[node] {
            path.insert(previous, at: 0)
            node = previous
        }
        return path
    }
    
    func getNeighbors(of position: Position) -> [Position] {
        let neighbors = [
            Position(mazeID: position.mazeID, x: position.x + 1, y: position.y),
            Position(mazeID: position.mazeID, x: position.x - 1, y: position.y),
            Position(mazeID: position.mazeID, x: position.x, y: position.y + 1),
            Position(mazeID: position.mazeID, x: position.x, y: position.y - 1)
        ]
        return neighbors.filter { $0.x >= 1 && $0.x <= height && $0.y >= 1 && $0.y <= width }
    }
}

// A*
extension Maze {
    func findPathAStar(from start: Position, to end: Position) -> [Position]? {
        var cameFrom: [Position: Position] = [:]
        var gScore: [Position: Int] = [start: 0]
        var fScore: [Position: Int] = [start: start.distance(to: end)]
        var openSet = Heap<Position>(elements: [start], priority: { fScore[$0, default: 0] < fScore[$1, default: 0] })
        
        while let current = openSet.pop() {
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            for neighbor in getNeighbors(of: current) {
                let isEndOrStart = (neighbor == start || neighbor == end)
                guard isWalkable(at: neighbor, isEndPosition: isEndOrStart) else { continue }
                
                let tentativeGScore = gScore[current, default: Int.max] + 1
                if tentativeGScore < gScore[neighbor, default: Int.max] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + neighbor.distance(to: end)
                    if !openSet.contains(neighbor) {
                        openSet.push(neighbor)
                    }
                }
            }
        }
        return nil
    }
}

// Biodirectional A*
extension Maze {
    func findPathBiDirectional(from start: Position, to end: Position) -> [Position]? {
        var cameFromStart: [Position: Position] = [:]
        var cameFromEnd: [Position: Position] = [:]
        var gScoreStart: [Position: Int] = [start: 0]
        var gScoreEnd: [Position: Int] = [end: 0]
        var fScoreStart: [Position: Int] = [start: start.distance(to: end)]
        var fScoreEnd: [Position: Int] = [end: end.distance(to: start)]
        
        // var openSetStart = Heap<Position>(elements: [start], priority: { fScoreStart[$0, default: 0] < fScoreStart[$1, default: 0] })
        // var openSetEnd = Heap<Position>(elements: [end], priority: { fScoreEnd[$0, default: 0] < fScoreEnd[$1, default: 0] })
        var openSetStart = Heap<Position>(elements: [start], priority: { $0.distance(to: end) < $1.distance(to: end) })
        var openSetEnd = Heap<Position>(elements: [end], priority: { $0.distance(to: start) < $1.distance(to: start) })
        
        while !openSetStart.isEmpty && !openSetEnd.isEmpty {
            guard let currentStart = openSetStart.pop(),
                  let currentEnd = openSetEnd.pop() else { break }
            
            // 检查两方向是否相交
            if let meetingPoint = checkForMeeting(cameFromStart: cameFromStart, cameFromEnd: cameFromEnd) {
                return reconstructPathBidirectional(cameFromStart: cameFromStart, cameFromEnd: cameFromEnd, meetingPoint: meetingPoint)
            }
            
            // 从起点方向扩展
            expandNeighbors(current: currentStart, end: end, openSet: &openSetStart, gScore: &gScoreStart, fScore: &fScoreStart, cameFrom: &cameFromStart)
            
            // 从终点方向扩展
            expandNeighbors(current: currentEnd, end: start, openSet: &openSetEnd, gScore: &gScoreEnd, fScore: &fScoreEnd, cameFrom: &cameFromEnd)
        }
        return nil
    }
    
    private func checkForMeeting(cameFromStart: [Position: Position], cameFromEnd: [Position: Position]) -> Position? {
        let intersection = Set(cameFromStart.keys).intersection(cameFromEnd.keys)
        return intersection.first
    }
    
    private func expandNeighbors(current: Position, end: Position, openSet: inout Heap<Position>, gScore: inout [Position: Int], fScore: inout [Position: Int], cameFrom: inout [Position: Position], isEndOrStart: Bool = false) {
        for neighbor in getNeighbors(of: current) {
            guard isWalkable(at: neighbor) else { continue }
            
            let tentativeGScore = gScore[current, default: Int.max] + 1
            if tentativeGScore < gScore[neighbor, default: Int.max] {
                cameFrom[neighbor] = current
                gScore[neighbor] = tentativeGScore
                fScore[neighbor] = tentativeGScore + neighbor.distance(to: end)
                if !openSet.contains(neighbor) {
                    openSet.push(neighbor)
                }
            }
        }
    }
    
    private func reconstructPathBidirectional(cameFromStart: [Position: Position], cameFromEnd: [Position: Position], meetingPoint: Position) -> [Position] {
        var pathStart = [meetingPoint]
        var pathEnd = [meetingPoint]
        
        var currentNode = meetingPoint
        while let previous = cameFromStart[currentNode] {
            pathStart.insert(previous, at: 0)
            currentNode = previous
        }
        
        currentNode = meetingPoint
        while let next = cameFromEnd[currentNode] {
            pathEnd.append(next)
            currentNode = next
        }
        
        return pathStart + pathEnd.dropFirst()
    }
}

// Jump Point Search (JPS)
extension Maze {
    func findPathJPS(from start: Position, to end: Position) -> [Position]? {
        var openSet: Set<Position> = [start]
        var cameFrom: [Position: Position] = [:]
        var gScore: [Position: Int] = [start: 0]
        var fScore: [Position: Int] = [start: start.distance(to: end)]
        
        while !openSet.isEmpty {
            let current = openSet.min(by: { fScore[$0, default: Int.max] < fScore[$1, default: Int.max] })!
            openSet.remove(current)
            
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            for (dx, dy) in directions {
                if let jumpPoint = jump(from: current, dx: dx, dy: dy, end: end) {
                    let tentativeGScore = gScore[current, default: Int.max] + current.distance(to: jumpPoint)
                    if tentativeGScore < gScore[jumpPoint, default: Int.max] {
                        cameFrom[jumpPoint] = current
                        gScore[jumpPoint] = tentativeGScore
                        fScore[jumpPoint] = tentativeGScore + jumpPoint.distance(to: end)
                        openSet.insert(jumpPoint)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func jump(from current: Position, dx: Int, dy: Int, end: Position) -> Position? {
        var x = current.x + dx
        var y = current.y + dy
        while isValidPosition(x, y), isWalkable(at: Position(mazeID: current.mazeID, x: x, y: y), isEndPosition: end.x == x && end.y == y) {
            let position = Position(mazeID: current.mazeID, x: x, y: y)
            if position == end || hasForcedNeighbors(position, dx: dx, dy: dy) {
                return position
            }
            x += dx
            y += dy
        }
        return nil
    }
    
    private func hasForcedNeighbors(_ position: Position, dx: Int, dy: Int) -> Bool {
        // 检查是否存在迫使转弯的邻居
        if dx != 0 {
            if isValidPosition(position.x, position.y + 1) && !isWalkable(at: Position(mazeID: position.mazeID, x: position.x - dx, y: position.y + 1)) {
                return true
            }
            if isValidPosition(position.x, position.y - 1) && !isWalkable(at: Position(mazeID: position.mazeID, x: position.x - dx, y: position.y - 1)) {
                return true
            }
        } else if dy != 0 {
            if isValidPosition(position.x + 1, position.y) && !isWalkable(at: Position(mazeID: position.mazeID, x: position.x + 1, y: position.y - dy)) {
                return true
            }
            if isValidPosition(position.x - 1, position.y) && !isWalkable(at: Position(mazeID: position.mazeID, x: position.x - 1, y: position.y - dy)) {
                return true
            }
        }
        return false
    }
}

// Dijkstra
extension Maze {
    func findPathDijkstra(from start: Position, to end: Position) -> [Position]? {
        var cameFrom: [Position: Position] = [:]
        var gScore: [Position: Int] = [start: 0]
        var openSet = Heap<Position>(elements: [start], priority: { gScore[$0, default: Int.max] < gScore[$1, default: Int.max] })
        
        while let current = openSet.pop() {
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            for neighbor in getNeighbors(of: current) {
                let isEndOrStart = (neighbor == start || neighbor == end)
                guard isWalkable(at: neighbor, isEndPosition: isEndOrStart) else { continue }
                
                let tentativeGScore = gScore[current, default: Int.max] + 1
                if tentativeGScore < gScore[neighbor, default: Int.max] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    if !openSet.contains(neighbor) {
                        openSet.push(neighbor)
                    }
                }
            }
        }
        return nil
    }
}
