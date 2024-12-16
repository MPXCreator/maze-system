//
//  SettingView.swift
//  Maze System
//

import SwiftUI

enum ThemeSetting: String, CaseIterable, Codable {
    case light
    case dark
    case automatic
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .automatic: return "Automatic"
        }
    }
}

struct SettingView: View {
    @AppStorage("defualtAuthor") private var defualtAuthor: String = "Somebody"
    @AppStorage("selectedTheme") private var selectedTheme: ThemeSetting = .automatic
    @AppStorage("pathfindingMethod") private var pathfindingMethod: PathMethod = .astar
    @AppStorage("autoReturnToMain") private var autoReturnToMain: Bool = true
    @AppStorage("defaultPlayerEmoji") private var defaultPlayerEmoji: String = "🧑‍💻"
    @AppStorage("displayMazeIcon") private var displayMazeIcon: Bool = true

    @State private var showEmojiPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("General")) {
                    HStack {
                        Image(systemName: "person.circle")
                        TextField("Default Author Name", text: $defualtAuthor)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(ThemeSetting.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }

                    Toggle("Auto Return to Main after Finishing", isOn: $autoReturnToMain)
                    Toggle("Display Maze Icon", isOn: $displayMazeIcon)
                }
                
                Section(header: Text("Player")) {
                    HStack {
                        Text("Default Player Emoji")
                        Spacer()
                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            Text(defaultPlayerEmoji)
                                .font(.largeTitle)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section(header: Text("Pathfinding")) {
                    Picker("Algorithm", selection: $pathfindingMethod) {
                        ForEach(PathMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: selectedTheme) { _, newValue in
                applyTheme(newValue)
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $defaultPlayerEmoji) { emoji in
                    defaultPlayerEmoji = emoji
                    showEmojiPicker = false
                }
            }
        }
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
