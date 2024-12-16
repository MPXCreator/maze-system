//
//  MazePreview.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI

struct MazePreview: View {
    @EnvironmentObject var maze: Maze
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    var marked: (Int, Int)? = nil

    var body: some View {
        GeometryReader { geometry in
            let gridSize = min(geometry.size.width / CGFloat(maze.width), geometry.size.height / CGFloat(maze.height)) * scale
            
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    ForEach(0..<maze.height, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<maze.width, id: \.self) { col in
                                Rectangle()
                                    .fill(colorForNode(x: row + 1, y: col + 1))
                                    .frame(width: gridSize, height: gridSize)
                                    .border(Color.gray)
                                    .gesture(TapGesture()
                                                .onEnded { handleTap(row: row, col: col) })
                            }
                        }
                    }
                }
                .scaleEffect(scale)
                .gesture(MagnificationGesture()
                            .onChanged { value in
                                self.scale = self.lastScale * value
                            }
                            .onEnded { _ in
                                self.lastScale = self.scale
                            })
                .frame(width: geometry.size.width * scale, height: geometry.size.height * scale)
            }
        }
    }

    func colorForNode(x: Int, y: Int) -> Color{
        if let mark = marked, mark.0 == x && mark.1 == y {
            return .red
        }
        return colorForNodeType(maze[x, y])
    }
    
    func colorForNodeType(_ nodeType: NodeType) -> Color {
        switch nodeType {
        case .wall: return .black
        case .path, .task, .portal, .endPoint: return .white
        }
    }
    
    func handleTap(row: Int, col: Int) {
        print("Tapped on cell at (\(row), \(col))")
        // Add tap handling logic
    }
}
