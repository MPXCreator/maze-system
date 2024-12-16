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
    @Attribute(.unique) var id: UUID
    @Attribute var timestamp: Date
    @Attribute var currentMaze: Maze
    @Attribute var mazes: [Maze]
    @Attribute var player: Player
    @Attribute var startPosition: Position
    @Attribute var endPosition: Position
    @Attribute var mazeScores: [String: Int] = [:]

    init(currentMaze: Maze, mazes: [Maze], player: Player, startPosition: Position, endPosition: Position) {
        self.id = UUID()
        self.timestamp = Date()
        self.currentMaze = currentMaze
        self.mazes = mazes
        self.player = player
        self.startPosition = startPosition
        self.endPosition = endPosition
    }
    
    init(currentMaze: Maze, mazes: [Maze], player: Player, startPosition: Position, endPosition: Position, mazeScores: [String: Int]) {
        self.id = UUID()
        self.timestamp = Date()
        self.currentMaze = currentMaze
        self.mazes = mazes
        self.player = player
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.mazeScores = mazeScores
    }

    // Display name
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(currentMaze.id) \(formatter.string(from: timestamp))"
    }

    // Convenient maze dictionary
    var mazesDict: [String: Maze] {
        var dict = [String: Maze]()
        for maze in mazes {
            dict[maze.id] = maze
        }
        return dict
    }
}
