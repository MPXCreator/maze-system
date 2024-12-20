//
//  DesignerStartView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData

struct DesignerStartView: View {
    @Environment(\.modelContext) var modelContext
    @Query var drafts: [Draft]
    
    @AppStorage("defualtAuthor") private var defualtAuthor: String = "Somebody"
    
    @State var ndraft: Draft?
    @State var isEditorActive = false
    @State var showSavedDrafts = false
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "pencil.and.outline")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()
            Text(LocalizedStringKey("Designer"))
                .font(.largeTitle)
            
            HStack {
                Spacer()
                
                Button {
                    ndraft = Draft(metadata: Metadata(name: "Mazes", author: defualtAuthor, version: "0.0.1"))
                    isEditorActive = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(LocalizedStringKey("New Config"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    showSavedDrafts = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        Text(NSLocalizedString("Saved Draft", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showSavedDrafts) {
                    DraftListView(onSelect: { draft in
                        ndraft = Draft(
                            metadata: draft.metadata,
                            start: draft.start,
                            end: draft.end,
                            mazes: draft.mazes
                        )
                        isEditorActive = true
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
        .navigationTitle(LocalizedStringKey("Designer"))
#if os(iOS)
        .navigationBarHidden(true)
#endif
        .navigationDestination(isPresented: $isEditorActive) {
            if let draft = ndraft {
                DraftEditView(draft: draft)
            } else {
                Text("Wrong data.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        DesignerStartView()
            .modelContainer(for: [Draft.self])
    }
}
