//
//  GameView.swift
//  Maze System
//

import SwiftUI
import SwiftData

struct GameView: View {
    @ObservedObject var gameController: GameController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("autoReturnToMain") private var autoReturnToMain: Bool = true
    @AppStorage("displayMazeIcon") private var displayMazeIcon: Bool = true
    #if os(macOS)
    @AppStorage("enableKeyboardMovement") private var enableKeyboardMovement: Bool = false
    @EnvironmentObject var globalGameController: GlobalGameControllerHolder
    #endif

    @State private var showEmojiPicker: Bool = false
    @State private var answerInput: String = ""
    @State private var splitRatio: CGFloat = 0.5 // 上下分屏比例
    @State private var isExporting = false
    @State private var exportData: Data?

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let topHeight = totalHeight * splitRatio
            let bottomHeight = totalHeight - topHeight

            VStack(spacing: 0) {
                topMazeView
                    .frame(height: topHeight)

                Divider()
                    .background(Color.gray)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newRatio = (topHeight + value.translation.height) / totalHeight
                                splitRatio = min(max(newRatio, 0.2), 0.8)
                            }
                    )

                bottomInfoView
                    .frame(height: bottomHeight)
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: Binding(
                get: { gameController.gameState.player.emoji },
                set: { newEmoji in
                    gameController.gameState.player.emoji = newEmoji
                }
            )) { emoji in
                showEmojiPicker = false
            }
        }
        .sheet(isPresented: $gameController.showTaskSheet) {
            TaskAlertView(
                question: gameController.taskQuestion,
                answer: $answerInput,
                onSubmit: { success in
                    gameController.taskAnswer = answerInput
                    gameController.taskCompletionHandler?(success)
                    answerInput = ""
                    gameController.showTaskSheet = false
                }
            )
        }
        .alert(item: $gameController.activeAlert) { alertType in
            switch alertType {
            case .portal:
                return Alert(
                    title: Text("Portal"),
                    message: Text(gameController.portalDescription),
                    primaryButton: .default(Text("Enter"), action: {
                        gameController.enterPortal()
                    }),
                    secondaryButton: .cancel(Text("Cancel"), action: {
                        gameController.declinePortal()
                    })
                )
            case .insufficientScore:
                return Alert(
                    title: Text("Portal Unavailable"),
                    message: Text(gameController.insufficientScoreAlertMessage),
                    dismissButton: .default(Text("OK")) {
                        gameController.activeAlert = nil
                    }
                )
            case .saveConfirmation(let success):
                return Alert(
                    title: Text(success ? "Saved Successfully" : "Fail to Save"),
                    message: Text(success ? "Your current game state has been saved." : "An error occurred while saving."),
                    dismissButton: .default(Text("OK")) {
                        gameController.activeAlert = nil
                    }
                )
            case .endReached:
                return Alert(
                    title: Text("Game Over"),
                    message: Text(gameController.endAlertMessage),
                    dismissButton: .default(Text("OK")) {
                        gameController.finishGame()
                        if autoReturnToMain {
                            dismiss()
                        } else {
                            gameController.gameFinished = true
                        }
                    }
                )
            case .pathNotFound:
                return Alert(
                    title: Text("Unable to Find Path"),
                    message: Text("Automatic pathfinding cannot find a path to the target."),
                    dismissButton: .default(Text("OK")) {
                        gameController.activeAlert = nil
                    }
                )
            }
        }
        .fileExporter(isPresented: $isExporting, document: PNGDataDocument(data: exportData ?? Data()), contentType: .png) { result in
            switch result {
            case .success:
                print("Export success.")
            case .failure(let error):
                print("Failed to export: \(error)")
            }
            isExporting = false
        }
        #if os(macOS)
        .onAppear() {
            globalGameController.gameController = self.gameController
        }
        #endif
    }

    var topMazeView: some View {
        return MazeView()
            .environmentObject(gameController)
            .padding()
    }

    var bottomInfoView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let twoColumns = width > 600

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    if twoColumns {
                        HStack(alignment: .top, spacing: 5) {
                            gameInfoSection
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            controlsSection
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    } else {
                        gameInfoSection
                        controlsSection
                    }

                    actionsSection
                }
                .padding()
            }
            .background(platformBackgroundColor())
        }
    }

    var gameInfoSection: some View {
        let maze = gameController.currentMaze
        return Section {
            VStack(alignment: .leading, spacing: 5) {
                Label {
                    let mazeName = maze.id
                    let mazeIcon = maze.type == .task ? "puzzlepiece.extension" : "cube.transparent"
                    HStack {
                        Text("Current Maze: \(mazeName)")
                        if displayMazeIcon {
                            Image(systemName: mazeIcon)
                                .foregroundColor(.blue)
                        }
                    }
                } icon: {
                    Image(systemName: "cube.transparent")
                        .foregroundColor(.blue)
                }
                .font(.headline)

                Label {
                    Text("Current Score: \(gameController.player.score)")
                } icon: {
                    Image(systemName: "gauge.high")
                        .foregroundColor(.green)
                }
                .font(.headline)

                if maze.type == .task {
                    let totalScore = maze.score
                    let current = min(gameController.currentMazePlayerScore, totalScore)
                    let enough = current >= totalScore
                    Label("Task Progress", systemImage: "chart.bar")
                        .font(.subheadline)

                    HStack(spacing: 5) {
                        ProgressView(value: Double(current), total: Double(totalScore))
                            .progressViewStyle(.linear)
                            .tint(enough ? .green : .yellow)
                            .frame(maxWidth: .infinity)

                        Image(systemName: enough ? "checkmark.circle" : "xmark.circle")
                            .foregroundColor(enough ? .green : .red)
                    }

                    Text("You have \(current) out of \(totalScore) points.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                let h = maze.height
                let w = maze.width
                let portalsCount = maze.portals.count
                let tasksCount = maze.tasks.count
                Text("Maze Size: \(h) x \(w)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("Portals: \(portalsCount), Tasks: \(tasksCount)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        } header: {
            Text("Game Info")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 2)
        }
    }

    var controlsSection: some View {
        return Section {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label("Auto Pathfinding", systemImage: "paperplane.circle")
                    Spacer()
                    Toggle("", isOn: $gameController.autoPathfindingEnabled)
                        #if os(iOS)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        #elseif os(macOS)
                        .toggleStyle(CheckboxToggleStyle())
                        #endif
                }

                HStack(spacing: 10) {
                    Label("Speed", systemImage: "speedometer")
                    Slider(value: $gameController.movementSpeed, in: 0.1...1.0)
                    Text(String(format: "%.2f", gameController.movementSpeed))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("Select a Role", systemImage: "person")
                    Spacer()
                    Button(action: {
                        showEmojiPicker = true
                    }) {
                        Text(gameController.gameState.player.emoji)
                            .font(.largeTitle)
                    }
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                }

                #if os(macOS)
                Divider()
                HStack {
                    Label("Keyboard Movement", systemImage: "keyboard")
                    Spacer()
                    Toggle("", isOn: $enableKeyboardMovement)
                        .toggleStyle(CheckboxToggleStyle())
                }
                Text("Use WASD or Arrow Keys to move one step.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                #endif

            }
            .padding(.top, 2)
        } header: {
            Text("Controls")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 2)
        }
    }

    var actionsSection: some View {
        return Section {
            VStack(alignment: .leading, spacing: 5) {
                Button(action: {
                    saveGameState()
                }) {
                    Label("Save Game State", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                #if os(macOS)
                .buttonStyle(BorderlessButtonStyle())
                #endif

                if gameController.gameFinished && !autoReturnToMain {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Return to Main Page", systemImage: "arrow.backward")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                }

                Button(action: {
                    takeMazeScreenshot()
                }) {
                    Label("Take Maze Screenshot", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
                #if os(macOS)
                .buttonStyle(BorderlessButtonStyle())
                #endif
            }
            .padding(.top, 2)
        } header: {
            Text("Actions")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 2)
        }
    }

    func saveGameState() {
        let mazes = gameController.gameState.mazes.map {
            Maze(
                id: $0.id,
                type: $0.type,
                height: $0.height,
                width: $0.width,
                nodes: $0.nodes,
                portals: $0.portals,
                tasks: $0.tasks,
                score: $0.score
            )
        }
        
        let player = Player(
            position: Position(mazeID: gameController.player.position.mazeID, x: gameController.player.position.x, y: gameController.player.position.y),
            score: gameController.player.score,
            emoji: gameController.player.emoji
        )
        
        let gameState = GameState(
            currentMaze: mazes.first { $0.id == gameController.currentMaze.id }!,
            mazes: mazes,
            player: player,
            startPosition: Position(mazeID: gameController.gameState.startPosition.mazeID, x: gameController.gameState.startPosition.x, y: gameController.gameState.startPosition.y),
            endPosition: Position(mazeID: gameController.gameState.endPosition.mazeID, x: gameController.gameState.endPosition.x, y: gameController.gameState.endPosition.y),
            mazeScores: gameController.gameState.mazeScores
        )

        modelContext.insert(gameState)
        do {
            try modelContext.save()
            gameController.activeAlert = .saveConfirmation(success: true)
        } catch {
            gameController.activeAlert = .saveConfirmation(success: false)
        }
    }

    func takeMazeScreenshot() {
        guard let data = generateMazeImage() else {
            print("Failed to generate image.")
            return
        }
        exportData = data
        isExporting = true
    }

    @MainActor
    func generateMazeImage() -> Data? {
        let maze = gameController.gameState.currentMaze
        let cellSize: CGFloat = 20
        let width = maze.width + 2
        let height = maze.height + 2
        let imageWidth = CGFloat(width) * cellSize
        let imageHeight = CGFloat(height) * cellSize

        let mazeForScreenshot = MazeView()
            .environmentObject(gameController)
            .frame(width: imageWidth, height: imageHeight)

        let renderer = ImageRenderer(content: mazeForScreenshot)
        renderer.scale = 1.0

        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return uiImage.pngData()
        } else {
            return nil
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            return pngData
        } else {
            return nil
        }
        #endif
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

import UniformTypeIdentifiers

struct PNGDataDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.png]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: data)
    }
}
