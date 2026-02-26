//
//  OrigamiStep.swift
//  Origame
//
//  Created by Mithil on 26/02/26.
//


import SwiftUI
import Observation

// MARK: - Data Models

/// Represents a single folding action the user must perform
struct OrigamiStep: Identifiable {
    let id = UUID()
    let instruction: String
    let targetAngle: Double // e.g., -180 for a full flat fold, -90 for a right-angle crease
    var isCompleted: Bool = false
}

/// Represents an entire origami model (like a Boat or a Crane)
struct OrigamiProject: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let iconName: String // We will use SF Symbols for the Gallery UI
    var steps: [OrigamiStep]
    
    // Conforming to Hashable makes it easy to use in SwiftUI Navigation
    static func == (lhs: OrigamiProject, rhs: OrigamiProject) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - The State Engine

/// The central "Brain" of our app. 
/// Using @Observable means SwiftUI will automatically redraw ONLY when these properties change.
@Observable
class OrigamiEngine {
    // The model the user is currently building
    var currentProject: OrigamiProject?
    
    // Which step they are on (starts at 0)
    var currentStepIndex: Int = 0
    
    // MARK: Computed Properties for the UI
    
    /// Returns the exact step the user needs to perform right now
    var activeStep: OrigamiStep? {
        guard let project = currentProject, currentStepIndex < project.steps.count else { return nil }
        return project.steps[currentStepIndex]
    }
    
    /// A cleanly formatted string for our Top UI Bar (e.g., "Step 1 of 5")
    var progressText: String {
        guard let project = currentProject else { return "" }
        return "Step \(currentStepIndex + 1) of \(project.steps.count)"
    }
    
    // MARK: - Intentions (Actions)
    
    /// Call this when the user taps a model in the Home Gallery
    func startProject(_ project: OrigamiProject) {
        self.currentProject = project
        self.currentStepIndex = 0
    }
    
    /// Call this when the user successfully completes a DragGesture
    func completeCurrentStep() {
        guard let project = currentProject else { return }
        
        if currentStepIndex < project.steps.count - 1 {
            // Move to the next step!
            currentStepIndex += 1
            
            // HIG Highlight: Fire a haptic to celebrate progress
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // THE PROJECT IS FINISHED!
            // (Later, this is where we will trigger SwiftData to unlock the next level)
            print("Project Complete! Cue the confetti!")
        }
    }
    
    // MARK: - Mock Data for the Prototype
    static let mockProjects: [OrigamiProject] = [
        OrigamiProject(
            title: "The Apprentice Boat",
            iconName: "sailboat.fill",
            steps: [
                OrigamiStep(instruction: "Drag the bottom edge up to perfectly meet the top edge.", targetAngle: -180.0),
                OrigamiStep(instruction: "Excellent. Now fold the right corner down.", targetAngle: -90.0),
                OrigamiStep(instruction: "Mirror that fold on the left side.", targetAngle: -90.0)
            ]
        )
    ]
}