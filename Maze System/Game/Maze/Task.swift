//
//  Task.swift
//  Maze System
//
//  Created by Reyes on 10/26/24.
//

import Foundation
import SwiftData

@Model
class Task {
    // MARK: - Properties

    var id: UUID
    var position: Position
    var score: Int

    // 任务的题目和答案，使用 @Transient 标记为非持久化属性
    @Transient var question: String = ""
    @Transient var answer: String = ""
    @Transient var taskType: TaskType = .calculation
    @Transient var difficulty: DifficultyLevel = .easy

    // MARK: - Initialization

    init(position: Position, score: Int) {
        self.id = UUID()
        self.position = position
        self.score = score
    }

    // MARK: - Enumerations

    /// 任务类型枚举，包含不同的数学领域
    enum TaskType {
        case calculation
        case discreteMath(DiscreteMathType)
        case advancedMath
        case probability
        case linearAlgebra
        case geometry
    }

    /// 离散数学子类型枚举
    enum DiscreteMathType {
        case permutationCombination
        case setTheory
        case groupTheory
        case graphTheory
    }

    /// 难度级别枚举
    enum DifficultyLevel {
        case easy
        case medium
        case hard
        case expert
    }

    // MARK: - Public Methods

    /// 生成任务问题，根据难度和类型
    func generateQuestion() {
        // 根据分数确定难度级别
        determineDifficulty()

        // 随机选择任务类型
        selectTaskType()

        // 根据任务类型生成问题
        switch taskType {
        case .calculation:
            generateCalculationQuestion()
        case .discreteMath(let type):
            generateDiscreteMathQuestion(type: type)
        case .advancedMath:
            generateAdvancedMathQuestion()
        case .probability:
            generateProbabilityQuestion()
        case .linearAlgebra:
            generateLinearAlgebraQuestion()
        case .geometry:
            generateGeometryQuestion()
        }
    }

    // MARK: - Private Methods

    /// 确定任务的难度级别
    private func determineDifficulty() {
        if self.score >= 50 {
            difficulty = .expert
        } else if self.score >= 30 {
            difficulty = .hard
        } else if self.score >= 20 {
            difficulty = .medium
        } else {
            difficulty = .easy
        }
    }

    /// 随机选择任务类型
    private func selectTaskType() {
        switch difficulty {
        case .easy:
            taskType = .calculation
        case .medium:
            let types: [TaskType] = [
                .calculation,
                .discreteMath(.permutationCombination),
                .probability
            ]
            taskType = types.randomElement()!
        case .hard:
            let types: [TaskType] = [
                .advancedMath,
                .linearAlgebra,
                .geometry,
                .discreteMath(.setTheory),
                .discreteMath(.groupTheory),
                .discreteMath(.graphTheory)
            ]
            taskType = types.randomElement()!
        case .expert:
            let types: [TaskType] = [
                .advancedMath,
                .linearAlgebra,
                .geometry,
                .probability,
                .discreteMath(.setTheory),
                .discreteMath(.groupTheory),
                .discreteMath(.graphTheory)
            ]
            taskType = types.randomElement()!
        }
    }

    // MARK: - Question Generators

    /// 生成计算类问题
    private func generateCalculationQuestion() {
        let a = Int.random(in: 1...50)
        let b = Int.random(in: 1...50)
        let operations = ["+", "-", "*", "/"]
        let operation = operations.randomElement()!

        switch operation {
        case "+":
            question = "Calculate: \(a) + \(b) = ?"
            answer = "\(a + b)"
        case "-":
            question = "Calculate: \(a) - \(b) = ?"
            answer = "\(a - b)"
        case "*":
            question = "Calculate: \(a) * \(b) = ?"
            answer = "\(a * b)"
        case "/":
            let dividend = a * b
            question = "Calculate: \(dividend) ÷ \(a) = ?"
            answer = "\(b)"
        default:
            break
        }
    }

    /// 生成离散数学问题
    private func generateDiscreteMathQuestion(type: DiscreteMathType) {
        switch type {
        case .permutationCombination:
            generatePermutationCombinationQuestion()
        case .setTheory:
            generateSetTheoryQuestion()
        case .groupTheory:
            generateGroupTheoryQuestion()
        case .graphTheory:
            generateGraphTheoryQuestion()
        }
    }

