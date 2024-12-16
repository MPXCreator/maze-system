//
//  GameConfiguration.swift
//  Maze System
//
//  Created by Reyes on 11/12/24.
//

import Foundation

struct GameConfiguration: Codable {
    var mazes: [CodableMazeConfig]
    var metadata: CodableMetadata
    var start: CodablePosition
    var end: CodablePosition
}

func loadGameConfiguration(from jsonData: Data) -> GameConfiguration? {
    let decoder = JSONDecoder()
    do {
        let config = try decoder.decode(GameConfiguration.self, from: jsonData)
        return config
    } catch {
        print("Error decoding configuration: \(error)")
        return nil
    }
}

func createGameState(from config: GameConfiguration) -> GameState? {
    var mazeDict = [String: Maze]()

    // Create all the mazes
    for codableMaze in config.mazes {
        let maze = Maze(id: codableMaze.id)
        maze.type = codableMaze.type
        maze.height = codableMaze.height
        maze.width = codableMaze.width
        maze.score = codableMaze.score

        maze.portals = []
        maze.tasks = []

        mazeDict[maze.id] = maze
    }

    // Create portals
    for codableMaze in config.mazes {
        guard let maze = mazeDict[codableMaze.id] else { continue }

        for codablePortal in codableMaze.portals {
            // Original portal
            let fromPosition = Position(mazeID: codablePortal.from.mazeID, x: codablePortal.from.x, y: codablePortal.from.y)
            let toPosition = Position(mazeID: codablePortal.to.mazeID, x: codablePortal.to.x, y: codablePortal.to.y)
            let portal = Portal(from: fromPosition, to: toPosition)
            portal.id = codablePortal.id
            maze.portals.append(portal)

            // Bidirectional portal
            guard let destinationMaze = mazeDict[toPosition.mazeID] else { continue }
            let reversePortal = Portal(from: toPosition, to: fromPosition)
            reversePortal.id = UUID()
            destinationMaze.portals.append(reversePortal)
        }
    }

    // Create tasks
    for codableMaze in config.mazes {
        guard let maze = mazeDict[codableMaze.id] else { continue }

        for codableTask in codableMaze.tasks {
            let position = Position(mazeID: codableTask.position.mazeID, x: codableTask.position.x, y: codableTask.position.y)
            let task = Task(position: position, score: codableTask.score)
            task.id = codableTask.id
            maze.tasks.append(task)
        }
    }

    // Generate mazes
    for codableMaze in config.mazes {
        guard let maze = mazeDict[codableMaze.id] else { continue }
        maze.Generate(height: maze.height, width: maze.width, method: codableMaze.method)
        if maze.id == config.end.mazeID {
            maze.setEnd(x: config.end.x, y: config.end.y)
        }
    }

    // Create the player
    let playerPosition = Position(mazeID: config.start.mazeID, x: config.start.x, y: config.start.y)
    let player = Player(position: playerPosition)

    // Set the current maze
    guard let currentMaze = mazeDict[playerPosition.mazeID] else {
        print("Current maze not found")
        return nil
    }

    // Create the end position
    let startPosition = Position(mazeID: config.start.mazeID, x: config.start.x, y: config.start.y)
    let endPosition = Position(mazeID: config.end.mazeID, x: config.end.x, y: config.end.y)

    // Create GameState
    let gameState = GameState(currentMaze: currentMaze, mazes: Array(mazeDict.values), player: player, startPosition: startPosition, endPosition: endPosition)

    return gameState
}
