//
//  ConfigurationView.swift
//  Maze System
//

import SwiftUI
import CodeEditorView
import LanguageSupport
import UniformTypeIdentifiers

enum Language: Hashable {
    case swift
    case haskell

    var configuration: LanguageConfiguration {
        switch self {
        case .swift: return .swift()
        case .haskell: return .haskell()
        }
    }
}

struct ConfigurationView: View {
    @State private var configurationText: String = ""
    @State private var errorMessage: String = ""
    @State private var gameController: GameController?
    @State private var showGameView: Bool = false
    @State private var isImporting: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    @State private var position: CodeEditor.Position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = Set()
    @State private var language: Language = .swift
    
    @AppStorage("defaultPlayerEmoji") private var defaultPlayerEmoji: String = "🧑‍💻"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    Text("Load Configuration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("You can drag and drop a JSON configuration file here or use the button below to select one. The file content will be displayed in the text box for review or minor edits.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 拖拽区域
                    VStack(spacing: 15) {
                        Text("Drag & Drop a configuration file here")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "doc.text.fill.viewfinder")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        
                        Text("or")
                            .foregroundColor(.secondary)
                        
                        Button {
                            isImporting = true
                        } label: {
                            Label("Select Configuration File", systemImage: "folder.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .onDrop(of: [UTType.json], isTargeted: nil) { providers in
                        if let provider = providers.first {
                            _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, error in
                                if let data = data, let content = String(data: data, encoding: .utf8) {
                                    DispatchQueue.main.async {
                                        configurationText = content
                                        errorMessage = ""
                                    }
                                } else if let error = error {
                                    DispatchQueue.main.async {
                                        errorMessage = "Failed to read file: \(error.localizedDescription)"
                                    }
                                }
                            }
                        }
                        return true
                    }
                    
                    // 文本内容查看与编辑区
                    Section {
                        CodeEditor(text: $configurationText, position: $position, messages: $messages, language: language.configuration)
                            .environment(\.codeEditorTheme,
                                          colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
                            .frame(minHeight: 200)
                            .padding()
                    } header: {
                        Text("Configuration Content")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, 2)
                    }
                    
                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.vertical, 4)
                    }
                    
                    // 操作区
                    HStack {
                        Spacer()
                        Button {
                            startGame()
                        } label: {
                            Label("Start Game", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(configurationText.isEmpty ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(configurationText.isEmpty)
                        Spacer()
                    }
                    
                    Spacer()
                    
                }
                .padding()
                .navigationTitle("Configuration")
                .navigationDestination(isPresented: $showGameView) {
                    if let gameController = gameController {
                        GameView(gameController: gameController)
                    } else {
                        Text("Error loading game.")
                    }
                }
                .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                    switch result {
                    case .success(let url):
                        do {
                            let data = try Data(contentsOf: url)
                            if let content = String(data: data, encoding: .utf8) {
                                configurationText = content
                                errorMessage = ""
                            }
                        } catch {
                            errorMessage = "Failed to read file: \(error.localizedDescription)"
                        }
                    case .failure(let error):
                        errorMessage = "Failed to select file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func startGame() {
        guard !configurationText.isEmpty else {
            errorMessage = "No configuration loaded."
            return
        }
        do {
            let data = configurationText.data(using: .utf8)!
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(GameConfiguration.self, from: data)
            if let gameState = createGameState(from: configuration) {
                gameState.player.emoji = defaultPlayerEmoji
                self.gameController = GameController(gameState: gameState)
                self.showGameView = true
            } else {
                errorMessage = "Failed to create game state."
            }
        } catch {
            errorMessage = "Failed to parse configuration: \(error.localizedDescription)"
        }
    }
    
    func platformBackgroundColor() -> Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
}
