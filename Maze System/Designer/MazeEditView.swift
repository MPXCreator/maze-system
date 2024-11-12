//
//  MazeEditView.swift
//  Maze System
//
//  Created by Reyes on 10/27/24.
//

import SwiftUI

struct MazeEditView: View {
    @ObservedObject var maze: MazeConfig
    @EnvironmentObject var draft: Draft

    @State var name: String
    @State var type: MazeType
    @State var method: GenMethod
    @State var rows: String
    @State var cols: String
    @State var score: String
    @State var mazep: Maze
    
    @State var showPortalSheet = false
    @State var showTaskSheet = false

    init(maze: MazeConfig) {
        self._maze = ObservedObject(initialValue: maze)
        self._name = State(initialValue: maze.id)
        self._type = State(initialValue: maze.type)
        self._method = State(initialValue: maze.method)
        self._rows = State(initialValue: String(maze.height))
        self._cols = State(initialValue: String(maze.width))
        self._score = State(initialValue: String(maze.score))
        self._mazep = State(initialValue: Maze(
            id: maze.id,
            height: maze.height,
            width: maze.width,
            portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
            tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
            method: maze.method
        ))
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    //Text(LocalizedStringKey("Name"))
                    TextField(LocalizedStringKey("Name"), text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Picker(selection: $type, label: Text(LocalizedStringKey("Type"))) {
                    Text(LocalizedStringKey("Normal")).tag(MazeType.normal)
                    Text(LocalizedStringKey("Task")).tag(MazeType.task)
                }
                .pickerStyle(.segmented)

                Picker(selection: $method, label: Text(LocalizedStringKey("Algorithm"))) {
                    Text("DFS").tag(GenMethod.dfs)
                    Text("Prim").tag(GenMethod.prim)
                    Text("Kruskal").tag(GenMethod.kruskal)
                }
                .pickerStyle(.segmented)

                HStack {
                    TextField(LocalizedStringKey("Rows"), text: $rows)
                        .textFieldStyle(.roundedBorder)
                    TextField(LocalizedStringKey("Columns"), text: $cols)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    if let h = Int(rows), let w = Int(cols), h >= 15 && w >= 15 && !name.isEmpty {
                        if draft.start.mazeID == maze.id {
                            draft.start.mazeID = name
                        }
                        if draft.end.mazeID == maze.id {
                            draft.end.mazeID = name
                        }
                        maze.id = name
                        withAnimation {
                            maze.type = type
                        }
                        if maze.type == .normal {
                            maze.tasks = []
                            maze.score = 0
                        }
                        maze.method = method
                        maze.height = h
                        maze.width = w
                        mazep = Maze(
                            id: maze.id,
                            height: maze.height,
                            width: maze.width,
                            portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
                            tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
                            method: maze.method
                        )
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                        Text(LocalizedStringKey("Modify Maze Info"))
                    }
                }
                #if os(macOS)
                .buttonStyle(.borderedProminent)
                #endif
            }
            
            Section {
                Button(action: { showPortalSheet.toggle() }) {
                    HStack {
                        Image(systemName: "door.left.hand.closed")
                        Text(LocalizedStringKey("Portals"))
                    }
                }
                
                if maze.type == .task {
                    Button(action: { showTaskSheet.toggle() }) {
                        HStack {
                            Image(systemName: "function")
                            Text(LocalizedStringKey("Tasks"))
                        }
                    }
                }
            }

            MazePreview()
                .environmentObject(mazep)
                .padding()
                .frame(minHeight: 300)
        }
        .navigationTitle(maze.id)
        .sheet(isPresented: $showPortalSheet) {
            PortalListView()
                .environment(maze)
                .environment(draft)
                .frame(minHeight: 400)
        }
        .sheet(isPresented: $showTaskSheet) {
            NavigationStack {
                TaskEditView()
                    .environment(maze)
                    .frame(minHeight: 400)
            }
            .navigationTitle("Tasks")
        }
    }
}

struct PortalListView: View {
    @EnvironmentObject var maze: MazeConfig
    @EnvironmentObject var draft: Draft

