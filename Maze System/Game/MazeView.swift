//
//  MazeView.swift
//  Maze System
//
//  Created by Reyes on 11/5/24.
//

import SwiftUI

struct MazeView: View {
    @EnvironmentObject var gameController: GameController

    var body: some View {
        GeometryReader { geometry in
            let maze = gameController.currentMaze
            let width = maze.width + 2  // 加上边框
            let height = maze.height + 2
            let cellSize = min(geometry.size.width / CGFloat(width), geometry.size.height / CGFloat(height))

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<height, id: \.self) { x in
                        HStack(spacing: 0) {
                            ForEach(0..<width, id: \.self) { y in
                                CellView(x: x, y: y, cellSize: cellSize)
                                    .environmentObject(gameController)
                            }
                        }
                    }
                }

                // 绘制玩家
                let playerX = gameController.player.position.x
                let playerY = gameController.player.position.y
                PlayerView()
                    .frame(width: cellSize, height: cellSize)
                    .position(x: CGFloat(playerY) * cellSize + cellSize / 2,
                              y: CGFloat(playerX) * cellSize + cellSize / 2)
            }
        }
    }
}

struct CellView: View {
    let x: Int
    let y: Int
    let cellSize: CGFloat
    @EnvironmentObject var gameController: GameController

    var body: some View {
        let maze = gameController.currentMaze

        ZStack {
            let nodeType = maze[x, y]
            Rectangle()
                .foregroundColor(colorForNodeType(nodeType))
                .frame(width: cellSize, height: cellSize)
                .border(Color.gray)

            if nodeType == .task {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                    .foregroundColor(.yellow)
            } else if nodeType == .portal {
                Image(systemName: "arrowshape.turn.up.right.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                    .foregroundColor(.purple)
            }
        }
        .onTapGesture {
            let position = Position(mazeID: maze.id, x: x, y: y)
            gameController.movePlayer(to: position)
        }
    }

    func colorForNodeType(_ nodeType: NodeType) -> Color {
        switch nodeType {
        case .wall:
            return .black
        case .path:
            return .white
        case .task:
            return .white
        case .portal:
            return .white
        }
    }
}

struct PlayerView: View {
    var body: some View {
        Text("🧑‍💻")
            .font(.system(size: 24))
    }
}
