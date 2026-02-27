import SwiftUI

struct WorkspaceView: View {
    let project: OrigamiProject
    @Environment(OrigamiEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    
    @State private var foldAngle: Double = 0.0
    @State private var isFolded: Bool = false
    let paperDisplaySize: CGFloat = 340
    
    @State private var cameraTilt: Double = 35.0
    @State private var lastCameraTilt: Double = 35.0
    @State private var cameraPan: Double = -15.0
    @State private var lastCameraPan: Double = -15.0
    @State private var canvasScale: CGFloat = 1.0
    
    // Constant pure white for the underside of paper
    let paperUndersideColor = Color.white
    
    var body: some View {
        ZStack {
            CuttingMatBackground()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            cameraPan = lastCameraPan + value.translation.width * 0.3
                            cameraTilt = max(0, min(85, lastCameraTilt - value.translation.height * 0.3))
                        }
                        .onEnded { _ in
                            lastCameraPan = cameraPan; lastCameraTilt = cameraTilt
                        }
                )
            
            CoordinateGridView()
            
            ZStack {
                if engine.isProjectComplete {
                    Group {
                        if project.title == "Pro Sailboat" {
                            SailboatVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Expert Butterfly" {
                            ButterflyVictory(project: project, dismissAction: dismiss)
                        } else {
                            AirplaneVictory(project: project, dismissAction: dismiss)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                    
                } else if let step = engine.activeStep {
                    ZStack {
                        PaperShape(points: step.paperPoints)
                            .fill(Color.black.opacity(0.2)) // Slightly stronger shadow against dark green
                            .offset(y: 15).blur(radius: 10)
                        
                        PaperShape(points: step.paperPoints).fill(project.accentColor)
                        
                        ForEach(0..<step.completedFlaps.count, id: \.self) { idx in
                            PaperShape(points: step.completedFlaps[idx])
                                .fill(paperUndersideColor)
                                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        }
                        
                        ZStack {
                            ForEach(0..<engine.currentStepIndex, id: \.self) { i in
                                VectorCreaseLine(points: project.steps[i].creasePoints)
                                    .stroke(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 1.5))
                            }
                        }
                        .clipShape(PaperShape(points: step.paperPoints))
                        
                        VectorCreaseLine(points: step.creasePoints)
                            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                            .opacity(isFolded ? 0 : 1)
                        
                        PaperShape(points: step.flapPoints)
                            .fill(abs(foldAngle) > 90 ? paperUndersideColor : project.accentColor.opacity(0.95))
                            .shadow(color: .black.opacity(shadowOpacity(for: foldAngle)), radius: shadowRadius(for: foldAngle), y: shadowRadius(for: foldAngle) / 2)
                            .rotation3DEffect(.degrees(foldAngle), axis: (x: step.rotationAxis.x, y: step.rotationAxis.y, z: step.rotationAxis.z), anchor: step.anchor.unitPoint, perspective: 0.4)
                            .gesture(
                                DragGesture().onChanged { value in
                                    if !isFolded {
                                        let drag = value.translation.height + value.translation.width
                                        foldAngle = max(-180, min(180, drag))
                                    }
                                }
                                .onEnded { _ in
                                    let completionPercentage = abs(foldAngle) / abs(step.targetAngle)
                                    if completionPercentage > 0.6 {
                                        SoundManager.shared.playFoldSound()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { foldAngle = step.targetAngle; isFolded = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            engine.completeCurrentStep(); foldAngle = 0; isFolded = false
                                        }
                                    } else {
                                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) { foldAngle = 0 }
                                    }
                                }
                            )
                    }
                    .frame(width: paperDisplaySize, height: project.title == "Elite Pro Airplane" ? paperDisplaySize * 1.414 : paperDisplaySize)
                    .rotation3DEffect(.degrees(cameraTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .rotation3DEffect(.degrees(cameraPan), axis: (x: 0, y: 0, z: 1), perspective: 0.5)
                }
            }
            .scaleEffect(canvasScale)
            .gesture(MagnificationGesture().onChanged { canvasScale = $0 })
            
            // LAYER 3: ADAPTIVE UI OVERLAY
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline.bold())
                            .padding(.vertical, 14).padding(.horizontal, 24)
                            .background(.thickMaterial, in: Capsule()) // Adapts perfectly!
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(engine.progressText).font(.caption.bold()).foregroundColor(.secondary)
                        Text(project.title).font(.system(.subheadline, design: .rounded).weight(.heavy)).foregroundColor(.primary)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 30)
                    .background(.thickMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    
                    Spacer()
                    
                    Button(action: { withAnimation { cameraTilt = 35.0; cameraPan = -15.0; lastCameraTilt = 35.0; lastCameraPan = -15.0; canvasScale = 1.0 } }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.headline.bold())
                            .padding(.vertical, 14).padding(.horizontal, 24)
                            .background(.thickMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 30).padding(.top, 50)
                
                Spacer()
                
                if let step = engine.activeStep {
                    VStack(spacing: 12) {
                        Text(step.instruction)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20).padding(.horizontal, 40)
                            .background(.thickMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
                        
                        Text("Drag background to orbit in 3D ✨")
                            .font(.caption.bold())
                            .foregroundColor(Color.white.opacity(0.8)) // Stands out nicely on green
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { engine.startProject(project) }
    }
    
    private func shadowOpacity(for angle: Double) -> Double {
        let normalized = abs(angle)
        if normalized < 5 || normalized > 175 { return 0.0 }
        let peak = 1.0 - abs(normalized - 90) / 90.0
        return 0.3 * peak
    }
    
    private func shadowRadius(for angle: Double) -> CGFloat {
        let normalized = abs(angle)
        if normalized < 5 || normalized > 175 { return 0 }
        let peak = 1.0 - abs(normalized - 90) / 90.0
        return 20 * CGFloat(peak)
    }
}

// MARK: - CONSTANT WHITE VICTORY SCREENS

struct AirplaneVictory: View {
    let project: OrigamiProject; var dismissAction: DismissAction
    var body: some View {
        VStack(spacing: 40) {
            True3DAirplane(color: project.accentColor)
                .shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20)
                .padding(.vertical, 20)
            
            VStack(spacing: 12) {
                Text("Clear for Takeoff!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary)
                Text("You did it!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor)
            }
            
            Button(action: { dismissAction() }) {
                Text("Back to Gallery").font(.headline.weight(.heavy)).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5)
            }
        }
        .padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5))
    }
}

struct True3DAirplane: View {
    @State private var spin: Double = 0; var color: Color
    var body: some View {
        ZStack {
            PaperShape(points: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 1)]).fill(color).rotation3DEffect(.degrees(70), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
            PaperShape(points: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 1)]).fill(color.opacity(0.85)).rotation3DEffect(.degrees(-70), axis: (x: 0, y: 1, z: 0), anchor: .leading)
            
