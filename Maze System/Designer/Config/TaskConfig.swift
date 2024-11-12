//
//  TaskConfig.swift
//  Maze System
//
//  Created by Reyes on 11/5/24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class TaskConfig: ObservableObject, Identifiable {
    var id: UUID
    var score: Int
    var position: Position
    
    init(score: Int, position: Position) {
        self.id = UUID()
        self.score = score
        self.position = position
    }
}

struct CodableTaskConfig: Codable {
    var id: UUID
    var score: Int
    var position: CodablePosition
    
    init(from taskConfig: TaskConfig) {
        self.id = taskConfig.id
        self.score = taskConfig.score
        self.position = CodablePosition(from: taskConfig.position)
    }
}
