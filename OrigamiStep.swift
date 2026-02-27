import SwiftUI
import Observation

enum FoldAnchor {
    case top, bottom, leading, trailing, center
    case custom(UnitPoint)
    
    var unitPoint: UnitPoint {
        switch self {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case .center: return .center
        case .custom(let point): return point
        }
    }
}

struct OrigamiStep: Identifiable, Hashable {
    let id = UUID()
    let instruction: String
    let paperPoints: [CGPoint]
    let completedFlaps: [[CGPoint]]
    let flapPoints: [CGPoint]
    let creasePoints: [CGPoint]
    let anchor: FoldAnchor
    let rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let targetAngle: Double
    
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
class OrigamiEngine {
    var currentProject: OrigamiProject?
    var currentStepIndex: Int = 0
    var isProjectComplete: Bool = false
    
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
    }
    
    func completeCurrentStep() {
        guard let project = currentProject else { return }
        if currentStepIndex < project.steps.count - 1 {
            currentStepIndex += 1
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            isProjectComplete = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    static let mockProjects: [OrigamiProject] = [
        // 1. THE PRO SAILBOAT
        OrigamiProject(
            title: "Pro Sailboat",
            difficulty: "Beginner",
            iconName: "sailboat.fill",
            accentColor: .blue,
            steps: [
                OrigamiStep(
                    instruction: "Fold the bottom half of the diamond up to the top point.",
                    paperPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 0.5)],
                    creasePoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)],
                    anchor: .center, rotationAxis: (1, 0, 0), targetAngle: 180.0
                ),
                OrigamiStep(
                    instruction: "Fold the left corner inward to reveal the white sail side.",
                    paperPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 0)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5)],
                    creasePoints: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.5, y: 0.5)), rotationAxis: (1, 1, 0), targetAngle: -180.0
                ),
                OrigamiStep(
                    instruction: "Fold the bottom corner up to finish the blue hull.",
                    paperPoints: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 0.5)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.75, y: 0.25)],
                    creasePoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.25)],
                    anchor: .custom(UnitPoint(x: 0.75, y: 0.25)), rotationAxis: (-1, 1, 0), targetAngle: 180.0
                )
            ]
        ),
        
        // 2. THE ELITE PRO AIRPLANE (FLAWLESS 4-STEP)
        OrigamiProject(
            title: "Elite Pro Airplane",
            difficulty: "Intermediate",
            iconName: "paperplane.fill",
            accentColor: .orange,
            steps: [
                // STEP 1: Left Corner
                OrigamiStep(
                    instruction: "Fold the top-left corner into the center.",
                    paperPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.5)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: 0.5)],
                    creasePoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.25, y: 0.25)), rotationAxis: (1, -1, 0), targetAngle: 180.0
                ),
                // STEP 2: Right Corner
                OrigamiStep(
                    instruction: "Fold the top-right corner into the center.",
                    paperPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.5)],
                    completedFlaps: [[CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0, y: 0.5)]],
                    flapPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 0.5)],
                    creasePoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.75, y: 0.25)), rotationAxis: (1, 1, 0), targetAngle: 180.0
                ),
                // STEP 3: Nose Down
                OrigamiStep(
                    instruction: "Fold the entire top triangle straight down.",
                    paperPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5)],
                    creasePoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.5, y: 0.5)), rotationAxis: (1, 0, 0), targetAngle: 180.0
                ),
                // STEP 4: Fold in Half
                OrigamiStep(
                    instruction: "Fold the left half over the right half to finish!",
                    paperPoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 1)],
                    completedFlaps: [[CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1)]],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 1)],
                    creasePoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 1)],
                    anchor: .custom(UnitPoint(x: 0.5, y: 0.75)), rotationAxis: (0, 1, 0), targetAngle: 180.0
                )
            ]
        ),
        
        // 3. THE EXPERT BUTTERFLY
        OrigamiProject(
            title: "Expert Butterfly",
            difficulty: "Expert",
            iconName: "viewfinder.circle.fill",
            accentColor: .purple,
            steps: [
                OrigamiStep(
                    instruction: "Fold the top half down to the bottom edge.",
                    paperPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5)],
                    creasePoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)],
                    anchor: .center, rotationAxis: (1, 0, 0), targetAngle: 180.0
                ),
                OrigamiStep(
                    instruction: "Fold the left side over to meet the right edge.",
                    paperPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 1)],
                    creasePoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 1)],
                    anchor: .trailing, rotationAxis: (0, 1, 0), targetAngle: 180.0
                ),
                OrigamiStep(
                    instruction: "Fold the top layer corner diagonally to form the first wing.",
                    paperPoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 1)],
                    completedFlaps: [],
                    flapPoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1)],
                    creasePoints: [CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.75, y: 0.75)), rotationAxis: (1, 1, 0), targetAngle: 180.0
                )
            ]
        )
    ]
}
