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
    @Published var movementSpeed: Double = 0.5  // 移动速度，范围 0.1 - 1.0
    @Published var autoPathfindingEnabled: Bool = false  // 自动寻路开关
    @Published var showTaskAlert: Bool = false
    @Published var taskQuestion: String = ""
    @Published var taskAnswer: String = ""
    @Published var showPortalAlert: Bool = false
    @Published var portalDescription: String = ""
    var taskCompletionHandler: (() -> Void)?    // 任务完成后的回调
    var portalToEnter: Portal?
    var previousPosition: Position?
    var lastValidPosition: Position?
    var pendingPath: [Position]?  // 保存剩余的路径
    var cancellables = Set<AnyCancellable>()

    // 计算动画持续时间
    var animationDuration: Double {
        return 1.1 - movementSpeed  // movementSpeed 为 1.0 时，duration 为 0.1
    }

    // 默认初始化方法，用于新游戏
    init() {
        // 创建默认的迷宫和玩家
        let maze = Maze(id: "DefaultMaze")
        let startPosition = Position(mazeID: maze.id, x: 1, y: 1)
        let player = Player(position: startPosition)
        player.emoji = "🧑‍💻"
        player.score = 0
        let gameState = GameState(currentMaze: maze, mazes: [maze], player: player)
        self.gameState = gameState

        setupBindings()
    }

    // 从 GameState 初始化
    init(gameState: GameState) {
        self.gameState = gameState
        setupBindings()
    }

    // 初始化公共部分
    private func setupBindings() {
        // 监听玩家位置变化，检测是否触发任务或传送门
        self.gameState.player.objectWillChange
            .sink { [weak self] in
                if let newPosition = self?.gameState.player.position {
                    self?.checkForTaskOrPortal(at: newPosition)
                }
            }
            .store(in: &cancellables)
    }

    // 获取当前迷宫
    var currentMaze: Maze {
        return gameState.currentMaze
    }

    // 获取玩家
    var player: Player {
        return gameState.player
    }

    // 获取 mazesDict
    var mazesDict: [String: Maze] {
        return gameState.mazesDict
    }

    // 判断位置是否相邻
    func isAdjacent(to position: Position) -> Bool {
        let dx = abs(player.position.x - position.x)
        let dy = abs(player.position.y - position.y)
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }

    // 移动玩家到指定位置
    func movePlayer(to position: Position) {
        guard !isMoving else { return }
        let maze = currentMaze
        guard position.x >= 0 && position.x < maze.height + 2 && position.y >= 0 && position.y < maze.width + 2 else { return }
        let nodeType = maze[position.x, position.y]
        if nodeType == .wall {
            // 墙壁，不能移动
            return
        }

        if autoPathfindingEnabled {
            // 自动寻路
            if let path = maze.findPath(method: .astar, from: player.position, to: position) {
                isMoving = true
                moveAlongPath(path)
            } else {
                print(NSLocalizedString("No path found", comment: ""))
            }
        } else {
            // 手动移动，只能移动到相邻的可通行位置
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

        var mutablePath = path
        // 移除第一个位置（当前玩家所在位置）
        mutablePath.removeFirst()

        moveNextPosition(in: mutablePath)
    }

    func moveNextPosition(in path: [Position]) {
        var path = path
        guard let nextPosition = path.first else {
            isMoving = false
            return
        }
        path.removeFirst()

        // 保存剩余路径
        self.pendingPath = path
        // 记录上一个位置
        self.previousPosition = player.position

        // 计算动画持续时间
        let duration = animationDuration

        // 计算当前位置与下一位置之间的方向变化
        let dx = nextPosition.x - player.position.x
        let dy = nextPosition.y - player.position.y
        let isTurning = (dx != 0 && dy != 0)  // 如果同时改变 x 和 y，认为是转向

        // 选择不同的动画曲线
        let animation = isTurning ? Animation.easeInOut(duration: duration) : Animation.linear(duration: duration)

        withAnimation(animation) {
            self.player.position = nextPosition
        }

        // 等待动画结束后，继续移动或处理任务
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // 检查是否有任务或传送门
            self.checkForTaskOrPortal(at: nextPosition)

            // 如果没有任务或移动未被暂停，继续移动
            if self.isMoving {
                if !path.isEmpty {
                    self.moveNextPosition(in: path)
                } else {
                    self.isMoving = false
                }
            }
        }
    }

    func movePlayerToPosition(_ position: Position) {
        let duration = animationDuration

        withAnimation(Animation.easeInOut(duration: duration)) {
            self.player.position = position
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isMoving = false
        }
    }

    func checkForTaskOrPortal(at position: Position) {
        // 检查是否有任务
        if let task = currentMaze.tasks.first(where: { $0.position.x == position.x && $0.position.y == position.y }) {
            // 保存当前位置，便于任务失败时回退
            self.lastValidPosition = previousPosition ?? player.position

            // 生成任务问题
            task.generateQuestion()
            self.taskQuestion = task.question
            self.taskAnswer = ""
            self.showTaskAlert = true
            self.taskCompletionHandler = {
                if self.taskAnswer == task.answer {
                    self.player.score += task.score
                    // 提示回答正确
                    self.taskQuestion = String(format: NSLocalizedString("Correct answer! You earned %d points. Current score: %d", comment: ""), task.score, self.player.score)
                    // 继续移动
                    if let path = self.pendingPath, !path.isEmpty {
                        self.moveNextPosition(in: path)
                    } else {
                        self.isMoving = false
                    }
                } else {
                    // 提示回答错误
                    self.taskQuestion = String(format: NSLocalizedString("Incorrect answer. The correct answer is: %@", comment: ""), task.answer)
                    // 停止移动，回退到上一个位置
                    self.player.position = self.lastValidPosition ?? self.player.position
                    self.isMoving = false
                }
                // 显示结果后，自动关闭提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showTaskAlert = false
                }
            }
        }

        // 检查是否有传送门
        if let portal = currentMaze.portals.first(where: { $0.from.x == position.x && $0.from.y == position.y }) {
            self.portalToEnter = portal
            self.portalDescription = String(format: NSLocalizedString("Do you want to enter maze %@?", comment: ""), portal.to.mazeID)
            self.showPortalAlert = true
        }
    }

    func enterPortal() {
        guard let portal = portalToEnter else { return }
        if let nextMaze = mazesDict[portal.to.mazeID] {
            self.gameState.currentMaze = nextMaze
            self.player.position = Position(mazeID: nextMaze.id, x: portal.to.x, y: portal.to.y)
        }
        portalToEnter = nil
    }

    func declinePortal() {
        portalToEnter = nil
    }
}