    /// 生成排列组合问题
    private func generatePermutationCombinationQuestion() {
        let n = Int.random(in: 5...10)
        let r = Int.random(in: 2...n)
        let isPermutation = Bool.random()

        if isPermutation {
            question = "Calculate the number of permutations when selecting \(r) items from \(n) items."
            let result = permutation(n: n, r: r)
            answer = "\(result)"
        } else {
            question = "Calculate the number of combinations when selecting \(r) items from \(n) items."
            let result = combination(n: n, r: r)
            answer = "\(result)"
        }
    }

    /// 生成集合论问题
    private func generateSetTheoryQuestion() {
        let setA = Set((1...20).shuffled().prefix(Int.random(in: 5...10)))
        let setB = Set((1...20).shuffled().prefix(Int.random(in: 5...10)))
        let operations = ["∪", "∩", "-", "Δ"]
        let operation = operations.randomElement()!

        switch operation {
        case "∪":
            question = "Given sets A = \(formatSet(setA)) and B = \(formatSet(setB)), find A ∪ B."
            let resultSet = setA.union(setB)
            answer = formatSet(resultSet)
        case "∩":
            question = "Given sets A = \(formatSet(setA)) and B = \(formatSet(setB)), find A ∩ B."
            let resultSet = setA.intersection(setB)
            answer = formatSet(resultSet)
        case "-":
            question = "Given sets A = \(formatSet(setA)) and B = \(formatSet(setB)), find A - B."
            let resultSet = setA.subtracting(setB)
            answer = formatSet(resultSet)
        case "Δ":
            question = "Given sets A = \(formatSet(setA)) and B = \(formatSet(setB)), find the symmetric difference A Δ B."
            let resultSet = setA.symmetricDifference(setB)
            answer = formatSet(resultSet)
        default:
            break
        }
    }

    /// 生成群论问题
    private func generateGroupTheoryQuestion() {
        let modulo = [5, 7, 9, 11].randomElement()!
        let generator = Int.random(in: 1...(modulo - 1))
        question = "In the additive group of integers modulo \(modulo), find the order of the element [\(generator)]."
        let elementOrder = modulo / gcd(generator, modulo)
        answer = "\(elementOrder)"
    }

    /// 生成图论问题
    private func generateGraphTheoryQuestion() {
        let nodeCount = Int.random(in: 5...7)
        let edgeProbability = Double.random(in: 0.3...0.7)
        var adjacencyMatrix = [[Int]](repeating: [Int](repeating: 0, count: nodeCount), count: nodeCount)

        // 生成对称的邻接矩阵
        for i in 0..<nodeCount {
            for j in i+1..<nodeCount {
                if Double.random(in: 0...1) < edgeProbability {
                    adjacencyMatrix[i][j] = 1
                    adjacencyMatrix[j][i] = 1
                }
            }
        }

        // 构建问题描述
        question = "Given the adjacency matrix of an undirected graph:\n"
        for row in adjacencyMatrix {
            question += row.map { "\($0)" }.joined(separator: " ") + "\n"
        }
        question += "Calculate the degree sequence of the graph."

        // 计算度数序列
        let degreeSequence = adjacencyMatrix.map { row in
            row.reduce(0, +)
        }.sorted(by: >)

        answer = degreeSequence.map { "\($0)" }.joined(separator: ", ")
    }

    /// 生成高等数学问题
    private func generateAdvancedMathQuestion() {
        switch difficulty {
        case .medium:
            generateExponentialQuestion()
        case .hard, .expert:
            generateIntegralQuestion()
        default:
            generateExponentialQuestion()
        }
    }

    /// 生成指数运算问题
    private func generateExponentialQuestion() {
        let base = Int.random(in: 2...5)
        let exponent = Int.random(in: 2...3)
        question = "Calculate: \(base)^\(exponent) = ?"
        let result = pow(Double(base), Double(exponent))
        answer = String(format: "%.0f", result)
    }

    /// 生成定积分计算问题
    private func generateIntegralQuestion() {
        let a = Double(Int.random(in: 1...5))
        let b = Double(Int.random(in: 6...10))
        let coefficient = Double(Int.random(in: 1...5))
        question = "Calculate the definite integral: ∫ from \(a) to \(b) of \(coefficient)x dx = ?"
        let result = 0.5 * coefficient * (b * b - a * a)
        answer = String(format: "%.2f", result)
    }

