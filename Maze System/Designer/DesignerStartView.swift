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
    
    @State var ndraft: Draft = Draft()
    @State var isEditorActive = false
    
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
                    ndraft = Draft()
                    isEditorActive = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(LocalizedStringKey("Create New Config"))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: {
                    DraftListView()
                        .environment(\.modelContext, modelContext)
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        Text(LocalizedStringKey("Saved Drafts"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
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
            DesignerEditView(draft: ndraft)
        }
    }
}

#Preview {
    NavigationStack {
        DesignerStartView()
            .modelContainer(for: [Draft.self])
    }
}
