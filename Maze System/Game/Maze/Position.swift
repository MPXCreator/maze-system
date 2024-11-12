//
//  Position.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

import Foundation
import SwiftData

@Model
class Position {
    var mazeID: String
    var x: Int
    var y: Int
    
    init(mazeID: String, x: Int, y: Int) {
        self.mazeID = mazeID
        self.x = x
        self.y = y
    }
}

extension Position: Hashable {
    static func == (lhs: Position, rhs: Position) -> Bool {
        return lhs.mazeID == rhs.mazeID && lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mazeID)
        hasher.combine(x)
        hasher.combine(y)
    }
    
    func distance(to position: Position) -> Int {
        return abs(self.x - position.x) + abs(self.y - position.y)
    }
}

struct CodablePosition: Codable {
    var mazeID: String
    var x: Int
    var y: Int
    
    init(from position: Position) {
        self.mazeID = position.mazeID
        self.x = position.x
        self.y = position.y
    }
}
