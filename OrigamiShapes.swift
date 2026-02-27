import SwiftUI

// MARK: - VICTORY SHAPES
struct ButterflyShape: Shape {
    var pointiness: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.height))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control1: CGPoint(x: rect.maxX * pointiness, y: rect.maxY), control2: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY * 0.8), control1: CGPoint(x: rect.midX, y: rect.minY), control2: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct AirplaneVictoryShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.8))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.8))
        path.closeSubpath()
        return path
    }
}

struct BoatHullShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - CONSTANT GREEN CRAFT TABLE
struct CuttingMatBackground: View {
    var body: some View {
        ZStack {
            // Adaptive outer edge so the notch area blends nicely
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    // The classic green cutting mat!
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.35, blue: 0.22))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Canvas { context, size in
                        let spacing: CGFloat = 40
                        var path = Path()
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        // Soft white/greenish grid lines
                        context.stroke(path, with: .color(Color.white.opacity(0.15)), lineWidth: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                }
                .padding(20)
            }
        }
    }
}

// MARK: - GRID COORDINATES
struct CoordinateGridView: View {
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]
    let numbers = Array(1...12)
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(numbers, id: \.self) { num in
                    VStack {
                        Spacer()
                        Text("\(num)").font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(Color.white.opacity(0.3)) // Matches the mat
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            VStack(spacing: 0) {
                ForEach(letters, id: \.self) { letter in
                    HStack {
                        Text(letter).font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(Color.white.opacity(0.3)) // Matches the mat
                            .frame(width: 30)
                        Spacer()
                    }
                }
            }
        }
        .padding(35)
    }
}

// MARK: - PAPER SHAPES
struct PaperShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
        for i in 1..<points.count { path.addLine(to: CGPoint(x: points[i].x * rect.width, y: points[i].y * rect.height)) }
        path.closeSubpath()
        return path
    }
}

struct VectorCreaseLine: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }
        path.move(to: CGPoint(x: points[0].x * rect.width, y: points[0].y * rect.height))
        for i in 1..<points.count { path.addLine(to: CGPoint(x: points[i].x * rect.width, y: points[i].y * rect.height)) }
        return path
    }
}
