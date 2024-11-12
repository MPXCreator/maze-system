//
//  DraftListView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData

struct DraftListView: View {
    @Environment(\.modelContext) var modelContext
    @Query var drafts: [Draft]
    
    var body: some View {
        List {
            ForEach(drafts) { draft in
                NavigationLink(destination: {
                    DesignerEditView(draft: draft)
                }) {
                    VStack(alignment: .leading) {
                        Text(draft.metadata.name)
                        Text("\(LocalizedStringKey("Author")): \(draft.metadata.author)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        deleteDraft(draft)
                    } label: {
                        Text(LocalizedStringKey("Delete"))
                        Image(systemName: "trash")
                    }
                }
            }
            .onDelete(perform: deleteDrafts)
            
            if drafts.isEmpty {
                Text(LocalizedStringKey("No content."))
            }
        }
        .navigationTitle(LocalizedStringKey("Saved Drafts"))
        .toolbar {
            #if os(iOS)
            EditButton()
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
