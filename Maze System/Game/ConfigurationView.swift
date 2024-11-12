//
//  ConfigurationView.swift
//  Maze System
//
//  Created by Reyes on 11/6/24.
//

import SwiftUI
import CodeEditor

struct ConfigurationView: View {
    @State private var configurationText: String = ""
    @State private var showFileImporter: Bool = false
    @State private var showGameView: Bool = false
    @State private var errorMessage: String = ""
    @State private var gameController: GameController?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Text("选择配置文件")
                    }
                    .padding()

                    Spacer()
                }

                CodeEditor(source: $configurationText, language: .json)
                    .frame(minHeight: 300)
                    .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    // 解析配置文件并初始化 GameController
                    // 这里暂时留空，您可以之后自行补充解析逻辑
                    // 以下是一个示例，您可以根据需要修改或完善
                    /*
                    do {
                        let data = configurationText.data(using: .utf8)!
                        let decoder = JSONDecoder()
                        let configuration = try decoder.decode(GameConfiguration.self, from: data)
                        // 初始化 GameController
                        self.gameController = GameController(configuration: configuration)
                        self.showGameView = true
                    } catch {
                        errorMessage = "解析配置文件失败：\(error.localizedDescription)"
                    }
                    */
                    // 暂时直接初始化一个默认的 GameController，供测试使用
                    self.gameController = GameController()
                    self.showGameView = true
                }) {
                    Text("确定")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("配置")
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        if let content = String(data: data, encoding: .utf8) {
                            configurationText = content
                        }
                    } catch {
                        errorMessage = "读取文件失败：\(error.localizedDescription)"
                    }
                case .failure(let error):
                    errorMessage = "选择文件失败：\(error.localizedDescription)"
                }
            }
            .navigationDestination(isPresented: $showGameView) {
                if let gameController = gameController {
                    GameView(gameController: gameController)
                } else {
                    Text("初始化游戏失败")
                }
            }
        }
    }
}
