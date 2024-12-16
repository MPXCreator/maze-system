//
//  Maze_SystemApp.swift
//  Maze System
//

import SwiftUI
import SwiftData

@main
struct Maze_SystemApp: App {
    #if os(macOS)
    @AppStorage("enableKeyboardMovement") private var enableKeyboardMovement = false
    @StateObject var globalGameController = GlobalGameControllerHolder()
    #endif

    @Environment(\.scenePhase) var scenePhase
    @AppStorage("selectedTheme") private var selectedTheme: ThemeSetting = .automatic

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [GameState.self, Draft.self])
            #if os(macOS)
                .environmentObject(globalGameController)
            #endif
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        applyTheme(selectedTheme)
                    }
                }
        }
        #if os(macOS)
        .commands {
            CommandGroup(after: .appSettings) {
                if enableKeyboardMovement,
                   let gameController = globalGameController.gameController,
                   gameController.showTaskSheet == false,
                   gameController.activeAlert == nil {
                    Button("Move Up") {
                        gameController.moveBy(dx: -1, dy: 0)
                    }.keyboardShortcut(.upArrow, modifiers: [])
                    
                    Button("Move Down") {
                        gameController.moveBy(dx: 1, dy: 0)
                    }.keyboardShortcut(.downArrow, modifiers: [])
                    
                    Button("Move Left") {
                        gameController.moveBy(dx: 0, dy: -1)
                    }.keyboardShortcut(.leftArrow, modifiers: [])
                    
                    Button("Move Right") {
                        gameController.moveBy(dx: 0, dy: 1)
                    }.keyboardShortcut(.rightArrow, modifiers: [])

                    Button("Move W") {
                        gameController.moveBy(dx: -1, dy: 0)
                    }.keyboardShortcut("w", modifiers: [])

                    Button("Move A") {
                        gameController.moveBy(dx: 0, dy: -1)
                    }.keyboardShortcut("a", modifiers: [])

                    Button("Move S") {
                        gameController.moveBy(dx: 1, dy: 0)
                    }.keyboardShortcut("s", modifiers: [])

                    Button("Move D") {
                        gameController.moveBy(dx: 0, dy: 1)
                    }.keyboardShortcut("d", modifiers: [])
                }
            }
        }
        #endif
    }

    private func applyTheme(_ theme: ThemeSetting) {
        #if os(iOS)
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }

            switch theme {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .automatic:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        #elseif os(macOS)
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .automatic:
            NSApp.appearance = nil
        }
        #endif
    }
}

#if os(macOS)
class GlobalGameControllerHolder: ObservableObject {
    @Published var gameController: GameController?
}
#endif