    @State private var selection: PortalConfig?

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                ForEach(maze.portals) { portal in
                    NavigationLink(
                        destination: PortalEditView()
                            .environment(portal)
                            .environment(maze)
                            .environment(draft)
                    ) {
                        HStack {
                            if portal.from.mazeID == portal.to.mazeID {
                                Image(systemName: "point.forward.to.point.capsulepath")
                            } else {
                                Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                            }
                            VStack {
                                Text("\(portal.from.x), \(portal.from.y) ->")
                                Text("\(portal.to.x), \(portal.to.y) @ \(portal.to.mazeID)")
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = maze.portals.firstIndex(where: { $0.id == portal.id }) {
                                maze.portals.remove(at: index)
                            }
                        } label: {
                            Label(LocalizedStringKey("Delete"), systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            if let index = maze.portals.firstIndex(where: { $0.id == portal.id }) {
                                maze.portals.remove(at: index)
                            }
                        } label: {
                            Text(LocalizedStringKey("Delete Portal"))
                            Image(systemName: "trash")
                        }
                    }
                }
                .id(maze.portals.count)

                Button {
                    withAnimation {
                        maze.portals.append(PortalConfig(
                            from: Position(mazeID: maze.id, x: 1, y: 1),
                            to: Position(mazeID: maze.id, x: maze.height, y: maze.width)
                        ))
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.app")
                        Text(LocalizedStringKey("Add a portal."))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Portals"))
        }
    }
}

struct PortalEditView: View {
    @EnvironmentObject var portal: PortalConfig
    @EnvironmentObject var maze: MazeConfig
    @EnvironmentObject var draft: Draft

    var body: some View {
        List {
            Section(LocalizedStringKey("From")) {
                HStack {
                    Picker(selection: $portal.from.x, label: Text(LocalizedStringKey("Row"))) {
                        ForEach(1...maze.height, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #endif

                    Spacer()

                    Divider()

                    Spacer()

                    Picker(selection: $portal.from.y, label: Text(LocalizedStringKey("Column"))) {
                        ForEach(1...maze.width, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #endif
                }
                .frame(height: 50)

                MazePreview(marked: (portal.from.x, portal.from.y))
                    .environmentObject(Maze(
                        id: maze.id,
                        height: maze.height,
                        width: maze.width,
                        portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
                        tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
                        method: maze.method
                    ))
                    .padding()
                    .frame(minHeight: 300)
            }
            Section(LocalizedStringKey("To")) {
                Picker(selection: $portal.to.mazeID, label: Text(LocalizedStringKey("Maze"))) {
                    ForEach(draft.mazes) { maze in
                        Text(maze.id).tag(maze.id)
                    }
                }
                if let maze = draft.mazes.first(where: { $0.id == portal.to.mazeID }) {
                    HStack {
                        Picker(selection: $portal.to.x, label: Text(LocalizedStringKey("Row"))) {
                            ForEach(1...maze.height, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #endif

                        Spacer()

                        Divider()

                        Spacer()

                        Picker(selection: $portal.to.y, label: Text(LocalizedStringKey("Column"))) {
                            ForEach(1...maze.width, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #endif
                    }
                    .frame(height: 50)

                    MazePreview(marked: (portal.to.x, portal.to.y))
                        .environmentObject(Maze(
                            id: maze.id,
                            height: maze.height,
                            width: maze.width,
                            portals: maze.portals.map { Portal(from: $0.from, to: $0.to) },
                            tasks: maze.tasks.map { Task(position: $0.position, score: $0.score) },
                            method: maze.method
                        ))
                        .padding()
                        .id(portal.to.mazeID)
                        .frame(minHeight: 300)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("Edit Portal"))
    }
}

struct TaskEditView: View {
    @EnvironmentObject var maze: MazeConfig

    @State private var requiredScore = ""
    @State private var taskX: String = ""
    @State private var taskY: String = ""
    @State private var taskScore: String = ""

    var body: some View {
        List {
            Section {
                Picker(selection: $maze.score, label: Text(LocalizedStringKey("Rquired Score"))) {
                    ForEach(0...maze.tasks.reduce(0) { $0 + $1.score }, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                #endif
                
                HStack {
                    TextField("X", text: $taskX)
                        .textFieldStyle(.roundedBorder)
                    TextField("Y", text: $taskY)
                        .textFieldStyle(.roundedBorder)
                    TextField(LocalizedStringKey("Score"), text: $taskScore)
                        .textFieldStyle(.roundedBorder)

                    Button(LocalizedStringKey("Add")) {
                        if let x = Int(taskX), let y = Int(taskY), let score = Int(taskScore) {
                            let newTask = TaskConfig(score: score, position: Position(mazeID: maze.id, x: x, y: y))
                            
                            withAnimation {
                                maze.tasks.append(newTask)
                            }

                            taskX = ""
                            taskY = ""
                            taskScore = ""
                        }
                    }
                    #if os(macOS)
                    .buttonStyle(.borderedProminent)
                    #endif
                }
            }
            
            Section {
                ForEach(maze.tasks) { task in
                    HStack {
                        if task.score <= 20 {
                            Image(systemName: "plus.forwardslash.minus")
                        } else if task.score <= 30 {
                            Image(systemName: "angle")
                        } else {
                            Image(systemName: "sum")
                        }
                        VStack(alignment: .leading) {
                            Text("Task @(\(task.position.x), \(task.position.y))")
                            Text("\(LocalizedStringKey("Score")): \(task.score)")
                        }
                        Spacer()
                        #if os(macOS)
                        Button(action: {
                            if let index = maze.tasks.firstIndex(where: { $0.id == task.id }) {
                                maze.tasks.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        #endif
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = maze.tasks.firstIndex(where: { $0.id == task.id }) {
                                maze.tasks.remove(at: index)
                            }
                        } label: {
                            Label(LocalizedStringKey("Delete"), systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            if let index = maze.tasks.firstIndex(where: { $0.id == task.id }) {
                                maze.tasks.remove(at: index)
                            }
                        } label: {
                            Text(LocalizedStringKey("Delete Task"))
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey("Tasks"))
    }
}
