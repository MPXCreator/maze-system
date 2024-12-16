//
//  GameController.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
class GameController: ObservableObject {
    @Published var gameState: GameState
    @Published var isMoving: Bool = false
    @Published var movementSpeed: Double = 0.5  // 移动速度
    @Published var autoPathfindingEnabled: Bool = false  // 自动寻路开关
    @AppStorage("pathfindingMethod") private var pathfindingMethod: PathMethod = .astar
    @AppStorage("autoReturnToMain") private var autoReturnToMain: Bool = true

    // 当游戏完成（到达终点）时设置为true，用于GameView观察并返回主页面
    @Published var gameFinished: Bool = false

    // Alerts
    @Published var showTaskSheet: Bool = false
    @Published var taskQuestion: String = ""
    @Published var taskAnswer: String = ""
    @Published var portalDescription: String = ""
    @Published var insufficientScoreAlertMessage: String = ""
    @Published var endAlertMessage: String = ""

    @Published var activeAlert: ActiveAlert?

    var taskCompletionHandler: ((Bool) -> Void)? // 任务完成后的回调

    var portalToEnter: Portal?
    var previousPosition: Position?
    var lastValidPosition: Position?
    var pendingPath: [Position]?
    var cancellables = Set<AnyCancellable>()

    // 管理移动取消的属性
    var movementWorkItem: DispatchWorkItem?

    // 动画持续时间
    var animationDuration: Double {
        return 1.1 - movementSpeed
    }

    init(gameState: GameState) {
        self.gameState = gameState
    }

    var currentMaze: Maze {
        return gameState.currentMaze
    }

    var player: Player {
        return gameState.player
    }

    var mazesDict: [String: Maze] {
        return gameState.mazesDict
    }

    var currentMazePlayerScore: Int {
        return gameState.mazeScores[currentMaze.id] ?? 0
    }

    func isAdjacent(to position: Position) -> Bool {
        let dx = abs(player.position.x - position.x)
        let dy = abs(player.position.y - position.y)
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }
    
    func moveBy(dx: Int, dy: Int) {
        let newX = player.position.x + dx
        let newY = player.position.y + dy
        let newPos = Position(mazeID: currentMaze.id, x: newX, y: newY)
        movePlayer(to: newPos)
    }

    func movePlayer(to position: Position) {
        // 当关闭自动寻路时清除可能存在的pendingPath
        if !autoPathfindingEnabled {
            self.pendingPath = nil
        }

        guard !isMoving else { return }
        let maze = currentMaze
        guard position.x >= 0 && position.x < maze.height + 2 && position.y >= 0 && position.y < maze.width + 2 else { return }
        let nodeType = maze[position.x, position.y]

        if nodeType == .wall { return }

        if position == player.position {
            checkForTaskOrPortalOrEnd(at: position)
            return
        }

        if autoPathfindingEnabled {
            if let path = maze.findPath(method: pathfindingMethod, from: player.position, to: position), path.count > 0 {
                isMoving = true
                moveAlongPath(path)
            } else {
                self.activeAlert = .pathNotFound
            }
        } else {
            if isAdjacent(to: position) && nodeType != .wall {
                isMoving = true
                movePlayerToPosition(position)
            }
        }
    }

    func moveAlongPath(_ path: [Position]) {
        guard path.count > 1 else {
            isMoving = false
            return
        }

        self.pendingPath = Array(path.dropFirst())
        moveNextPosition(in: self.pendingPath!)
    }

    func moveNextPosition(in path: [Position]) {
        guard let nextPosition = path.first else {
            isMoving = false
            return
        }

        var remainingPath = path
        remainingPath.removeFirst()

        movePlayerToPosition(nextPosition) {
            if self.isMoving {
                if !remainingPath.isEmpty {
                    self.moveNextPosition(in: remainingPath)
                } else {
                    self.isMoving = false
                }
            }
        }
    }

