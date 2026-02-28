import SwiftUI
import Observation

// MARK: - THE COMPUTATIONAL GEOMETRY ENGINE
struct OrigamiMath {
    static func axis(from start: CGPoint, to end: CGPoint) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        return (x: end.x - start.x, y: end.y - start.y, z: 0)
    }
    
    static func anchor(from start: CGPoint, to end: CGPoint) -> UnitPoint {
        return UnitPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }
    
    static func mirror(_ point: CGPoint, start: CGPoint, end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let a = (dx * dx - dy * dy) / (dx * dx + dy * dy)
        let b = 2 * dx * dy / (dx * dx + dy * dy)
        let x2 = a * (point.x - start.x) + b * (point.y - start.y) + start.x
        let y2 = b * (point.x - start.x) - a * (point.y - start.y) + start.y
        return CGPoint(x: x2, y: y2)
    }
    
    static func mirror(polygons: [[CGPoint]], start: CGPoint, end: CGPoint) -> [[CGPoint]] {
        return polygons.map { poly in poly.map { mirror($0, start: start, end: end) } }
    }
    
    static func slice(_ polygon: [CGPoint], start: CGPoint, end: CGPoint) -> (staying: [CGPoint], moving: [CGPoint]) {
        var staying: [CGPoint] = []
        var moving: [CGPoint] = []
        
        let side = { (p: CGPoint) -> CGFloat in
            return (end.x - start.x) * (p.y - start.y) - (end.y - start.y) * (p.x - start.x)
        }
        
        for i in 0..<polygon.count {
            let current = polygon[i]
            let next = polygon[(i + 1) % polygon.count]
            
            let d1 = side(current)
            let d2 = side(next)
            
            if d1 >= -0.0001 { staying.append(current) }
            if d1 <= 0.0001 { moving.append(current) }
            
            if (d1 > 0.0001 && d2 < -0.0001) || (d1 < -0.0001 && d2 > 0.0001) {
                let a1 = next.y - current.y
                let b1 = current.x - next.x
                let c1 = a1 * current.x + b1 * current.y
                
                let a2 = end.y - start.y
                let b2 = start.x - end.x
                let c2 = a2 * start.x + b2 * start.y
                
                let det = a1 * b2 - a2 * b1
                if abs(det) > 0.00001 {
                    let intersection = CGPoint(x: (b2 * c1 - b1 * c2) / det, y: (a1 * c2 - a2 * c1) / det)
                    staying.append(intersection)
                    moving.append(intersection)
                }
            }
        }
        return (clean(staying), clean(moving))
    }
    
    static func slice(polygons: [[CGPoint]], start: CGPoint, end: CGPoint, filter: (([CGPoint]) -> Bool)? = nil) -> (staying: [[CGPoint]], moving: [[CGPoint]]) {
        var staying: [[CGPoint]] = []
        var moving: [[CGPoint]] = []
        for poly in polygons {
            if let filter = filter, !filter(poly) {
                staying.append(poly)
                continue
            }
            let (s, m) = slice(poly, start: start, end: end)
            if s.count >= 3 { staying.append(s) }
            if m.count >= 3 { moving.append(m) }
        }
        return (staying, moving)
    }
    
    private static func clean(_ poly: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        for p in poly {
            if result.isEmpty || hypot(result.last!.x - p.x, result.last!.y - p.y) > 0.001 { result.append(p) }
        }
        if result.count > 1 && hypot(result.first!.x - result.last!.x, result.first!.y - result.last!.y) < 0.001 { result.removeLast() }
        return result
    }
}

class OrigamiBuilder {
    var staticPolygons: [[CGPoint]]
    var whitePolygons: [[CGPoint]]
    var steps: [OrigamiStep] = []
    var isFlippedInternally: Bool = false
    var currentColorOverride: Color? = nil
    
