//
//  Portal.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

import Foundation
import SwiftData

@Model
class Portal: ObservableObject {
    var id: UUID
    var from: Position
    var to: Position
    
    init(from: Position, to: Position) {
        self.id = UUID()
        self.from = from
        self.to = to
    }
}
