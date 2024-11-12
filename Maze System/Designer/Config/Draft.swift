//
//  Draft.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import Foundation
import SwiftData

@Model
class Draft: ObservableObject, Identifiable {
    @Attribute(.unique) var id: UUID
    var metadata: Metadata
    var start: Position
    var end: Position
    var mazes: [MazeConfig]
    
    init() {
        self.id = UUID()
        self.start = Position(mazeID: "", x: 0, y: 0)
        self.end = Position(mazeID: "", x: 0, y: 0)
        self.mazes = []
        self.metadata = Metadata(name: "Mazes", author: "Somebody", version: "0.0.1")
    }
    
    init(id: UUID, metadata: Metadata, start: Position, end: Position, mazes: [MazeConfig]) {
        self.id = id
        self.metadata = metadata
        self.start = start
        self.end = end
        self.mazes = mazes
    }
}

struct CodableDraft: Codable {
    var id: UUID
    var metadata: CodableMetadata
    var start: CodablePosition
    var end: CodablePosition
    var mazes: [CodableMazeConfig]
    
    init(from draft: Draft) {
        self.id = draft.id
        self.metadata = CodableMetadata(from: draft.metadata)
        self.start = CodablePosition(from: draft.start)
        self.end = CodablePosition(from: draft.end)
        self.mazes = draft.mazes.map { CodableMazeConfig(from: $0) }
    }
}
