//
//  EmojiPickerView.swift
//  Maze System
//
//  Created by Reyes on 11/6/24.
//

import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    var onEmojiSelected: (String) -> Void

    let emojis = ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣",
                  "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰",
                  "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜",
                  "🤪", "🤨", "🧐", "🤓", "😎", "🥸", "🤩", "🥳"]

    var body: some View {
        #if os(iOS) || os(tvOS)
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 40))
                            .onTapGesture {
                                selectedEmoji = emoji
                                onEmojiSelected(emoji)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Select an Emoji", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "")) {
                        onEmojiSelected(selectedEmoji)
                    }
                }
            }
        }
        #elseif os(macOS)
        VStack {
            Text(NSLocalizedString("Select an Emoji", comment: ""))
                .font(.headline)
                .padding()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 30))
                            .onTapGesture {
                                selectedEmoji = emoji
                                onEmojiSelected(emoji)
                            }
                    }
                }
                .padding()
            }
            HStack {
                Button(NSLocalizedString("Cancel", comment: "")) {
                    onEmojiSelected(selectedEmoji)
                }
                Button(NSLocalizedString("Done", comment: "")) {
                    onEmojiSelected(selectedEmoji)
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}
