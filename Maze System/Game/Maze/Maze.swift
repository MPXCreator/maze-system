//
//  Maze.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

import Foundation
import SwiftData

enum MazeType: String, Codable {
    case normal, task
}

enum NodeType: String, Codable {
    case wall, path, task, portal, endPoint
}

@Model
class Maze: Equatable, ObservableObject {
    var id: String
    
    var type: MazeType
    
    var height: Int = 0
    var width: Int = 0
    
    var nodes: [NodeType] = []
    
    var portals: [Portal] = []
    
    var tasks: [Task] = []
    
    var score = 0
    
    init(id: String) {
        self.id = id
        self.type = .normal
    }
    
    init(id: String, height: Int, width: Int, portals: [Portal], method: GenMethod) {
        self.id = id
        self.type = .normal
        self.portals = portals
        Generate(height: height, width: width, method: method)
    }
    
    init(id: String, height: Int, width: Int, portals: [Portal], tasks: [Task], method: GenMethod, score: Int = 0) {
        self.id = id
        self.type = .task
        self.portals = portals
        self.tasks = tasks
        self.score = score
        Generate(height: height, width: width, method: method)
    }
    
    init(id: String, type: MazeType, height: Int, width: Int, nodes: [NodeType], portals: [Portal], tasks: [Task], score: Int = 0) {
        self.id = id
        self.type = type
        self.height = height
        self.width = width
        self.nodes = nodes
        self.portals = portals
        self.tasks = tasks
        self.score = score
    }
    
    subscript(x: Int, y: Int) -> NodeType {
        get {
            let index = x * (self.width + 2) + y
            if index >= 0 && index < nodes.count {
                return nodes[index]
            } else {
                return .wall // Return wall for out-of-bounds indices
            }
        }
        set(newValue) {
            let index = x * (self.width + 2) + y
            if index >= 0 && index < nodes.count {
                nodes[index] = newValue
            } else {
                // Handle out-of-bounds write
                print("Attempted to write to out-of-bounds index (\(x), \(y)) in maze \(id)")
            }
        }
    }
    
    static func == (lhs: Maze, rhs: Maze) -> Bool {
        return lhs.id == rhs.id
    }
    
    func setEnd(x: Int, y: Int) {
        self[x, y] = .endPoint
    }
}
