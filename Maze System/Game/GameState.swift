//
//  State.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import Foundation
import SwiftData

@Model
class GameState: Identifiable {
    var id: UUID
    var timestamp: Date
    var currentMaze: Maze
    var mazes: [Maze]
    var player: Player

    init(currentMaze: Maze, mazes: [Maze], player: Player) {
        self.id = UUID()
        self.timestamp = Date()
        self.currentMaze = currentMaze
        self.mazes = mazes
        self.player = player
    }

    // 用于显示的名称
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(currentMaze.id) \(formatter.string(from: timestamp))"
    }

    // 方便地获取 mazesDict
    var mazesDict: [String: Maze] {
        var dict = [String: Maze]()
        for maze in mazes {
            dict[maze.id] = maze
        }
        return dict
    }
}
