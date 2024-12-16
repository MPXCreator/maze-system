//
//  GameStartView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData

struct GameStartView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showConfigurationView: Bool = false
    @State private var showSavedGames: Bool = false
    @State private var selectedGameState: GameState?
    @State private var loadSavedGame: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("Maze")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .cornerRadius(30)
                
                Text(NSLocalizedString("Welcome to Maze System!", comment: ""))
                    .font(.largeTitle)
                
                HStack {
                    Spacer()
                    
                    Button {
                        // 显示配置界面
                        showConfigurationView = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(NSLocalizedString("Start", comment: ""))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .navigationDestination(isPresented: $showConfigurationView) {
                        ConfigurationView()
                    }
                    
                    Button {
                        // 显示保存的游戏状态列表
                        showSavedGames = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            Text(NSLocalizedString("Saved Games", comment: ""))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showSavedGames) {
                        GameStateListView(onSelect: { state in
                            selectedGameState = state
                            showSavedGames = false
                            loadSavedGame = true
                        })
                        .frame(minHeight: 300)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: 400)
                .padding()
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationDestination(for: GameState.self) { gameState in
                GameView(gameController: GameController(gameState: gameState))
            }
            .navigationDestination(isPresented: $loadSavedGame) {
                if let gameState = selectedGameState {
                    GameView(gameController: GameController(gameState: gameState))
                } else {
                    Text("Error content.")
                }
            }
        }
    }
}
#Preview {
    GameStartView()
}