            // Constantly white inner body
            PaperShape(points: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.4, y: 1)]).fill(Color.white.opacity(0.9)).rotation3DEffect(.degrees(-80), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
            PaperShape(points: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.6, y: 1)]).fill(Color.white).rotation3DEffect(.degrees(80), axis: (x: 0, y: 1, z: 0), anchor: .leading)
        }
        .frame(width: 200, height: 250).rotation3DEffect(.degrees(20), axis: (x: 1, y: 0, z: 0)).rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
        .onAppear { withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = 360 } }
    }
}

struct ButterflyVictory: View {
    let project: OrigamiProject; var dismissAction: DismissAction
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                ButterflyShape(pointiness: 1.0).fill(project.accentColor).frame(width: 200, height: 160)
                ButterflyShape(pointiness: 0.6).fill(project.accentColor.opacity(0.8)).frame(width: 160, height: 120).offset(y: 80)
                
                // Constantly white body
                Capsule().fill(Color.white).frame(width: 20, height: 180).offset(y: 20)
            }.shadow(color: project.accentColor.opacity(0.4), radius: 20, y: 15)
            
            VStack(spacing: 12) {
                Text("Amazing!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary)
                Text("Expert Level Achieved!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor)
            }
            
            Button(action: { dismissAction() }) {
                Text("Back to Gallery").font(.headline.weight(.heavy)).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5)
            }
        }
        .padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5))
    }
}

struct SailboatVictory: View {
    let project: OrigamiProject; var dismissAction: DismissAction
    var body: some View {
        VStack(spacing: 40) {
            ZStack(alignment: .bottom) {
                // Constantly white sail
                Triangle().fill(Color.white).frame(width: 120, height: 160).offset(x: -20, y: -40)
                BoatHullShape().fill(project.accentColor).frame(width: 260, height: 80)
            }.shadow(color: project.accentColor.opacity(0.4), radius: 20, y: 15)
            
            VStack(spacing: 12) {
                Text("Smooth Sailing!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary)
                Text("You did it!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor)
            }
            
            Button(action: { dismissAction() }) {
                Text("Back to Gallery").font(.headline.weight(.heavy)).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5)
            }
        }
        .padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5))
    }
}
