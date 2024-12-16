//
//  MazeView.swift
//  Maze System
//

import SwiftUI

struct MazeView: View {
    @EnvironmentObject var gameController: GameController

    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureOffset: CGSize = .zero
    @GestureState private var gestureZoomScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            let maze = gameController.currentMaze
            let rows = maze.height + 2
            let cols = maze.width + 2
            let scale = zoomScale * gestureZoomScale
            let cellSize = min(geometry.size.width / CGFloat(cols), geometry.size.height / CGFloat(rows)) * scale

            let mazeWidth = CGFloat(cols) * cellSize
            let mazeHeight = CGFloat(rows) * cellSize

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<rows, id: \.self) { x in
                        HStack(spacing: 0) {
                            ForEach(0..<cols, id: \.self) { y in
                                CellView(x: x, y: y, cellSize: cellSize)
                                    .environmentObject(gameController)
                            }
                        }
                    }
                }
                .offset(x: offset.width + gestureOffset.width, y: offset.height + gestureOffset.height)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .updating($gestureZoomScale) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                zoomScale *= value
                            },
                        DragGesture()
                            .updating($gestureOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                            }
                    )
                )

                let playerX = CGFloat(gameController.player.position.x)
                let playerY = CGFloat(gameController.player.position.y)

                PlayerView(emoji: gameController.player.emoji, cellSize: cellSize)
                    .position(x: (playerY + 0.5) * cellSize + offset.width + gestureOffset.width,
                              y: (playerX + 0.5) * cellSize + offset.height + gestureOffset.height)
            }
            .onAppear {
                centerMaze(geometry: geometry, mazeWidth: mazeWidth, mazeHeight: mazeHeight)
            }
            .onChange(of: gameController.currentMaze) { _, newMaze in
                withAnimation {
                    zoomScale = 1.0
                    offset = .zero
                    let newRows = newMaze.height + 2
                    let newCols = newMaze.width + 2
                    let newCellSize = min(geometry.size.width / CGFloat(newCols), geometry.size.height / CGFloat(newRows)) * zoomScale
                    let newMazeWidth = CGFloat(newCols) * newCellSize
                    let newMazeHeight = CGFloat(newRows) * newCellSize
                    centerMaze(geometry: geometry, mazeWidth: newMazeWidth, mazeHeight: newMazeHeight)
                }
            }
        }
    }

    private func centerMaze(geometry: GeometryProxy, mazeWidth: CGFloat, mazeHeight: CGFloat) {
        let dx = (geometry.size.width - mazeWidth) / 2
        let dy = (geometry.size.height - mazeHeight) / 2
        offset = CGSize(width: dx, height: dy)
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
                .border(Color.gray, width: 0.5)

            if nodeType == .task {
                if maze.tasks.contains(where: { $0.position == Position(mazeID: gameController.currentMaze.id, x: x, y: y) }) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                        .foregroundColor(.gray)
                }
            } else if nodeType == .portal {
                Image(systemName: "arrowshape.turn.up.right.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                    .foregroundColor(.purple)
            } else if nodeType == .endPoint {
                Image(systemName: "pip.exit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cellSize * 0.6, height: cellSize * 0.6)
                    .foregroundColor(.red)
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
        case .path, .task, .portal, .endPoint:
            return .white
        }
    }
}

struct PlayerView: View {
    let emoji: String
    let cellSize: CGFloat

    var body: some View {
        Text(emoji)
            .font(.system(size: cellSize * 0.8))
            .frame(width: cellSize, height: cellSize)
    }
}