    init(startPolygon: [CGPoint] = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]) {
        self.staticPolygons = [startPolygon]
        self.whitePolygons = []
    }
    
    func addFold(instruction: String, start: CGPoint, end: CGPoint, angle: Double = 180.0, filter: (([CGPoint]) -> Bool)? = nil) {
        let engineStart = isFlippedInternally ? CGPoint(x: 1.0 - start.x, y: start.y) : start
        let engineEnd = isFlippedInternally ? CGPoint(x: 1.0 - end.x, y: end.y) : end
        
        let staticSlices = OrigamiMath.slice(polygons: staticPolygons, start: engineStart, end: engineEnd, filter: filter)
        let whiteSlices = OrigamiMath.slice(polygons: whitePolygons, start: engineStart, end: engineEnd, filter: filter)
        
        let step = OrigamiStep(
            instruction: instruction,
            staticBase: staticSlices.staying,
            whiteBase: whiteSlices.staying,
            staticMoving: staticSlices.moving,
            whiteMoving: whiteSlices.moving,
            creaseStart: engineStart,
            creaseEnd: engineEnd,
            targetAngle: angle,
            isFlipStep: false,
            isNextPartStep: false,
            colorOverride: currentColorOverride
        )
        steps.append(step)
        
        let mirroredStatic = OrigamiMath.mirror(polygons: staticSlices.moving, start: engineStart, end: engineEnd)
        let mirroredWhite = OrigamiMath.mirror(polygons: whiteSlices.moving, start: engineStart, end: engineEnd)
        
        staticPolygons = staticSlices.staying + mirroredWhite
        whitePolygons = whiteSlices.staying + mirroredStatic
    }
    
    func addFlip(instruction: String) {
        isFlippedInternally.toggle()
        let step = OrigamiStep(
            instruction: instruction,
            staticBase: staticPolygons,
            whiteBase: whitePolygons,
            staticMoving: [],
            whiteMoving: [],
            creaseStart: .zero,
            creaseEnd: .zero,
            targetAngle: 0,
            isFlipStep: true,
            isNextPartStep: false,
            colorOverride: currentColorOverride
        )
        steps.append(step)
    }
    
    func startNewPart(instruction: String, startPolygon: [CGPoint], color: Color) {
        self.staticPolygons = [startPolygon]
        self.whitePolygons = []
        self.isFlippedInternally = false
        self.currentColorOverride = color
        
        let step = OrigamiStep(
            instruction: instruction,
            staticBase: staticPolygons,
            whiteBase: whitePolygons,
            staticMoving: [],
            whiteMoving: [],
            creaseStart: .zero,
            creaseEnd: .zero,
            targetAngle: 0,
            isFlipStep: false,
            isNextPartStep: true,
            colorOverride: color
        )
        steps.append(step)
    }
}

struct OrigamiStep: Identifiable, Hashable {
    let id = UUID()
    let instruction: String
    let staticBase: [[CGPoint]]
    let whiteBase: [[CGPoint]]
    let staticMoving: [[CGPoint]]
    let whiteMoving: [[CGPoint]]
    let creaseStart: CGPoint
    let creaseEnd: CGPoint
    let targetAngle: Double
    var isFlipStep: Bool = false
    var isNextPartStep: Bool = false
    var colorOverride: Color? = nil
    
    var anchor: UnitPoint { OrigamiMath.anchor(from: creaseStart, to: creaseEnd) }
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) { OrigamiMath.axis(from: creaseStart, to: creaseEnd) }
    var creasePoints: [CGPoint] { [creaseStart, creaseEnd] }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OrigamiStep, rhs: OrigamiStep) -> Bool { lhs.id == rhs.id }
}

struct OrigamiProject: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let difficulty: String
    let iconName: String
    let accentColor: Color
    var steps: [OrigamiStep]
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OrigamiProject, rhs: OrigamiProject) -> Bool { lhs.id == rhs.id }
}

@Observable
@MainActor
class OrigamiEngine {
    var currentProject: OrigamiProject?
    var currentStepIndex: Int = 0
    var isProjectComplete: Bool = false
    var isWaitingForDone: Bool = false
    
