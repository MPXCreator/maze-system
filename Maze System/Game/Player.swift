//
//  Player.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import Foundation
import SwiftData

@Model
class Player: ObservableObject {
    var position: Position
    var score: Int = 0
    var emoji: String = "🧑‍💻"

    init(position: Position) {
        self.position = position
    }
}
