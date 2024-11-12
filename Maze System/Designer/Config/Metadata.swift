//
//  Metadata.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftData

@Model
class Metadata {
    var name: String
    var author: String
    var version: String
    
    init(name: String, author: String, version: String) {
        self.name = name
        self.author = author
        self.version = version
    }
}

struct CodableMetadata: Codable {
    var name: String
    var author: String
    var version: String
    
    init(from metadata: Metadata) {
        self.name = metadata.name
        self.author = metadata.author
        self.version = metadata.version
    }
}