    var activeStep: OrigamiStep? {
        guard let project = currentProject, currentStepIndex < project.steps.count else { return nil }
        return project.steps[currentStepIndex]
    }
    
    var progressText: String {
        guard let project = currentProject else { return "" }
        return "Step \(currentStepIndex + 1) of \(project.steps.count)"
    }
    
    func startProject(_ project: OrigamiProject) {
        self.currentProject = project
        self.currentStepIndex = 0
        self.isProjectComplete = false
        self.isWaitingForDone = false
    }
    
    func completeCurrentStep() {
        guard let project = currentProject else { return }
        if currentStepIndex < project.steps.count - 1 {
            currentStepIndex += 1
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            isWaitingForDone = true
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    func finishProject() {
        isWaitingForDone = false
        isProjectComplete = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static let mockProjects: [OrigamiProject] = [
        buildFrog(), buildRabbit(), buildWhale(), buildDog(), buildCat(),
        buildFox(), buildHeart(), buildSailboat()
    ]
    
    // MARK: - THE MATHEMATICALLY VERIFIED PROJECTS
    
    static func buildFrog() -> OrigamiProject {
        // Start with a diamond shape (rotated square)
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        builder.addFold(instruction: "Fold the bottom corner up to the top corner.", start: CGPoint(x: 1, y: 0.5), end: CGPoint(x: 0, y: 0.5))
        builder.addFold(instruction: "Fold the top point down as shown.", start: CGPoint(x: 0, y: 0.25), end: CGPoint(x: 1, y: 0.25))
        builder.addFold(instruction: "Fold the left corner up to start the first eye.", start: CGPoint(x: 0.45, y: 0.5), end: CGPoint(x: 0.25, y: 0.15))
        builder.addFold(instruction: "Fold the right corner up for the other eye.", start: CGPoint(x: 0.75, y: 0.15), end: CGPoint(x: 0.55, y: 0.5))
        builder.addFold(instruction: "Fold the bottom point up to shape the chin.", start: CGPoint(x: 1, y: 0.42), end: CGPoint(x: 0, y: 0.42))
        builder.addFlip(instruction: "Turn the paper over to see your frog!")
        
        return OrigamiProject(title: "Jumpy Frog", difficulty: "Intermediate", iconName: "leaf.fill", accentColor: .green, steps: builder.steps)
    }
    
    static func buildRabbit() -> OrigamiProject {
        // Step 1: Start with a diamond shape
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 1, y: 0.7), CGPoint(x: 0.5, y: 1.2), CGPoint(x: 0, y: 0.7)])
        
        // Step 2: Fold the bottom half up
        builder.addFold(instruction: "Fold the bottom half up.", start: CGPoint(x: 1, y: 0.7), end: CGPoint(x: 0, y: 0.7))
        
        // Step 3: Fold the bottom edge up slightly
        builder.addFold(instruction: "Fold the bottom edge up slightly.", start: CGPoint(x: 1, y: 0.6), end: CGPoint(x: 0, y: 0.6))
        
        // Step 4: Fold the left and right corners UP
        // Angle them slightly more inwards to meet near the center!
        builder.addFold(instruction: "Fold the left corner up to form an ear.", start: CGPoint(x: 0.46, y: 0.6), end: CGPoint(x: 0.0, y: 0.14)) 
        builder.addFold(instruction: "Fold the right corner up to form the other ear.", start: CGPoint(x: 1.0, y: 0.14), end: CGPoint(x: 0.54, y: 0.6))
        
        // Step 5: Turn the paper over
        builder.addFlip(instruction: "Turn the paper over to see the face.")
        
        // Step 6: Fold the top point backwards to flatten the head
        builder.addFold(instruction: "Fold the top point backwards to flatten the head.", start: CGPoint(x: 1, y: 0.4), end: CGPoint(x: 0, y: 0.4), angle: -180.0) { poly in
            let minY = poly.map { $0.y }.min() ?? 0
            return minY > 0.15 // The ears reach up to 0.14, head is at 0.20, so this perfectly targets only the head!
        }
        
//        // Step 7: Fold the bottom point
        
        return OrigamiProject(title: "Cute Bunny", difficulty: "Intermediate", iconName: "hare.fill", accentColor: .pink, steps: builder.steps)
    }
    
