//
//  DraftListView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData

struct DraftListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var drafts: [Draft]
    
    var onSelect: (Draft) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(drafts) { draft in
                    HStack {
                        Text(draft.metadata.name)
                        Text("By \(draft.metadata.author)")
                        Text("Version \(draft.metadata.version)")
                        Spacer()
                        #if os(macOS)
                        Button(action: {
                            modelContext.delete(draft)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteDraft(draft)
                        } label: {
                            Text(LocalizedStringKey("Delete"))
                            Image(systemName: "trash")
                        }
                    }
                    .onTapGesture {
                        let nD = Draft(
                            metadata: draft.metadata,
                            start: draft.start,
                            end: draft.end,
                            mazes: draft.mazes
                        )
                        
                        onSelect(nD)
                        dismiss()
                    }
                }
                .onDelete(perform: deleteDrafts)
                
                if drafts.isEmpty {
                    Text(LocalizedStringKey("No content."))
                }
            }
            .navigationTitle(LocalizedStringKey("Saved Drafts"))
            #if os(iOS)
            .toolbar {
                EditButton()
            }
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
    
    func deleteDrafts(at offsets: IndexSet) {
        for index in offsets {
            let draft = drafts[index]
            modelContext.delete(draft)
        }
    }
    
    private func deleteDraft(_ draft: Draft) {
        modelContext.delete(draft)
    }
}
