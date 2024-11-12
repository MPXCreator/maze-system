//
//  MazeConfig.swift
//  Maze System
//
//  Created by Reyes on 10/28/24.
//

import SwiftUI
import SwiftData

@Model
class MazeConfig: ObservableObject, Identifiable {
    var id: String
    var type: MazeType
    var height: Int
    var width: Int
    var method: GenMethod
    
    var portals: [PortalConfig]
    var tasks: [TaskConfig]
    var score: Int
    
    init(id: String, type: MazeType, height: Int, width: Int, method: GenMethod, portals: [PortalConfig] = [], tasks: [TaskConfig] = [], score: Int = 0) {
        self.id = id
        self.type = type
        self.height = height
        self.width = width
        self.method = method
        self.portals = portals
        self.tasks = tasks
        self.score = score
    }
}

struct CodableMazeConfig: Codable {
    var id: String
    var type: MazeType
    var height: Int
    var width: Int
    var method: GenMethod
    var portals: [CodablePortalConfig]
    var tasks: [CodableTaskConfig]
    var score: Int
    
    init(from mazeConfig: MazeConfig) {
        self.id = mazeConfig.id
        self.type = mazeConfig.type
        self.height = mazeConfig.height
        self.width = mazeConfig.width
        self.method = mazeConfig.method
        self.portals = mazeConfig.portals.map { CodablePortalConfig(from: $0) }
        self.tasks = mazeConfig.tasks.map { CodableTaskConfig(from: $0) }
        self.score = mazeConfig.score
    }
}