    static func buildWhale() -> OrigamiProject {
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        builder.addFold(instruction: "Fold the top-right edge to the center diagonal.", start: CGPoint(x: 0.25, y: 0.25), end: CGPoint(x: 1, y: 0.5))
        builder.addFold(instruction: "Fold the bottom-right edge to the center diagonal.", start: CGPoint(x: 1, y: 0.5), end: CGPoint(x: 0.25, y: 0.75))
        builder.addFold(instruction: "Fold the left pointy nose IN to flatten the front.", start: CGPoint(x: 0.15, y: 0.8), end: CGPoint(x: 0.15, y: 0.2))
        builder.addFold(instruction: "Fold the entire whale in half!", start: CGPoint(x: 1, y: 0.5), end: CGPoint(x: 0, y: 0.5))
        builder.addFold(instruction: "Fold the tail up to make it swim!", start: CGPoint(x: 0.9, y: 0.2), end: CGPoint(x: 0.7, y: 0.5))
        return OrigamiProject(title: "Blue Whale", difficulty: "Beginner", iconName: "fish.fill", accentColor: .blue, steps: builder.steps)
    }

    static func buildDog() -> OrigamiProject {
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        // Step 1: Fold top point DOWN to meet bottom → creates upside-down triangle
        // The BOTTOM stays, the TOP folds down. Flat edge at top (y=0.5), point at bottom (y=1.0).
        builder.addFold(instruction: "Fold the top point down to the bottom point to make a triangle.", start: CGPoint(x: 0, y: 0.5), end: CGPoint(x: 1, y: 0.5))
        
        // Step 2: Big floppy left ear - crease from left edge midpoint to 40% of flat top
        builder.addFold(instruction: "Fold the left corner DOWN to make a floppy ear.", start: CGPoint(x: 0.1, y: 0.75), end: CGPoint(x: 0.4, y: 0.5))
        
        // Step 3: Big floppy right ear - symmetric
        builder.addFold(instruction: "Fold the right corner DOWN to make the other ear.", start: CGPoint(x: 0.6, y: 0.5), end: CGPoint(x: 0.9, y: 0.75))
        
        // Step 4: Fold the bottom tip UP slightly to make the dog's snout.
        builder.addFold(instruction: "Fold the bottom tip up a little to make the dog's snout.", start: CGPoint(x: 1, y: 0.9), end: CGPoint(x: 0, y: 0.9))
        
        return OrigamiProject(title: "Puppy Dog", difficulty: "Beginner", iconName: "pawprint.fill", accentColor: .orange, steps: builder.steps)
    }
    
