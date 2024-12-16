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
        NavigationStack {
            List {
                ForEach(gameStates) { gameState in
                    HStack {
                        Text(gameState.displayName)
                        Spacer()
                        #if os(macOS)
                        Button(action: {
                            deleteState(gameState)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                        onSelect(gameState)
                    }
                }
                .onDelete(perform: deleteStates)
                
                if gameStates.isEmpty {
                    Text("No content.")
                }
            }
            .navigationTitle(NSLocalizedString("Saved Games", comment: ""))
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif
            }
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
    
    func deleteStates(at offsets: IndexSet) {
        for index in offsets {
            let state = gameStates[index]
            modelContext.delete(state)
        }
    }
    
    private func deleteState(_ state: GameState) {
        modelContext.delete(state)
    }
}