    func movePlayerToPosition(_ position: Position, completion: @escaping () -> Void = {}) {
        self.previousPosition = player.position
        self.lastValidPosition = player.position

        let duration = animationDuration

        withAnimation(.linear(duration: duration)) {
            self.player.position = position
        }

        self.movementWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.checkForTaskOrPortalOrEnd(at: position)
            self.adjustPendingPath()

            if self.pendingPath == nil || self.pendingPath?.isEmpty == true {
                if self.activeAlert == nil && !self.showTaskSheet {
                    self.isMoving = false
                }
            }
            completion()
        }
        self.movementWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func adjustPendingPath() {
        guard let pendingPath = pendingPath else { return }
        if let index = pendingPath.firstIndex(of: player.position) {
            if index + 1 < pendingPath.count {
                self.pendingPath = Array(pendingPath[(index + 1)...])
            } else {
                self.pendingPath = []
            }
        } else {
            self.pendingPath = pendingPath.filter { $0 != player.position }
        }
    }

    func checkForTaskOrPortalOrEnd(at position: Position) {
        let maze = currentMaze

        // 终点检测
        if maze[position.x, position.y] == .endPoint {
            self.isMoving = false
            self.movementWorkItem?.cancel()
            self.endAlertMessage = "Congratulations on reaching the finish! \nYour score is \(self.player.score) points."
            self.activeAlert = .endReached
            return
        }

        // 任务检测
        if let task = maze.tasks.first(where: { $0.position == position }) {
            task.generateQuestion()
            self.taskQuestion = task.question
            self.taskAnswer = ""
            self.taskCompletionHandler = { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.player.score += task.score
                    self.gameState.mazeScores[self.currentMaze.id, default: 0] += task.score
                    if let index = self.currentMaze.tasks.firstIndex(where: { $0.position == position }) {
                        self.currentMaze.tasks.remove(at: index)
                    }
                    if let path = self.pendingPath, !path.isEmpty {
                        self.isMoving = true
                        self.moveNextPosition(in: path)
                    } else {
                        self.isMoving = false
                    }
                } else {
                    self.player.position = self.lastValidPosition ?? self.player.position
                    self.pendingPath = nil
                    self.isMoving = false
                    self.movementWorkItem?.cancel()
                }
            }
            self.isMoving = false
            self.movementWorkItem?.cancel()
            self.showTaskSheet = true
            return
        }

        // 传送门检测
        if let portal = maze.portals.first(where: { $0.from == position }) {
            if currentMaze.type == .task {
                let requiredScore = currentMaze.score
                let currentScore = gameState.mazeScores[currentMaze.id, default: 0]
                if currentScore < requiredScore {
                    self.portalToEnter = nil
                    self.insufficientScoreAlertMessage = "You need \(requiredScore) points to leave this maze. \nYou currently have \(currentScore) points."
                    self.activeAlert = .insufficientScore
                    self.isMoving = false
                    self.movementWorkItem?.cancel()
                    return
                }
            }

            self.portalToEnter = portal
            self.portalDescription = String(format: "Do you want to enter the maze %@?", portal.to.mazeID)
            self.isMoving = false
            self.movementWorkItem?.cancel()
            self.activeAlert = .portal
            return
        }
    }

    func enterPortal() {
        guard let portal = portalToEnter else { return }

        if let nextMaze = mazesDict[portal.to.mazeID] {
            let x = portal.to.x
            let y = portal.to.y
            if x >= 0 && x < nextMaze.height + 2 && y >= 0 && y < nextMaze.width + 2 {
                self.gameState.currentMaze = nextMaze
                self.player.position = Position(mazeID: nextMaze.id, x: x, y: y)
            } else {
                self.gameState.currentMaze = nextMaze
                self.player.position = Position(mazeID: nextMaze.id, x: 1, y: 1)
            }
        }
        portalToEnter = nil
        activeAlert = nil
    }

    func declinePortal() {
        portalToEnter = nil
        activeAlert = nil
    }

    func returnToStartPage() {
        self.isMoving = false
        self.autoPathfindingEnabled = false
        self.activeAlert = nil
        self.gameFinished = true
    }

    func finishGame() {
        // 当用户关闭终点提示时，根据设置决定是否自动返回
        if autoReturnToMain {
            returnToStartPage()
        } else {
            // 不自动返回时用户可在GameView中手动返回
        }
    }
}

enum ActiveAlert: Identifiable, Equatable {
    case portal
    case insufficientScore
    case saveConfirmation(success: Bool)
    case endReached
    case pathNotFound

    var id: String {
        switch self {
        case .portal:
            return "portal"
        case .insufficientScore:
            return "insufficientScore"
        case .saveConfirmation(let success):
            return "saveConfirmation-\(success)"
        case .endReached:
            return "endReached"
        case .pathNotFound:
            return "pathNotFound"
        }
    }
}
