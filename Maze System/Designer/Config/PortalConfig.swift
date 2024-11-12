//
//  PortalConfig.swift
//  Maze System
//
//  Created by Reyes on 11/5/24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class PortalConfig: ObservableObject, Identifiable {
    var id: UUID
    var from: Position
    var to: Position
    
    init(from: Position, to: Position) {
        self.id = UUID()
        self.from = from
        self.to = to
    }
}

struct CodablePortalConfig: Codable {
    var id: UUID
    var from: CodablePosition
    var to: CodablePosition
    
    init(from portalConfig: PortalConfig) {
        self.id = portalConfig.id
        self.from = CodablePosition(from: portalConfig.from)
        self.to = CodablePosition(from: portalConfig.to)
    }
}
