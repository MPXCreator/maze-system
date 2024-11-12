//
//  MazePathfinder.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

extension Maze {
    enum PathMethod {
        case astar, bidir, jps, dij
    }
    
    func findPath(method: PathMethod, from start: Position, to end: Position) -> [Position]? {
        switch method {
        case .astar: return findPathAStar(from: start, to: end)
        case .bidir: return findPathBiDirectional(from: start, to: end)
        case .jps: return findPathJPS(from: start, to: end)
        case .dij: return findPathDijkstra(from: start, to: end)
        }
    }
}

// A*
extension Maze {
    func isWalkable(at position: Position, isEndPosition: Bool = false) -> Bool {
        let nodeType = self[position.x, position.y]
        
        if isEndPosition {
            return nodeType == .path || nodeType == .task || nodeType == .portal
        } else {
            return nodeType == .path || nodeType == .task
        }
    }

    func findPathAStar(from start: Position, to end: Position) -> [Position]? {
        guard start.mazeID == self.id, end.mazeID == self.id else {
            print("起点或终点不在当前迷宫中")
            return nil
        }
        
        var openSet: Set<Position> = [start]
        var cameFrom: [Position: Position] = [:]
        
        var gScore: [Position: Int] = [start: 0]
        var fScore: [Position: Int] = [start: start.distance(to: end)]
        
        while !openSet.isEmpty {
            let current = openSet.min(by: { fScore[$0, default: Int.max] < fScore[$1, default: Int.max] })!
            
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            openSet.remove(current)
            
            let neighbors = getNeighbors(of: current)
            for neighbor in neighbors {
                // 起点和终点允许为 portal，但中途不可为 portal
                let isEndOrStart = (neighbor == start || neighbor == end)
                guard isWalkable(at: neighbor, isEndPosition: isEndOrStart) else { continue }
                
                let tentativeGScore = gScore[current, default: Int.max] + 1
                
                if tentativeGScore < gScore[neighbor, default: Int.max] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + neighbor.distance(to: end)
                    
                    if !openSet.contains(neighbor) {
                        openSet.insert(neighbor)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getNeighbors(of position: Position) -> [Position] {
        let potentialNeighbors = [
            Position(mazeID: position.mazeID, x: position.x + 1, y: position.y),
            Position(mazeID: position.mazeID, x: position.x - 1, y: position.y),
            Position(mazeID: position.mazeID, x: position.x, y: position.y + 1),
            Position(mazeID: position.mazeID, x: position.x, y: position.y - 1)
        ]
        
        return potentialNeighbors.filter { pos in
            pos.x >= 1 && pos.x <= height && pos.y >= 1 && pos.y <= width
        }
    }
    
    private func reconstructPath(cameFrom: [Position: Position], current: Position) -> [Position] {
        var totalPath = [current]
        var currentNode = current
        while let previous = cameFrom[currentNode] {
            currentNode = previous
            totalPath.insert(currentNode, at: 0)
        }
        return totalPath
    }
}

// 双向 A*
extension Maze {
    func findPathBiDirectional(from start: Position, to end: Position) -> [Position]? {
        guard start.mazeID == self.id, end.mazeID == self.id else {
            print("起点或终点不在当前迷宫中")
            return nil
        }

        var openSetStart: Set<Position> = [start]
        var openSetEnd: Set<Position> = [end]
        
        var cameFromStart: [Position: Position] = [:]
        var cameFromEnd: [Position: Position] = [:]
        
        var gScoreStart: [Position: Int] = [start: 0]
        var gScoreEnd: [Position: Int] = [end: 0]
        
        var fScoreStart: [Position: Int] = [start: start.distance(to: end)]
        var fScoreEnd: [Position: Int] = [end: end.distance(to: start)]
        
        while !openSetStart.isEmpty && !openSetEnd.isEmpty {
            // 选择从起点和终点出发的当前节点
            let currentStart = openSetStart.min(by: { fScoreStart[$0, default: Int.max] < fScoreStart[$1, default: Int.max] })!
            let currentEnd = openSetEnd.min(by: { fScoreEnd[$0, default: Int.max] < fScoreEnd[$1, default: Int.max] })!
            
            // 判断两端是否相遇
            if cameFromEnd.keys.contains(currentStart) || cameFromStart.keys.contains(currentEnd) {
                return reconstructPathBidirectional(cameFromStart: cameFromStart, cameFromEnd: cameFromEnd, meetingPoint: currentStart == end ? currentEnd : currentStart)
            }
            
            openSetStart.remove(currentStart)
            openSetEnd.remove(currentEnd)
            
            // 从起点方向扩展邻居节点
            expandNeighbors(current: currentStart, end: end, openSet: &openSetStart, gScore: &gScoreStart, fScore: &fScoreStart, cameFrom: &cameFromStart, isEndOrStart: false)
            
            // 从终点方向扩展邻居节点
            expandNeighbors(current: currentEnd, end: start, openSet: &openSetEnd, gScore: &gScoreEnd, fScore: &fScoreEnd, cameFrom: &cameFromEnd, isEndOrStart: false)
        }
        
        return nil
    }
    
    private func expandNeighbors(current: Position, end: Position, openSet: inout Set<Position>, gScore: inout [Position: Int], fScore: inout [Position: Int], cameFrom: inout [Position: Position], isEndOrStart: Bool) {
        let neighbors = getNeighbors(of: current)
        for neighbor in neighbors {
            guard isWalkable(at: neighbor, isEndPosition: isEndOrStart) else { continue }
            
            let tentativeGScore = gScore[current, default: Int.max] + 1
            if tentativeGScore < gScore[neighbor, default: Int.max] {
                cameFrom[neighbor] = current
                gScore[neighbor] = tentativeGScore
                fScore[neighbor] = tentativeGScore + neighbor.distance(to: end)
                
                if !openSet.contains(neighbor) {
                    openSet.insert(neighbor)
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
        guard start.mazeID == self.id, end.mazeID == self.id else {
            print("起点或终点不在当前迷宫中")
            return nil
        }
        
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
        while isValidPosition(x, y), isWalkable(at: Position(mazeID: current.mazeID, x: x, y: y)) {
            let position = Position(mazeID: current.mazeID, x: x, y: y)
            if position == end {
                return position
            }
            if hasForcedNeighbors(position, dx: dx, dy: dy) {
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
        guard start.mazeID == self.id, end.mazeID == self.id else {
            print("起点或终点不在当前迷宫中")
            return nil
        }
        
        var openSet: Set<Position> = [start]
        var cameFrom: [Position: Position] = [:]
        var gScore: [Position: Int] = [start: 0]
        
        while !openSet.isEmpty {
            let current = openSet.min(by: { gScore[$0, default: Int.max] < gScore[$1, default: Int.max] })!
            openSet.remove(current)
            
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            for neighbor in getNeighbors(of: current) {
                guard isWalkable(at: neighbor) else { continue }
                
                let tentativeGScore = gScore[current, default: Int.max] + 1
                if tentativeGScore < gScore[neighbor, default: Int.max] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    openSet.insert(neighbor)
                }
            }
        }
        
        return nil
    }
}
