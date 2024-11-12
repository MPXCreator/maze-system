//
//  ContentView.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            GameStartView()
                .tabItem {
                    Label("迷宫", systemImage: "square.grid.2x2")
                }
                .modelContainer(for: GameState.self)
            
            NavigationStack {
                DesignerStartView()
            }
                .tabItem {
                    Label("设计器", systemImage: "pencil.and.outline")
                }
                .modelContainer(for: Draft.self)
            
            SettingView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        //.tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