    /// 生成概率问题
    private func generateProbabilityQuestion() {
        switch difficulty {
        case .easy, .medium:
            generateBasicProbabilityQuestion()
        case .hard, .expert:
            generateAdvancedProbabilityQuestion()
        }
    }

    /// 生成基础概率问题
    private func generateBasicProbabilityQuestion() {
        let totalOutcomes = Int.random(in: 6...10)
        let favorableOutcomes = Int.random(in: 1...(totalOutcomes - 1))
        question = "An event has \(favorableOutcomes) favorable outcomes out of \(totalOutcomes) possible outcomes. What is the probability of the event occurring? (Express as a simplified fraction)"
        let gcdValue = gcd(favorableOutcomes, totalOutcomes)
        let numerator = favorableOutcomes / gcdValue
        let denominator = totalOutcomes / gcdValue
        answer = "\(numerator)/\(denominator)"
    }

    /// 生成高级概率问题
    private func generateAdvancedProbabilityQuestion() {
        let totalBalls = Int.random(in: 15...30)
        let colors = ["red", "blue", "green", "yellow"]
        var colorCounts: [String: Int] = [:]
        var remainingBalls = totalBalls

        for color in colors {
            if color == colors.last {
                colorCounts[color] = remainingBalls
            } else {
                let maxCount = remainingBalls - (colors.count - colorCounts.count - 1)
                let count = Int.random(in: 1...maxCount)
                colorCounts[color] = count
                remainingBalls -= count
            }
        }

        // 确保总球数正确
        let calculatedTotalBalls = colorCounts.values.reduce(0, +)
        if calculatedTotalBalls != totalBalls {
            if let lastColor = colors.last {
                colorCounts[lastColor]! += (totalBalls - calculatedTotalBalls)
            }
        }

        let drawnBalls = Int.random(in: 2...3)
        let selectedColors = colors.shuffled().prefix(drawnBalls)
        let selectedColorsList = selectedColors.joined(separator: " and ")

        question = "A box contains the following balls: \(colorCounts.map { "\($0.value) \($0.key)" }.joined(separator: ", ")). If \(drawnBalls) balls are drawn at random without replacement, what is the probability that they are all different colors: \(selectedColorsList)? (Express as a simplified fraction)"

        // 计算概率
        var favorableOutcomes = 1
        for color in selectedColors {
            favorableOutcomes *= colorCounts[color] ?? 0
        }

        var totalOutcomes = 1
        var tempTotalBalls = totalBalls
        for _ in 0..<drawnBalls {
            totalOutcomes *= tempTotalBalls
            tempTotalBalls -= 1
        }

        // 化简分数
        let gcdValue = gcd(favorableOutcomes, totalOutcomes)
        let numerator = favorableOutcomes / gcdValue
        let denominator = totalOutcomes / gcdValue
        answer = "\(numerator)/\(denominator)"
    }

    /// 生成线性代数问题
    private func generateLinearAlgebraQuestion() {
        switch difficulty {
        case .medium:
            generateBasicLinearAlgebraQuestion()
        case .hard:
            generateDeterminantQuestion(order: 2)
        case .expert:
            generateDeterminantQuestion(order: 3)
        default:
            generateBasicLinearAlgebraQuestion()
        }
    }

    /// 生成基础线性代数问题
    private func generateBasicLinearAlgebraQuestion() {
        let a1 = Int.random(in: 1...5)
        let b1 = Int.random(in: 1...5)
        let c1 = Int.random(in: 1...20)
        let a2 = Int.random(in: 1...5)
        let b2 = Int.random(in: 1...5)
        let c2 = Int.random(in: 1...20)
        question = "Solve the system of equations:\n\(a1)x + \(b1)y = \(c1)\n\(a2)x + \(b2)y = \(c2)"
        let denominator = a1 * b2 - a2 * b1
        if denominator != 0 {
            let xNumerator = c1 * b2 - c2 * b1
            let yNumerator = a1 * c2 - a2 * c1
            let x = Double(xNumerator) / Double(denominator)
            let y = Double(yNumerator) / Double(denominator)
            answer = String(format: "x = %.2f, y = %.2f", x, y)
        } else {
            answer = "No solution or infinite solutions"
        }
    }

