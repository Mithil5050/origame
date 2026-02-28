//
//  DeviceTiltManager.swift
//  Origame
//
//  Created by Mithil on 27/02/26.
//


import Foundation
import CoreMotion
import Observation

@Observable
class DeviceTiltManager {
    private let motionManager = CMMotionManager()
    var tiltProgress: Double = 0.0 
    
    // Captures the resting angle of the iPad when the step begins
    private var initialPitch: Double?
    
    func startTracking() {
        initialPitch = nil // Reset memory for the new step
        tiltProgress = 0.0
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 FPS for buttery smooth folding
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                
                // 1. Auto-Calibrate: Lock in the angle the child is currently holding the iPad
                if self.initialPitch == nil {
                    self.initialPitch = motion.attitude.pitch
                }
                
                guard let startPitch = self.initialPitch else { return }
                
                // 2. Calculate the difference. (Tilting the iPad forward reduces the pitch)
                let pitchDelta = startPitch - motion.attitude.pitch 
                
                // 3. Map a ~40 degree tilt (0.7 radians) to 100% fold completion
                let progress = max(0, min(1.0, pitchDelta / 0.7))
                
                // Update the UI smoothly
                self.tiltProgress = progress
            }
        } else {
            print("⚠️ CoreMotion is not available on this device/simulator.")
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
    }
}