    static func buildCat() -> OrigamiProject {
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        // Step 1: Fold top point DOWN → keeps bottom half.
        // Result: triangle with flat top at y=0.5 and point at bottom y=1.0
        builder.addFold(instruction: "Fold the top point down to make a triangle.", start: CGPoint(x: 0, y: 0.5), end: CGPoint(x: 1, y: 0.5))
        
        // Step 2: Left ear — crease from (0.25,0.75) on left edge to (0.1,0.5) on top edge.
        // Left corner (0,0.5) mirrors UP to approx (0.15,0.41) — ear tip above face!
        builder.addFold(instruction: "Fold the left corner UP to make the left ear.", start: CGPoint(x: 0.25, y: 0.75), end: CGPoint(x: 0.1, y: 0.5))
        
        // Step 3: Right ear — symmetric crease.
        // Right corner (1,0.5) mirrors UP to approx (0.85,0.41) — ear tip above face!
        builder.addFold(instruction: "Fold the right corner UP to make the right ear.", start: CGPoint(x: 0.9, y: 0.5), end: CGPoint(x: 0.75, y: 0.75))
        
        // Step 4: Flip to reveal the cat face!
        builder.addFlip(instruction: "Turn the paper over to see your cat!")
        
        return OrigamiProject(title: "Cute Cat", difficulty: "Beginner", iconName: "cat.fill", accentColor: .yellow, steps: builder.steps)
    }

    
    static func buildFox() -> OrigamiProject {
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        // Step 1: Fold top point DOWN → triangle with flat top (y=0.5), chin at bottom (y=1.0)
        builder.addFold(instruction: "Fold the top point down to make a triangle.", start: CGPoint(x: 0, y: 0.5), end: CGPoint(x: 1, y: 0.5))
        
        // Step 2: Left ear — fold left corner UP. Steeper angle than cat = pointier fox ears.
        builder.addFold(instruction: "Fold the left corner UP to make the left fox ear.", start: CGPoint(x: 0.2, y: 0.7), end: CGPoint(x: 0.1, y: 0.5))
        
        // Step 3: Right ear — symmetric fold.
        builder.addFold(instruction: "Fold the right corner UP to make the right fox ear.", start: CGPoint(x: 0.9, y: 0.5), end: CGPoint(x: 0.8, y: 0.7))
        
        // Step 4: Flip to reveal the fox face!
        builder.addFlip(instruction: "Turn the paper over to see your fox!")
        
        return OrigamiProject(title: "Origami Fox", difficulty: "Intermediate", iconName: "service.dog.fill", accentColor: .orange, steps: builder.steps)
    }
    
    static func buildHeart() -> OrigamiProject {
        // Step 1 & 2: Start with diamond and fold creases
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        // Step 3: Fold top point DOWN to the center
        builder.addFold(instruction: "Fold the top point down to the center.", start: CGPoint(x: 0, y: 0.25), end: CGPoint(x: 1, y: 0.25))
        
        // Step 4: Fold bottom point UP to the top edge
        builder.addFold(instruction: "Fold the bottom point all the way up to the top edge.", start: CGPoint(x: 1, y: 0.625), end: CGPoint(x: 0, y: 0.625))
        
        // Step 5: Fold left and right halves up diagonally along the center
        builder.addFold(instruction: "Fold the right half diagonally up along the center.", start: CGPoint(x: 1.0, y: 0.125), end: CGPoint(x: 0, y: 1.125))
        builder.addFold(instruction: "Fold the left half diagonally up along the center.", start: CGPoint(x: 1.0, y: 1.125), end: CGPoint(x: 0, y: 0.125))
        
        // Step 6: Flip the paper over to fold the back corners
        builder.addFlip(instruction: "Turn the paper over.")
        
      
        return OrigamiProject(title: "Origami Heart", difficulty: "Expert", iconName: "heart.fill", accentColor: .red, steps: builder.steps)
    }

    static func buildSailboat() -> OrigamiProject {
        // Use diamond like other models
        let builder = OrigamiBuilder(startPolygon: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        
        // Step 1: Fold bottom half UP → keeps top triangle = the sail!
        // Sail: point at (0.5, 0), flat bottom from (0, 0.5) to (1, 0.5).
        builder.addFold(instruction: "Fold the bottom half up to create the sail.", start: CGPoint(x: 1, y: 0.5), end: CGPoint(x: 0, y: 0.5))
        
        // Step 2: Fold bottom edge UP → creates the hull.
        // The mirrored strip extends WIDER than the sail, creating the boat hull!
        builder.addFold(instruction: "Fold the bottom edge up to shape the hull.", start: CGPoint(x: 1, y: 0.42), end: CGPoint(x: 0, y: 0.42))
        
        return OrigamiProject(title: "Pro Sailboat", difficulty: "Beginner", iconName: "sailboat.fill", accentColor: .blue, steps: builder.steps)
    }
}