    /// 生成行列式计算问题
    private func generateDeterminantQuestion(order: Int) {
        if order == 2 {
            let a = Int.random(in: 1...5)
            let b = Int.random(in: 1...5)
            let c = Int.random(in: 1...5)
            let d = Int.random(in: 1...5)
            question = "Calculate the determinant of the matrix:\n| \(a) \(b) |\n| \(c) \(d) |"
            let determinant = a * d - b * c
            answer = "\(determinant)"
        } else if order == 3 {
            let a = Int.random(in: 1...5)
            let b = Int.random(in: 1...5)
            let c = Int.random(in: 1...5)
            let d = Int.random(in: 1...5)
            let e = Int.random(in: 1...5)
            let f = Int.random(in: 1...5)
            let g = Int.random(in: 1...5)
            let h = Int.random(in: 1...5)
            let i = Int.random(in: 1...5)
            question = """
            Calculate the determinant of the matrix:
            | \(a) \(b) \(c) |
            | \(d) \(e) \(f) |
            | \(g) \(h) \(i) |
            """
            let determinant = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
            answer = "\(determinant)"
        }
    }

    /// 生成几何问题
    private func generateGeometryQuestion() {
        switch difficulty {
        case .easy:
            generateBasicGeometryQuestion()
        case .medium:
            generateIntermediateGeometryQuestion()
        case .hard, .expert:
            generateAdvancedGeometryQuestion()
        }
    }

    /// 生成基础几何问题
    private func generateBasicGeometryQuestion() {
        let length = Double.random(in: 1...10)
        let width = Double.random(in: 1...10)
        let isArea = Bool.random()

        if isArea {
            question = "Calculate the area of a rectangle with length \(String(format: "%.1f", length)) units and width \(String(format: "%.1f", width)) units."
            let area = length * width
            answer = String(format: "%.2f", area)
        } else {
            question = "Calculate the perimeter of a rectangle with length \(String(format: "%.1f", length)) units and width \(String(format: "%.1f", width)) units."
            let perimeter = 2 * (length + width)
            answer = String(format: "%.2f", perimeter)
        }
    }

    /// 生成中等难度几何问题
    private func generateIntermediateGeometryQuestion() {
        let radius = Double.random(in: 1...10)
        let isArea = Bool.random()

        if isArea {
            question = "Calculate the area of a circle with radius \(String(format: "%.1f", radius)) units. (Use π ≈ 3.14)"
            let area = 3.14 * radius * radius
            answer = String(format: "%.2f", area)
        } else {
            question = "Calculate the circumference of a circle with radius \(String(format: "%.1f", radius)) units. (Use π ≈ 3.14)"
            let circumference = 2 * 3.14 * radius
            answer = String(format: "%.2f", circumference)
        }
    }

    /// 生成高级几何问题
    private func generateAdvancedGeometryQuestion() {
        let a = Double.random(in: 3...10)
        let b = Double.random(in: 4...10)
        let c = sqrt(a * a + b * b)
        let problemType = Int.random(in: 1...2)

        switch problemType {
        case 1:
            question = "Calculate the area of a right-angled triangle with legs of lengths \(String(format: "%.1f", a)) units and \(String(format: "%.1f", b)) units."
            let area = 0.5 * a * b
            answer = String(format: "%.2f", area)
        case 2:
            question = "In a right-angled triangle, one leg is \(String(format: "%.1f", a)) units and the other leg is \(String(format: "%.1f", b)) units. Calculate the length of the hypotenuse."
            answer = String(format: "%.2f", c)
        default:
            break
        }
    }

    // MARK: - Helper Functions

    /// 计算最大公约数
    private func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }

    /// 计算排列数
    private func permutation(n: Int, r: Int) -> Int {
        if r == 0 {
            return 1
        } else {
            return n * permutation(n: n - 1, r: r - 1)
        }
    }

    /// 计算组合数
    private func combination(n: Int, r: Int) -> Int {
        return permutation(n: n, r: r) / permutation(n: r, r: r)
    }

    /// 格式化集合为字符串
    private func formatSet(_ set: Set<Int>) -> String {
        let sortedElements = set.sorted()
        return "{ " + sortedElements.map { "\($0)" }.joined(separator: ", ") + " }"
    }
}
