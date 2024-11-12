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
    case wall, path, task, portal
}

@Model
class Maze: ObservableObject {
    var id: String
    
    var type: MazeType
    
    var height: Int = 0
    var width: Int = 0
    
    var nodes: [NodeType] = []
    
    var portals: [Portal] = []
    
    var tasks: [Task] = []
    
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
    
    init(id: String, height: Int, width: Int, portals: [Portal], tasks: [Task], method: GenMethod) {
        self.id = id
        self.type = .task
        self.portals = portals
        self.tasks = tasks
        Generate(height: height, width: width, method: method)
    }
    
    subscript(x: Int, y: Int) -> NodeType {
        get {
            return nodes[x * (self.width + 2) + y]
        }
        set(newValue) {
            nodes[x * (self.width + 2) + y] = newValue
        }
    }
}
