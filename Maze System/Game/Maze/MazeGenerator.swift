//
//  MazeGenerator.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

enum GenMethod: String, Codable {
    case dfs, prim, kruskal
}

extension Maze {
    enum StateType {
        case wall, able, watch, confirm
    }
    
    func Generate(method: GenMethod) {
        Generate(height: self.height, width: self.width, method: method)
    }
    
    func Generate(height: Int, width: Int, method: GenMethod) {
        self.height = height
        self.width = width
        self.nodes = Array(repeating: .wall, count: (height + 2) * (width + 2))
        var states: [[StateType]] = Array(repeating: Array(repeating: .wall, count: self.width + 2), count: self.height + 2)
        for i in stride(from: 1, through: self.height, by: 2) {
            for j in stride(from: 1, through: self.width, by: 2) {
                states[i][j] = .able
            }
        }
        switch method {
        case .dfs: dfsGenerate(states: &states)
        case .prim: primGenerate(states: &states)
        case .kruskal: kruskalGenerate(states: &states)
        }
        for i in 1...self.height {
            for j in 1...self.width {
                self[i, j] = states[i][j] == .confirm ? .path : .wall
            }
        }
        for portal in portals {
            self[portal.from.x, portal.from.y] = .portal
        }
        if self.type == .task {
            for task in tasks {
                self[task.position.x, task.position.y] = .task
            }
        }
    }
}

extension Maze {
    var directions: [(Int, Int)] {
        return [(-1, 0), (0, 1), (1, 0), (0, -1)]
    }

    /// 检查指定位置是否有效且具有指定的状态
    func isValidPosition(_ x: Int, _ y: Int) -> Bool {
        return x > 0 && x <= self.height && y > 0 && y <= self.width
    }

    /// 深度优先搜索算法生成迷宫
    func dfsGenerate(states: inout [[StateType]]) {
        dfs(x: 1, y: 1, states: &states)
    }

    func dfs(x: Int, y: Int, states: inout [[StateType]]) {
        states[x][y] = .confirm
        for (dx, dy) in directions.shuffled() {
            let nx = x + dx * 2
            let ny = y + dy * 2
            if isValidPosition(nx, ny) && states[nx][ny] == .able {
                states[x + dx][y + dy] = .confirm
                dfs(x: nx, y: ny, states: &states)
            }
        }
    }

    /// Prim 算法生成迷宫
    func primGenerate(states: inout [[StateType]]) {
        prim(x: 1, y: 1, states: &states)
    }
    
    func prim(x: Int, y: Int, states: inout [[StateType]]) {
        states[x][y] = .confirm
        var cache: [(Int, Int, Int, Int)] = []
        for (dx, dy) in directions {
            if isValidPosition(x + dx, y + dy) && states[x + dx][y + dy] == .wall {
                states[x + dx][y + dy] = .watch
                cache.append((x + dx, y + dy, x + dx * 2, y + dy * 2))
            }
        }
        while !cache.isEmpty {
            let randomIndex: Int = Int.random(in: 0..<cache.count)
            let tmp = cache[randomIndex]
            cache.remove(at: randomIndex)
            if isValidPosition(tmp.2, tmp.3) && states[tmp.2][tmp.3] == .able {
                states[tmp.0][tmp.1] = .confirm
                prim(x: tmp.2, y: tmp.3, states: &states)
            }
            else {
                states[tmp.0][tmp.1] = .wall
            }
        }
    }

    /// Kruskal 算法生成迷宫
    func kruskalGenerate(states: inout [[StateType]]) {
        var wall_list: [(Int, Int)] = []
        for i in 1...self.height {
            for j in 1...self.width {
                if states[i][j] == .wall { wall_list.append((i, j)) }
            }
        }
        
        //并查集
        var father:[Int] = Array(0...Int(self.height * self.width))
        func find(_ x: Int) -> Int {
            if x != father[x] { father[x] = find(father[x]) }
            return father[x]
        }
        func unite(_ x: Int, _ y: Int) {
            if (find(x) != find(y)) { father[find(y)] = find(x) }
        }
        func calcIndex(_ x: Int, _ y: Int) -> Int { return (x - 1) * self.width + y }
        
        while !wall_list.isEmpty {
            let randomIndex = Int.random(in: 0..<wall_list.count)
            let tmp = wall_list[randomIndex]
            wall_list.remove(at: randomIndex)
            if states[tmp.0 - 1][tmp.1] == .able && states[tmp.0 + 1][tmp.1] == .able {
                if find(calcIndex(tmp.0 - 1, tmp.1)) != find(calcIndex(tmp.0 + 1, tmp.1)) {
                    unite(calcIndex(tmp.0 - 1, tmp.1), calcIndex(tmp.0 + 1, tmp.1))
                    father[calcIndex(tmp.0, tmp.1)] = find(calcIndex(tmp.0 - 1, tmp.1))
                    states[tmp.0][tmp.1] = .able
                }
            }
            else if states[tmp.0][tmp.1 - 1] == .able && states[tmp.0][tmp.1 + 1] == .able {
                if find(calcIndex(tmp.0, tmp.1 - 1)) != find(calcIndex(tmp.0, tmp.1 + 1)) {
                    unite(calcIndex(tmp.0, tmp.1 - 1), calcIndex(tmp.0, tmp.1 + 1))
                    father[calcIndex(tmp.0, tmp.1)] = find(calcIndex(tmp.0, tmp.1 - 1))
                    states[tmp.0][tmp.1] = .able
                }
            }
        }
        
        for i in 1...self.height {
            for j in 1...self.width {
                if states[i][j] == .able { states[i][j] = .confirm }
            }
        }
    }
}
