//
//  GameView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData

struct GameView: View {
    @ObservedObject var gameController: GameController

    @State private var showEmojiPicker: Bool = false
    @State private var selectedEmoji: String = "🧑‍💻"
    @State private var answerInput: String = ""
    @Environment(\.modelContext) private var modelContext // 引入 SwiftData 的 modelContext

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MazeView()
                    .environmentObject(gameController)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                    .padding()

                // 控制区域
                VStack {
                    HStack {
                        Text(String(format: NSLocalizedString("Current Score: %d", comment: ""), gameController.player.score))
                            .font(.headline)
                            .padding()

                        Spacer()

                        // Emoji 选择按钮
                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            HStack {
                                Text(NSLocalizedString("Select Character", comment: ""))
                                Text(gameController.player.emoji)
                                    .font(.largeTitle)
                            }
                        }
                        .padding()
                    }

                    HStack {
                        // 自动寻路开关
                        Toggle(isOn: $gameController.autoPathfindingEnabled) {
                            Text(NSLocalizedString("Auto Pathfinding", comment: ""))
                        }
                        #if os(iOS) || os(tvOS)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        #endif
                        .padding()

                        Spacer()

                        // 保存按钮
                        Button(action: {
                            saveGameState()
                        }) {
                            Text(NSLocalizedString("Save", comment: ""))
                        }
                        .padding()

                        Spacer()

                        // 速度调节滑块
                        HStack {
                            Text(NSLocalizedString("Speed:", comment: ""))
                            Slider(value: $gameController.movementSpeed, in: 0.1...1.0)
                            Text(String(format: "%.2f", gameController.movementSpeed))
                        }
                        .padding()
                    }
                }
                .background(platformBackgroundColor())
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji) { emoji in
                    gameController.player.emoji = emoji
                    showEmojiPicker = false
                }
            }
            .sheet(isPresented: $gameController.showTaskAlert) {
                TaskAlertView(question: gameController.taskQuestion, answer: $answerInput) {
                    // 用户点击了提交按钮
                    gameController.taskAnswer = answerInput
                    gameController.taskCompletionHandler?()
                    answerInput = ""
                }
            }
            .alert(isPresented: $gameController.showPortalAlert) {
                Alert(
                    title: Text(NSLocalizedString("Portal", comment: "")),
                    message: Text(gameController.portalDescription),
                    primaryButton: .default(Text(NSLocalizedString("Enter", comment: "")), action: {
                        gameController.enterPortal()
                    }),
                    secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")), action: {
                        gameController.declinePortal()
                    })
                )
            }
        }
    }

    // 保存游戏状态的函数
    func saveGameState() {
        let gameState = gameController.gameState

        // 更新时间戳
        gameState.timestamp = Date()

        // 将 gameState 插入到 modelContext 中，如果已经存在则会更新
        modelContext.insert(gameState)
    }

    // 跨平台的背景颜色函数
    func platformBackgroundColor() -> Color {
        #if os(iOS) || os(tvOS)
        return Color(UIColor.systemGray6)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
}
