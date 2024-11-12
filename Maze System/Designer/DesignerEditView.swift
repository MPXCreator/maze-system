//
//  DesignerEditView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DesignerEditView: View {
    @ObservedObject var draft: Draft
    @Environment(\.modelContext) private var modelContext

    @State private var showInputForm = false
    @State private var mazeName = ""
    @State private var rows = ""
    @State private var columns = ""
    @State private var mazeType = MazeType.normal
    @State private var genMethod = GenMethod.dfs

    @State private var isExporting = false
    @State private var exportData: Data?

    @State private var showSavedPrompt = false
    @State private var showSaveFailurePrompt = false
    @State private var showExportSuccessPrompt = false
    @State private var showExportFailurePrompt = false

    // State variables for error handling
    @State private var showErrorPrompt = false
    @State private var errorMessage = ""

    // State variable for selection
    @State private var selection: DesignerSelection?

    var body: some View {
        ZStack {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                navigationStack
            } else {
                //navigationSplitView
                navigationStack
            }
            #else
            navigationSplitView
            #endif

            // Prompt Views
            if showSavedPrompt {
                successPromptView(imageName: "checkmark.circle", message: "Saved")
            }
            if showSaveFailurePrompt {
                failurePromptView(imageName: "xmark.circle", message: "Save Failed")
            }
            if showExportSuccessPrompt {
                successPromptView(imageName: "checkmark.circle", message: "Exported")
            }
            if showExportFailurePrompt {
                failurePromptView(imageName: "xmark.circle", message: "Export Failed")
            }
            if showErrorPrompt {
                errorPromptView(message: errorMessage)
            }
        }
        .fileExporter(isPresented: $isExporting, document: JSONDataDocument(data: exportData ?? Data()), contentType: .json, defaultFilename: "\(draft.metadata.name).json") { result in
            handleExportResult(result)
        }
        .sheet(isPresented: $showInputForm) {
            addMazeForm
        }
    }

    private var content: some View {
        List {
            metadataSection
            entryExitSection
            mazesSection
        }
    }
    
    // for iOS
    private var navigationStack: some View {
        content
            .navigationTitle(draft.metadata.name)
            .navigationDestination(for: DesignerSelection.self) { selection in
                detailView(for: selection)
            }
            .toolbar {
                toolbarContent
            }
    }
    
    // for macOS
    private var navigationSplitView: some View {
        NavigationSplitView {
            List(selection: $selection) {
                metadataSection

                Section(LocalizedStringKey("Entry & Exit")) {
                    entryExitButtons
                }

                mazesSection
            }
            .navigationTitle(draft.metadata.name)
        } detail: {
            if let selection = selection {
                detailView(for: selection)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .scaledToFit()
                        .padding()
                    Text("Select an item or add a maze.")
                        .font(.title)
                    Spacer()
                }
                .padding()
            }
        }
        .toolbar {
            toolbarContent
        }
    }

    @ViewBuilder
    private func detailView(for selection: DesignerSelection) -> some View {
        switch selection {
        case .entry:
            entryView
        case .exit:
            exitView
        case .maze(let id):
            if let maze = draft.mazes.first(where: { $0.id == id }) {
                MazeEditView(maze: maze)
                    .environmentObject(draft)
            } else {
                EmptyView()
            }
        }
    }

    private var metadataSection: some View {
        Section(LocalizedStringKey("Metadata")) {
            HStack {
                Image(systemName: "square.grid.2x2")
                TextField(LocalizedStringKey("Name"), text: $draft.metadata.name)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Image(systemName: "person.circle")
                TextField(LocalizedStringKey("Author"), text: $draft.metadata.author)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Image(systemName: "number.square")
                TextField(LocalizedStringKey("Version"), text: $draft.metadata.version)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var entryContent: some View {
        HStack {
            Image(systemName: "tray.and.arrow.down.fill")
            Text(LocalizedStringKey("Entry"))
            Spacer()
            if !draft.mazes.isEmpty {
                Text("\(draft.start.mazeID) | (\(draft.start.x), \(draft.start.y))")
                    .foregroundColor(.gray)
            } else {
                Text("None")
                    .foregroundColor(.gray)
            }
        }
    }

    private var exitContent: some View {
        HStack {
            Image(systemName: "tray.and.arrow.up.fill")
            Text(LocalizedStringKey("Exit"))
            Spacer()
            if !draft.mazes.isEmpty {
                Text("\(draft.end.mazeID) | (\(draft.end.x), \(draft.end.y))")
                    .foregroundColor(.gray)
            } else {
                Text("None")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var entryExitButtons: some View {
        Group {
            #if os(iOS)
            NavigationLink(destination: detailView(for: .entry)) {
                entryContent
            }
            #else
            NavigationLink(value: DesignerSelection.entry) {
                entryContent
            }
            #endif
            
            #if os(iOS)
            NavigationLink(destination: detailView(for: .exit)) {
                exitContent
            }
            #else
            NavigationLink(value: DesignerSelection.exit) {
                exitContent
            }
            #endif
        }
    }

    private var entryExitSection: some View {
        Section(LocalizedStringKey("Entry & Exit")) {
            entryExitButtons
        }
    }

    private var mazesSection: some View {
        Section(LocalizedStringKey("Mazes")) {
            ForEach(draft.mazes) { maze in
                #if os(iOS)
                NavigationLink(destination: detailView(for: .maze(id: maze.id))) {
                    Text(maze.id)
                }
                #else
                NavigationLink(value: DesignerSelection.maze(id: maze.id)) {
                    Text(maze.id)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        if let index = draft.mazes.firstIndex(where: { $0.id == maze.id }) {
                            draft.mazes.remove(at: index)
                        }
                    } label: {
                        Text(LocalizedStringKey("Delete Maze"))
                        Image(systemName: "trash")
                    }
                }
                #endif
            }
            .onDelete(perform: deleteItems)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        #endif
        ToolbarItem {
            Button(action: { showInputForm = true }) {
                Label(LocalizedStringKey("Add Maze"), systemImage: "plus")
            }
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #endif
        }
        ToolbarItem {
            Button(action: { saveDraft() }) {
                Label(LocalizedStringKey("Save Draft"), systemImage: "square.and.arrow.down.badge.clock")
            }
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #endif
        }
        ToolbarItem {
            Button(action: { exportConfig() }) {
                Label(LocalizedStringKey("Export Config"), systemImage: "square.and.arrow.up")
            }
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #endif
        }
    }

    private var addMazeForm: some View {
        VStack(spacing: 15) {
            VStack(spacing: 5) {
                Text(LocalizedStringKey("Maze Parameters"))
                    .font(.headline)
                    .padding(.top, 10)

                Text(LocalizedStringKey("Please enter maze name and size"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Divider()

            List {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    TextField(LocalizedStringKey("Maze Name"), text: $mazeName)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    TextField(LocalizedStringKey("Rows"), text: $rows)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    TextField(LocalizedStringKey("Columns"), text: $columns)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                
                Picker(selection: $mazeType, label: Image(systemName: "apple.intelligence")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)) {
                    Text(LocalizedStringKey("Normal")).tag(MazeType.normal)
                    Text(LocalizedStringKey("Task")).tag(MazeType.task)
                }
                .pickerStyle(.segmented)

                Picker(selection: $genMethod, label: Image(systemName: "function")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)) {
                    Text("DFS").tag(GenMethod.dfs)
                    Text("Prim").tag(GenMethod.prim)
                    Text("Kruskal").tag(GenMethod.kruskal)
                }
                .pickerStyle(.segmented)
            }
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            //.padding(.horizontal, 20)

            Button(action: {
                addMaze()
                withAnimation {
                    showInputForm = false
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(LocalizedStringKey("Confirm"))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
            }
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #endif
            .padding(.top, 10)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 350)
        .cornerRadius(12)
        .padding()
    }

    private func addMaze() {
        // Trim whitespace and check for empty name
        let trimmedName = mazeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Maze name cannot be empty."
            withAnimation {
                showErrorPrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showErrorPrompt = false
                }
            }
            return
        }

        // Check for duplicate maze names
        if draft.mazes.contains(where: { $0.id.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            errorMessage = "A maze with this name already exists."
            withAnimation {
                showErrorPrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showErrorPrompt = false
                }
            }
            return
        }

        // Validate rows and columns
        guard let h = Int(rows), let w = Int(columns), h >= 15, w >= 15 else {
            errorMessage = "Rows and Columns must be integers >= 15."
            withAnimation {
                showErrorPrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showErrorPrompt = false
                }
            }
            return
        }

        // Add the maze
        let newMaze = MazeConfig(id: trimmedName, type: mazeType, height: h, width: w, method: genMethod, portals: [], tasks: [])
        draft.mazes.append(newMaze)

        // If it's the first maze, set start and end positions
        if draft.mazes.count == 1 {
            draft.start = Position(mazeID: newMaze.id, x: 1, y: 1)
            draft.end = Position(mazeID: newMaze.id, x: 1, y: 1)
        }

        // Reset input fields
        mazeName = ""
        rows = ""
        columns = ""
        mazeType = .normal
        genMethod = .dfs
    }

    private func deleteItems(offsets: IndexSet) {
        draft.mazes.remove(atOffsets: offsets)
    }

    // Entry View
    private var entryView: some View {
        VStack {
            List {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                        Text(LocalizedStringKey("Entry"))
                            .font(.largeTitle)
                        Text(LocalizedStringKey("Here's the start position of the game."))
                    }
                    Spacer()
                }

                if !draft.mazes.isEmpty {
                    Picker(selection: $draft.start.mazeID, label: Text(LocalizedStringKey("Maze"))) {
                        ForEach(draft.mazes) { maze in
                            Text(maze.id).tag(maze.id)
                        }
                    }
                } else {
                    Text(LocalizedStringKey("There's no maze in the game."))
                }
            }

            if let maze = draft.mazes.first(where: { $0.id == draft.start.mazeID }) {
                HStack {
                    Picker(selection: $draft.start.x, label: Text(LocalizedStringKey("Row"))) {
                        ForEach(1...maze.height, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(InlinePickerStyle())
                    #endif

                    Spacer()

                    Divider()

                    Spacer()

                    Picker(selection: $draft.start.y, label: Text(LocalizedStringKey("Column"))) {
                        ForEach(1...maze.width, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(InlinePickerStyle())
                    #endif
                }
                .frame(height: 50)

                MazePreview(marked: (draft.start.x, draft.start.y))
                    .environmentObject(Maze(
                        id: maze.id,
                        height: maze.height,
                        width: maze.width,
                        portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
                        tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
                        method: maze.method
                    ))
                    .padding()
                    .id(draft.start.mazeID)
            }
        }
        .navigationTitle(LocalizedStringKey("Entry"))
    }

    // Exit View
    private var exitView: some View {
        VStack {
            List {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "tray.and.arrow.up.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                        Text(LocalizedStringKey("Exit"))
                            .font(.largeTitle)
                        Text(LocalizedStringKey("Here's the end position of the game."))
                    }
                    Spacer()
                }

                if !draft.mazes.isEmpty {
                    Picker(selection: $draft.end.mazeID, label: Text(LocalizedStringKey("Maze"))) {
                        ForEach(draft.mazes) { maze in
                            Text(maze.id).tag(maze.id)
                        }
                    }
                } else {
                    Text(LocalizedStringKey("There's no maze in the game."))
                }
            }

            if let maze = draft.mazes.first(where: { $0.id == draft.end.mazeID }) {
                HStack {
                    Picker(selection: $draft.end.x, label: Text(LocalizedStringKey("Row"))) {
                        ForEach(1...maze.height, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(InlinePickerStyle())
                    #endif

                    Spacer()

                    Divider()

                    Spacer()

                    Picker(selection: $draft.end.y, label: Text(LocalizedStringKey("Column"))) {
                        ForEach(1...maze.width, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(InlinePickerStyle())
                    #endif
                }
                .frame(height: 50)

                MazePreview(marked: (draft.end.x, draft.end.y))
                    .environmentObject(Maze(
                        id: maze.id,
                        height: maze.height,
                        width: maze.width,
                        portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
                        tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
                        method: maze.method
                    ))
                    .padding()
            }
        }
        .navigationTitle(LocalizedStringKey("Exit"))
    }

    private func exportConfig() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let codableDraft = CodableDraft(from: draft)
            let data = try encoder.encode(codableDraft)
            exportData = data
            isExporting = true
        } catch {
            print("Failed to encode draft: \(error)")
            // Show export failure prompt
            withAnimation {
                showExportFailurePrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showExportFailurePrompt = false
                }
            }
        }
    }

    private func saveDraft() {
        do {
            modelContext.insert(draft)
            try modelContext.save()
            // Show save success prompt
            withAnimation {
                showSavedPrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSavedPrompt = false
                }
            }
        } catch {
            print("Failed to save draft: \(error)")
            // Show save failure prompt
            withAnimation {
                showSaveFailurePrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSaveFailurePrompt = false
                }
            }
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        // Handle result
        switch result {
        case .success(let url):
            print("Exported to \(url)")
            // Show export success prompt
            withAnimation {
                showExportSuccessPrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showExportSuccessPrompt = false
                }
            }
        case .failure(let error):
            print("Failed to export: \(error)")
            // Show export failure prompt
            withAnimation {
                showExportFailurePrompt = true
            }
            // Hide prompt after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showExportFailurePrompt = false
                }
            }
        }
        // Reset isExporting to false
        isExporting = false
    }

    // Success prompt view
    private func successPromptView(imageName: String, message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    VisualEffectBlur()
                        .frame(width: 150, height: 150)
                        .cornerRadius(20)
                    VStack {
                        Image(systemName: imageName)
                            .resizable()
                            .foregroundColor(.green)
                            .frame(width: 80, height: 80)
                        Text(message)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity)
    }

    // Failure prompt view
    private func failurePromptView(imageName: String, message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    VisualEffectBlur()
                        .frame(width: 150, height: 150)
                        .cornerRadius(20)
                    VStack {
                        Image(systemName: imageName)
                            .resizable()
                            .foregroundColor(.red)
                            .frame(width: 80, height: 80)
                        Text(message)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity)
    }

    // Error prompt view
    private func errorPromptView(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    VisualEffectBlur()
                        .frame(width: 300, height: 150)
                        .cornerRadius(20)
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .foregroundColor(.red)
                            .frame(width: 60, height: 60)
                        Text(message)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity)
    }
}

// 定义选择枚举
enum DesignerSelection: Hashable {
    case entry
    case exit
    case maze(id: String)
}

// 自定义模糊效果视图，适用于 iOS 和 macOS
struct VisualEffectBlur: View {
    #if os(iOS)
    var style: UIBlurEffect.Style = .systemMaterial

    var body: some View {
        BlurView(style: style)
            .ignoresSafeArea()
    }
    #else
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    var body: some View {
        BlurView(material: material, blendingMode: blendingMode)
            .ignoresSafeArea()
    }
    #endif
}

#if os(iOS)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
#else
struct BlurView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let nsView = NSVisualEffectView()
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
        return nsView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

struct JSONDataDocument: FileDocument {
    static let readableContentTypes = [UTType.json]

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

struct DesignerEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DesignerEditView(draft: Draft())
                .modelContainer(for: Draft.self)
        }
    }
}
