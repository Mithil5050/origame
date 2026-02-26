import SwiftUI
import Observation

// MARK: - Helper Types

/// Defines the anchor point for the 3D rotation hinge
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

// MARK: - Data Models

/// Represents a precise vector-based folding action with diagrammatic guides
struct OrigamiStep: Identifiable {
    let id = UUID()
    let instruction: String
    
    /// The shape of the paper during this step (Normalized coordinates 0.0 to 1.0)
    let paperPoints: [CGPoint]
    
    /// The specific points forming the "flap" that the user actually moves
    let flapPoints: [CGPoint]
    
    /// The exact vector path where the dotted guide line should appear
    let creasePoints: [CGPoint]
    
    /// The hinge of the fold
    let anchor: FoldAnchor
    
    /// The 3D axis of rotation
    let rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat)
    
    /// The final resting angle (usually -180 or 180)
    let targetAngle: Double
    
    var isCompleted: Bool = false
}

struct OrigamiProject: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let iconName: String
    var steps: [OrigamiStep]
    
    static func == (lhs: OrigamiProject, rhs: OrigamiProject) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - The State Engine

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
        guard let project = currentProject else { return "Select a Project" }
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
    
    // MARK: - The High-Accuracy Sailboat Tutorial
    
    static let mockProjects: [OrigamiProject] = [
        OrigamiProject(
            title: "The Classic Sailboat",
            iconName: "sailboat.fill",
            steps: [
                // STEP 1: Diamond Fold (Triangle)
                // Starts as a diamond, folds bottom half up to create a triangle
                OrigamiStep(
                    instruction: "Fold the bottom half of the diamond up to meet the top point.",
                    paperPoints: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 0.5)],
                    creasePoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5)],
                    anchor: .center,
                    rotationAxis: (x: 1, y: 0, z: 0),
                    targetAngle: 180.0
                ),
                
                // STEP 2: The Vertical Sail Fold
                // Creates the sharp white sail by folding the left corner toward the center
                OrigamiStep(
                    instruction: "Fold the left corner inward to reveal the white sail.",
                    paperPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 0)],
                    flapPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5)],
                    creasePoints: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5)],
                    anchor: .custom(UnitPoint(x: 0.5, y: 0.5)),
                    rotationAxis: (x: 1, y: 1, z: 0),
                    targetAngle: -180.0
                ),
                
                // STEP 3: The Hull Fold
                // Folds the bottom edge up horizontally to create the blue boat base
                OrigamiStep(
                    instruction: "Fold the bottom corner up to finish the hull.",
                    paperPoints: [CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.25, y: 0.25)],
                    flapPoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.75, y: 0.25)],
                    creasePoints: [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.25)],
                    anchor: .custom(UnitPoint(x: 0.75, y: 0.25)),
                    rotationAxis: (x: -1, y: 1, z: 0),
                    targetAngle: 180.0
                )
            ]
        )
    ]
}
