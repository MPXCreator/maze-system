//
//  GameStateListView.swift
//  Maze System
//
//  Created by Reyes on 11/6/24.
//

import SwiftUI
import SwiftData

struct GameStateListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var gameStates: [GameState]

    var onSelect: (GameState) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(gameStates) { gameState in
                    HStack {
                        Text(gameState.displayName)
                        Spacer()
                        Button(action: {
                            // 删除保存的游戏状态
                            modelContext.delete(gameState)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(gameState)
                        dismiss()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Saved Games", comment: ""))
#if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text(NSLocalizedString("Cancel", comment: ""))
                    }
                }
            }
#endif
        }
    }
}
