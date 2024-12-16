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
                    Label(LocalizedStringKey("Maze"), systemImage: "square.grid.2x2")
                }
            
            NavigationStack {
                DesignerStartView()
            }
                .tabItem {
                    Label(LocalizedStringKey("Designer"), systemImage: "pencil.and.outline")
                }
            
            SettingView()
                .tabItem {
                    Label(LocalizedStringKey("Settings"), systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
