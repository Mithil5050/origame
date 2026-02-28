import SwiftUI

struct WorkspaceView: View {
    let project: OrigamiProject
    @Environment(OrigamiEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    
    @State private var foldAngle: Double = 0.0
    @State private var isFolded: Bool = false
    let paperDisplaySize: CGFloat = 340
    @State private var canvasScale: CGFloat = 1.0
    
    // ✨ TRACKS THE PHYSICAL ROTATION OF THE PAPER ✨
    @State private var isFlipped: Bool = false
    @State private var globalFlipAngle: Double = 0.0
    
    let paperUndersideColor = Color.white
    
    // Dynamically swaps the colors when looking at the back of the paper!
    func frontColor(for step: OrigamiStep?) -> Color {
        let baseColor = step?.colorOverride ?? project.accentColor
        return isFlipped ? paperUndersideColor : baseColor
    }
    
    func backColor(for step: OrigamiStep?) -> Color {
        let baseColor = step?.colorOverride ?? project.accentColor
        return isFlipped ? baseColor : paperUndersideColor
    }
    
    private var part1FinalStep: OrigamiStep? {
        if let idx = project.steps.firstIndex(where: { $0.isNextPartStep }), engine.currentStepIndex >= idx || engine.isWaitingForDone {
            return project.steps[idx - 1]
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            CuttingMatBackground()
            CoordinateGridView()
            
            ZStack {
                if engine.isProjectComplete {
                    Group {
                        if project.title == "Jumpy Frog" { FrogVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Cute Bunny" { RabbitVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Blue Whale" { WhaleVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Puppy Dog" { DogVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Cute Cat" { CatVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Origami Fox" { FoxVictory(project: project, dismissAction: dismiss)
                        } else if project.title == "Origami Heart" { HeartVictory(project: project, dismissAction: dismiss)
                        } else { SailboatVictory(project: project, dismissAction: dismiss) }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                    
                } else if let step = engine.activeStep {
                    ZStack {
                        // LAYER 1: The Static Base Paper
                        ZStack {
                            ForEach(0..<step.staticBase.count, id: \.self) { i in
                                PaperShape(points: step.staticBase[i]).fill(frontColor(for: step))
                            }
                            ForEach(0..<step.whiteBase.count, id: \.self) { i in
                                PaperShape(points: step.whiteBase[i]).fill(backColor(for: step))
                            }
                        }
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 15)
                        
                        // LAYER 2: Crease Lines (Hidden during a Flip step!)
                        if !step.isFlipStep {
                            VectorCreaseLine(points: step.creasePoints)
                                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                                .opacity(isFolded ? 0 : 1)
                        }
                        
                        // LAYER 3: The Moving Flaps
                        ZStack {
                            ForEach(0..<step.staticMoving.count, id: \.self) { i in
                                PaperShape(points: step.staticMoving[i])
                                    .fill(abs(foldAngle) > 90 ? backColor(for: step) : frontColor(for: step))
                            }
                            ForEach(0..<step.whiteMoving.count, id: \.self) { i in
                                PaperShape(points: step.whiteMoving[i])
                                    .fill(abs(foldAngle) > 90 ? frontColor(for: step) : backColor(for: step))
                            }
                        }
                        .shadow(color: .black.opacity(shadowOpacity(for: foldAngle)), radius: shadowRadius(for: foldAngle), y: shadowRadius(for: foldAngle) / 2)
                        .rotation3DEffect(
                            .degrees(foldAngle),
                            axis: (x: step.rotationAxis.x, y: step.rotationAxis.y, z: step.rotationAxis.z),
                            anchor: step.anchor,
                            perspective: 0.15
                        )
                        
                        // ✨ THE FROG FACE OVERLAY ✨
                        if project.title == "Jumpy Frog" && engine.isWaitingForDone && isFlipped {
                            FrogFaceDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 1 : 0) // Only shows on the back (the new front!)
                        }
                        
                        // ✨ THE WHALE EYE OVERLAY ✨
                        if project.title == "Blue Whale" && engine.isWaitingForDone && !isFlipped {
                            WhaleEyeDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 0 : 1) // Keeps it hidden when flipped
                        }
                        
                        // ✨ THE BUNNY FACE OVERLAY ✨
                        if project.title == "Cute Bunny" && engine.isWaitingForDone && isFlipped {
                            BunnyFaceDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 1 : 0) // Only shows on the back
                        }
                        
                        // ✨ THE DOG FACE OVERLAY ✨
                        if project.title == "Puppy Dog" && engine.isWaitingForDone && !isFlipped {
                            DogFaceDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 0 : 1) // Keeps it hidden when flipped
                        }
                        
                        // ✨ THE CAT FACE OVERLAY ✨
                        if project.title == "Cute Cat" && engine.isWaitingForDone && isFlipped {
                            CatFaceDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 1 : 0) // Only shows on the back
                        }
                        
                        // ✨ THE FOX FACE OVERLAY ✨
                        if project.title == "Origami Fox" && engine.isWaitingForDone && isFlipped {
                            FoxFaceDrawnOverlay()
                                .frame(width: paperDisplaySize, height: paperDisplaySize)
                                .opacity(isFlipped ? 1 : 0) // Only shows on the back
                        }
                        
                        // ✨ OVERLAY PART 1 (FLOWER) ON TOP OF PART 2 (STEM)
                        if let p1 = part1FinalStep {
                            ZStack {
                                ForEach(0..<p1.staticBase.count, id: \.self) { i in
                                    PaperShape(points: p1.staticBase[i]).fill(project.accentColor)
                                }
                                ForEach(0..<p1.whiteBase.count, id: \.self) { i in
                                    PaperShape(points: p1.whiteBase[i]).fill(paperUndersideColor)
                                }
                            }
                            .scaleEffect(0.65)
                            .offset(y: -paperDisplaySize * 0.38)
                            .zIndex(10) // Render high enough to be seen!
                        }
                    }
                    .frame(width: paperDisplaySize, height: paperDisplaySize)
                    
                    // ✨ THE MAGIC FLIP: Physically spins the entire assembly around! ✨
                    .rotation3DEffect(.degrees(globalFlipAngle), axis: (x: 0, y: 1, z: 0))
                    
                    .contentShape(Rectangle())
                    .id(step.id)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.98))))
                    
                    // Disables touch drag if we are supposed to hit the "Flip Paper" button
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isFolded && !step.isFlipStep {
                                    let dragDistance = hypot(value.translation.width, value.translation.height)
                                    let progress = min(1.0, dragDistance / 150.0)
                                    withAnimation(.interactiveSpring()) {
                                        foldAngle = progress * step.targetAngle
                                    }
                                }
                            }
                            .onEnded { _ in
                                if !isFolded && !step.isFlipStep { processFoldCompletion(step: step) }
                            }
                    )
                }
            }
            .scaleEffect(canvasScale)
            .gesture(MagnificationGesture().onChanged { canvasScale = $0 })
            
            // UI OVERLAY
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Label("Back", systemImage: "chevron.left").font(.headline.bold()).padding(.vertical, 14).padding(.horizontal, 24).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text(engine.progressText).font(.caption.bold()).foregroundColor(.secondary)
                        Text(project.title).font(.system(.subheadline, design: .rounded).weight(.heavy)).foregroundColor(.primary)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 30).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            engine.startProject(project)
                            canvasScale = 1.0
                            isFlipped = false
                            globalFlipAngle = 0
                            foldAngle = 0
                            isFolded = false
                        }
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise").font(.headline.bold()).padding(.vertical, 14).padding(.horizontal, 24).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                }
                .foregroundColor(.primary).padding(.horizontal, 30).padding(.top, 50)
                
                Spacer()
                
                // ✨ DYNAMIC BOTTOM CONTROLS (Swipe, Flip, or Done!) ✨
                if engine.isWaitingForDone {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            engine.finishProject()
                        }
                    }) {
                        Text("Done!")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundColor(.white)
                            .padding(.vertical, 18).padding(.horizontal, 60)
                            .background(Color.green, in: Capsule())
                            .shadow(color: .green.opacity(0.4), radius: 15, y: 8)
                    }
                    .padding(.bottom, 60)
                    
                } else if let step = engine.activeStep {
                    
                    if step.isNextPartStep {
                        VStack(spacing: 20) {
                            Text(step.instruction)
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundColor(.primary).multilineTextAlignment(.center).padding(.vertical, 20).padding(.horizontal, 40).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 15, y: 8)
                            
                            Button(action: {
                                SoundManager.shared.playFoldSound()
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    isFlipped = false
                                    globalFlipAngle = 0.0
                                    engine.completeCurrentStep()
                                }
                            }) {
                                Label("Start Next Part", systemImage: "sparkles")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16).padding(.horizontal, 30)
                                    .background(step.colorOverride ?? project.accentColor, in: Capsule())
                                    .shadow(color: (step.colorOverride ?? project.accentColor).opacity(0.4), radius: 10, y: 5)
                            }
                        }
                        .padding(.bottom, 60)
                        
                    } else if step.isFlipStep {
                        VStack(spacing: 20) {
                            Text(step.instruction)
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundColor(.primary).multilineTextAlignment(.center).padding(.vertical, 20).padding(.horizontal, 40).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 15, y: 8)
                            
                            // ✨ The Dedicated Flip Button!
                            Button(action: {
                                SoundManager.shared.playFoldSound()
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    globalFlipAngle += 180.0
                                    isFlipped.toggle()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    engine.completeCurrentStep()
                                }
                            }) {
                                Label("Flip Paper", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16).padding(.horizontal, 30)
                                    .background(Color.blue, in: Capsule())
                                    .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
                            }
                        }
                        .padding(.bottom, 60)
                        
                    } else {
                        VStack(spacing: 12) {
                            Text(step.instruction)
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundColor(.primary).multilineTextAlignment(.center).padding(.vertical, 20).padding(.horizontal, 40).background(.thickMaterial, in: Capsule()).shadow(color: .black.opacity(0.15), radius: 15, y: 8)
                            Text("Swipe anywhere to fold ✨").font(.caption.bold()).foregroundColor(Color.white.opacity(0.8))
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isFlipped = false
            globalFlipAngle = 0.0
            engine.startProject(project)
        }
    }
    
    // MARK: - PHYSICS HELPERS
    private func processFoldCompletion(step: OrigamiStep) {
        let completionPercentage = abs(foldAngle) / abs(step.targetAngle)
        if completionPercentage > 0.5 {
            isFolded = true
            SoundManager.shared.playFoldSound()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { foldAngle = step.targetAngle }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    engine.completeCurrentStep()
                    if !engine.isWaitingForDone {
                        foldAngle = 0
                        isFolded = false
                    }
                }
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) { foldAngle = 0 }
        }
    }
    
    private func shadowOpacity(for angle: Double) -> Double {
        let normalized = abs(angle)
        if normalized < 5 || normalized > 175 { return 0.0 }
        return 0.3 * (1.0 - abs(normalized - 90) / 90.0)
    }
    
    private func shadowRadius(for angle: Double) -> CGFloat {
        let normalized = abs(angle)
        if normalized < 5 || normalized > 175 { return 0 }
        return 20 * CGFloat(1.0 - abs(normalized - 90) / 90.0)
    }
}

// MARK: - ✨ IN-GAME DECORATIONS ON THE PAPER ✨
struct FrogFaceDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Left Eye
                Circle().fill(Color.white).frame(width: w*0.045, height: w*0.045).position(x: w*0.44, y: h*0.33)
                Circle().fill(Color.black).frame(width: w*0.02, height: w*0.02).position(x: w*0.44, y: h*0.33)
                
                // Right Eye
                Circle().fill(Color.white).frame(width: w*0.045, height: w*0.045).position(x: w*0.56, y: h*0.33)
                Circle().fill(Color.black).frame(width: w*0.02, height: w*0.02).position(x: w*0.56, y: h*0.33)
                
                // Smile
                Path { p in
                    p.move(to: CGPoint(x: w*0.47, y: h*0.37))
                    p.addCurve(to: CGPoint(x: w*0.53, y: h*0.37), control1: CGPoint(x: w*0.49, y: h*0.39), control2: CGPoint(x: w*0.51, y: h*0.39))
                }
                .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                // Cheek Freckles
                Circle().fill(Color.green).frame(width: w*0.02, height: w*0.02).position(x: w*0.41, y: h*0.36)
                Circle().fill(Color.green).frame(width: w*0.02, height: w*0.02).position(x: w*0.59, y: h*0.36)
            }
        }
    }
}

struct WhaleEyeDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Huge cute eye just like the picture!
                Circle().fill(Color.white).frame(width: w*0.12, height: w*0.12).position(x: w*0.35, y: h*0.43)
                Circle().fill(Color.black).frame(width: w*0.06, height: w*0.06).position(x: w*0.36, y: h*0.43)
                Circle().fill(Color.white).frame(width: w*0.02, height: w*0.02).position(x: w*0.35, y: h*0.41)
            }
        }
    }
}

struct BunnyFaceDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Left Eye
                Circle().fill(Color.white).frame(width: w*0.06, height: w*0.06).position(x: w*0.42, y: h*0.48)
                Circle().fill(Color.black).frame(width: w*0.03, height: w*0.03).position(x: w*0.42, y: h*0.48)
                
                // Right Eye
                Circle().fill(Color.white).frame(width: w*0.06, height: w*0.06).position(x: w*0.58, y: h*0.48)
                Circle().fill(Color.black).frame(width: w*0.03, height: w*0.03).position(x: w*0.58, y: h*0.48)
                
                // Cute little red nose
                Circle().fill(Color.pink).frame(width: w*0.025, height: w*0.025).position(x: w*0.5, y: h*0.52)
                
                // Little mouth lines
                Path { p in
                    p.move(to: CGPoint(x: w*0.5, y: h*0.52))
                    p.addLine(to: CGPoint(x: w*0.5, y: h*0.54))
                    p.addCurve(to: CGPoint(x: w*0.47, y: h*0.55), control1: CGPoint(x: w*0.5, y: h*0.55), control2: CGPoint(x: w*0.47, y: h*0.55))
                }
                .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
                Path { p in
                    p.move(to: CGPoint(x: w*0.5, y: h*0.54))
                    p.addCurve(to: CGPoint(x: w*0.53, y: h*0.55), control1: CGPoint(x: w*0.5, y: h*0.55), control2: CGPoint(x: w*0.53, y: h*0.55))
                }
                .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct DogFaceDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Left Eye - smaller, lower on face
                Ellipse().fill(Color.black).frame(width: w*0.065, height: w*0.075).position(x: w*0.38, y: h*0.66)
                Ellipse().fill(Color.white).frame(width: w*0.02, height: w*0.02).position(x: w*0.383, y: h*0.648)
                
                // Right Eye - smaller, lower on face
                Ellipse().fill(Color.black).frame(width: w*0.065, height: w*0.075).position(x: w*0.62, y: h*0.66)
                Ellipse().fill(Color.white).frame(width: w*0.02, height: w*0.02).position(x: w*0.623, y: h*0.648)
                
                // Nose - downward pointing triangle
                Path { p in
                    p.move(to: CGPoint(x: w*0.44, y: h*0.75))
                    p.addLine(to: CGPoint(x: w*0.56, y: h*0.75))
                    p.addLine(to: CGPoint(x: w*0.5, y: h*0.79))
                    p.closeSubpath()
                }.fill(Color.black)
            }
        }
    }
}

struct CatFaceDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Left Eye (Outer Yellow Circle)
                Circle().fill(Color.black).frame(width: w*0.08, height: w*0.08).position(x: w*0.35, y: h*0.6)
                Circle().fill(Color.yellow).frame(width: w*0.04, height: w*0.04).position(x: w*0.35, y: h*0.6)
                Circle().fill(Color.black).frame(width: w*0.02, height: w*0.02).position(x: w*0.35, y: h*0.6)
                
                // Right Eye (Outer Yellow Circle)
                Circle().fill(Color.black).frame(width: w*0.08, height: w*0.08).position(x: w*0.65, y: h*0.6)
                Circle().fill(Color.yellow).frame(width: w*0.04, height: w*0.04).position(x: w*0.65, y: h*0.6)
                Circle().fill(Color.black).frame(width: w*0.02, height: w*0.02).position(x: w*0.65, y: h*0.6)
                
                // Cat Nose
                Path { p in
                    p.move(to: CGPoint(x: w*0.47, y: h*0.7))
                    p.addLine(to: CGPoint(x: w*0.53, y: h*0.7))
                    p.addLine(to: CGPoint(x: w*0.5, y: h*0.73))
                    p.closeSubpath()
                }.fill(Color.black)
                
                // Cat Mouth
                Path { p in
                    p.move(to: CGPoint(x: w*0.45, y: h*0.77))
                    p.addCurve(to: CGPoint(x: w*0.5, y: h*0.73), control1: CGPoint(x: w*0.45, y: h*0.75), control2: CGPoint(x: w*0.5, y: h*0.75))
                    p.addCurve(to: CGPoint(x: w*0.55, y: h*0.77), control1: CGPoint(x: w*0.5, y: h*0.75), control2: CGPoint(x: w*0.55, y: h*0.75))
                }
                .stroke(Color.black, style: StrokeStyle(lineWidth: w*0.008, lineCap: .round, lineJoin: .round))
                
                // Whiskers Left
                Path { p in p.move(to: CGPoint(x: w*0.38, y: h*0.72)); p.addLine(to: CGPoint(x: w*0.28, y: h*0.7)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
                Path { p in p.move(to: CGPoint(x: w*0.36, y: h*0.75)); p.addLine(to: CGPoint(x: w*0.26, y: h*0.75)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
                Path { p in p.move(to: CGPoint(x: w*0.38, y: h*0.78)); p.addLine(to: CGPoint(x: w*0.28, y: h*0.8)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
                
                // Whiskers Right
                Path { p in p.move(to: CGPoint(x: w*0.62, y: h*0.72)); p.addLine(to: CGPoint(x: w*0.72, y: h*0.7)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
                Path { p in p.move(to: CGPoint(x: w*0.64, y: h*0.75)); p.addLine(to: CGPoint(x: w*0.74, y: h*0.75)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
                Path { p in p.move(to: CGPoint(x: w*0.62, y: h*0.78)); p.addLine(to: CGPoint(x: w*0.72, y: h*0.8)) }.stroke(Color.black, style: StrokeStyle(lineWidth: w*0.005, lineCap: .round))
            }
        }
    }
}

// MARK: - ✨ THE VICTORY GRAPHICS & SCREENS ✨
struct FrogVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.7, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.95, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.7, y: h*0.9)); p.addLine(to: CGPoint(x: w*0.3, y: h*0.9)); p.addLine(to: CGPoint(x: w*0.05, y: h*0.6)) }.fill(color); Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.2, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.4, y: h*0.3)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: -2); Path { p in p.move(to: CGPoint(x: w*0.7, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.8, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.6, y: h*0.3)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: -2, y: -2); Circle().fill(Color.white).frame(width: w*0.16, height: w*0.16).position(x: w*0.28, y: h*0.25); Circle().fill(Color.black).frame(width: w*0.06, height: w*0.06).position(x: w*0.28, y: h*0.25); Circle().fill(Color.white).frame(width: w*0.16, height: w*0.16).position(x: w*0.72, y: h*0.25); Circle().fill(Color.black).frame(width: w*0.06, height: w*0.06).position(x: w*0.72, y: h*0.25); Circle().fill(Color.green.opacity(0.8)).frame(width: w*0.1, height: w*0.1).position(x: w*0.25, y: h*0.6); Circle().fill(Color.green.opacity(0.8)).frame(width: w*0.1, height: w*0.1).position(x: w*0.75, y: h*0.6); Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.7)); p.addCurve(to: CGPoint(x: w*0.7, y: h*0.7), control1: CGPoint(x: w*0.4, y: h*0.85), control2: CGPoint(x: w*0.6, y: h*0.85)) }.stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round)) } } } }
struct RabbitVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.7, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.6, y: h*0.95)); p.addLine(to: CGPoint(x: w*0.4, y: h*0.95)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.65)) }.fill(color); Path { p in p.move(to: CGPoint(x: w*0.4, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.2, y: h*0.0)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.45)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: -2, y: 2); Path { p in p.move(to: CGPoint(x: w*0.6, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.8, y: h*0.0)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.45)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 2); Circle().fill(Color.black).frame(width: w*0.08, height: w*0.08).position(x: w*0.35, y: h*0.65); Circle().fill(Color.black).frame(width: w*0.08, height: w*0.08).position(x: w*0.65, y: h*0.65); Circle().fill(Color.red).frame(width: w*0.06, height: w*0.06).position(x: w*0.5, y: h*0.75); Group { Path { p in p.move(to: CGPoint(x: w*0.4, y: h*0.72)); p.addLine(to: CGPoint(x: w*0.2, y: h*0.68)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.4, y: h*0.75)); p.addLine(to: CGPoint(x: w*0.18, y: h*0.75)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.4, y: h*0.78)); p.addLine(to: CGPoint(x: w*0.2, y: h*0.82)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.6, y: h*0.72)); p.addLine(to: CGPoint(x: w*0.8, y: h*0.68)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.6, y: h*0.75)); p.addLine(to: CGPoint(x: w*0.82, y: h*0.75)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.6, y: h*0.78)); p.addLine(to: CGPoint(x: w*0.8, y: h*0.82)) }.stroke(Color.black, lineWidth: 2) } } } } }
struct WhaleVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.1, y: h*0.4)); p.addLine(to: CGPoint(x: w*0.8, y: h*0.4)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.95, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.85, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.8)); p.addLine(to: CGPoint(x: w*0.15, y: h*0.8)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.4)) }.fill(color); Circle().fill(Color.white).frame(width: w*0.22, height: w*0.22).position(x: w*0.28, y: h*0.55); Circle().fill(Color.black).frame(width: w*0.14, height: w*0.14).position(x: w*0.26, y: h*0.55); Circle().fill(Color.white).frame(width: w*0.04, height: w*0.04).position(x: w*0.24, y: h*0.53) } } } }
struct DogVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.15, y: h*0.25)); p.addLine(to: CGPoint(x: w*0.85, y: h*0.25)); p.addLine(to: CGPoint(x: w*0.65, y: h*0.85)); p.addLine(to: CGPoint(x: w*0.35, y: h*0.85)) }.fill(color); Path { p in p.move(to: CGPoint(x: w*0.45, y: h*0.25)); p.addLine(to: CGPoint(x: w*0.0, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.9)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 2); Path { p in p.move(to: CGPoint(x: w*0.55, y: h*0.25)); p.addLine(to: CGPoint(x: w*1.0, y: h*0.45)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.9)) }.fill(color).shadow(color: .black.opacity(0.15), radius: 2, x: -2, y: 2); Path { p in p.move(to: CGPoint(x: w*0.35, y: h*0.85)); p.addLine(to: CGPoint(x: w*0.65, y: h*0.85)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.6)) }.fill(Color.white).shadow(color: .black.opacity(0.1), radius: 2, y: -2); ZStack { Circle().fill(Color.black).frame(width: w*0.12, height: w*0.12).position(x: w*0.38, y: h*0.45); Circle().fill(Color.white).frame(width: w*0.03, height: w*0.03).position(x: w*0.39, y: h*0.43); Circle().fill(Color.black).frame(width: w*0.12, height: w*0.12).position(x: w*0.62, y: h*0.45); Circle().fill(Color.white).frame(width: w*0.03, height: w*0.03).position(x: w*0.63, y: h*0.43) }; Path { p in p.move(to: CGPoint(x: w*0.45, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.55, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.53, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.47, y: h*0.65)) }.fill(Color.black); Path { p in p.move(to: CGPoint(x: w*0.5, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.7)); p.addCurve(to: CGPoint(x: w*0.42, y: h*0.68), control1: CGPoint(x: w*0.5, y: h*0.75), control2: CGPoint(x: w*0.42, y: h*0.75)) }.stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round)); Path { p in p.move(to: CGPoint(x: w*0.5, y: h*0.7)); p.addCurve(to: CGPoint(x: w*0.58, y: h*0.68), control1: CGPoint(x: w*0.5, y: h*0.75), control2: CGPoint(x: w*0.58, y: h*0.75)) }.stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round)) } } } }
struct CatVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.1, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.9)) }.fill(color); Path { p in p.move(to: CGPoint(x: w*0.1, y: h*0.3)); p.addLine(to: CGPoint(x: w*0.0, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.35, y: h*0.3)) }.fill(color.opacity(0.85)); Path { p in p.move(to: CGPoint(x: w*0.9, y: h*0.3)); p.addLine(to: CGPoint(x: w*1.0, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.65, y: h*0.3)) }.fill(color.opacity(0.85)); Path { p in p.move(to: CGPoint(x: w*0.45, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.55, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.65)) }.fill(Color.pink); ZStack { Circle().stroke(Color.black, lineWidth: 3).frame(width: w*0.15, height: w*0.15).position(x: w*0.35, y: h*0.45); Circle().fill(Color.black).frame(width: w*0.06, height: w*0.06).position(x: w*0.35, y: h*0.45); Circle().stroke(Color.black, lineWidth: 3).frame(width: w*0.15, height: w*0.15).position(x: w*0.65, y: h*0.45); Circle().fill(Color.black).frame(width: w*0.06, height: w*0.06).position(x: w*0.65, y: h*0.45) }; Group { Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.55)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.5)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.08, y: h*0.6)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.3, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.7)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.7, y: h*0.55)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.5)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.7, y: h*0.6)); p.addLine(to: CGPoint(x: w*0.92, y: h*0.6)) }.stroke(Color.black, lineWidth: 2); Path { p in p.move(to: CGPoint(x: w*0.7, y: h*0.65)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.7)) }.stroke(Color.black, lineWidth: 2) } } } } }

struct FoxVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; ZStack { Path { p in p.move(to: CGPoint(x: w*0.15, y: h*0.5)); p.addLine(to: CGPoint(x: w*0.85, y: h*0.5)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.9)) }.fill(color); Path { p in p.move(to: CGPoint(x: w*0.15, y: h*0.5)); p.addLine(to: CGPoint(x: w*0.1, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.45, y: h*0.5)) }.fill(color.opacity(0.85)); Path { p in p.move(to: CGPoint(x: w*0.85, y: h*0.5)); p.addLine(to: CGPoint(x: w*0.9, y: h*0.1)); p.addLine(to: CGPoint(x: w*0.55, y: h*0.5)) }.fill(color.opacity(0.85)); Circle().fill(Color.black).frame(width: w*0.12, height: w*0.12).position(x: w*0.5, y: h*0.85); Path { p in p.move(to: CGPoint(x: w*0.35, y: h*0.6)); p.addCurve(to: CGPoint(x: w*0.42, y: h*0.65), control1: CGPoint(x: w*0.35, y: h*0.6), control2: CGPoint(x: w*0.38, y: h*0.65)) }.stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round)); Path { p in p.move(to: CGPoint(x: w*0.65, y: h*0.6)); p.addCurve(to: CGPoint(x: w*0.58, y: h*0.65), control1: CGPoint(x: w*0.65, y: h*0.6), control2: CGPoint(x: w*0.62, y: h*0.65)) }.stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round)) } } } }

struct FoxFaceDrawnOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Fox Nose (cute round dot at the bottom tip)
                Circle()
                    .fill(Color.black)
                    .frame(width: w*0.06, height: w*0.06)
                    .position(x: w*0.5, y: h*0.85)
                
                // Left sleepy eye
                Path { p in
                    p.move(to: CGPoint(x: w*0.35, y: h*0.7))
                    p.addCurve(to: CGPoint(x: w*0.42, y: h*0.73), control1: CGPoint(x: w*0.35, y: h*0.7), control2: CGPoint(x: w*0.38, y: h*0.73))
                }
                .stroke(Color.black, style: StrokeStyle(lineWidth: w*0.015, lineCap: .round))
                
                // Right sleepy eye
                Path { p in
                    p.move(to: CGPoint(x: w*0.65, y: h*0.7))
                    p.addCurve(to: CGPoint(x: w*0.58, y: h*0.73), control1: CGPoint(x: w*0.65, y: h*0.7), control2: CGPoint(x: w*0.62, y: h*0.73))
                }
                .stroke(Color.black, style: StrokeStyle(lineWidth: w*0.015, lineCap: .round))
            }
        }
    }
}
struct HeartVictoryGraphic: View { var color: Color; var body: some View { GeometryReader { geo in let w = geo.size.width; let h = geo.size.height; Path { p in p.move(to: CGPoint(x: w*0.5, y: h*0.3)); p.addCurve(to: CGPoint(x: w, y: h*0.35), control1: CGPoint(x: w*0.6, y: h*0.0), control2: CGPoint(x: w*1.0, y: h*0.0)); p.addCurve(to: CGPoint(x: w*0.5, y: h*0.9), control1: CGPoint(x: w, y: h*0.6), control2: CGPoint(x: w*0.5, y: h*0.8)); p.addCurve(to: CGPoint(x: 0, y: h*0.35), control1: CGPoint(x: w*0.5, y: h*0.8), control2: CGPoint(x: 0, y: h*0.6)); p.addCurve(to: CGPoint(x: w*0.5, y: h*0.3), control1: CGPoint(x: 0, y: h*0.0), control2: CGPoint(x: w*0.4, y: h*0.0)) }.fill(color) } } }

struct FrogVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { FrogVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Ribbit!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Frog!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct RabbitVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { RabbitVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Hop Hop!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Bunny!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct WhaleVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { WhaleVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Splash!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Whale!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct DogVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { DogVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Woof! Woof!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Puppy!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct CatVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { CatVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Meow!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Kitty!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }

struct FoxVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { FoxVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Yip Yip!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Fox!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct HeartVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { HeartVictoryGraphic(color: project.accentColor).frame(width: 180, height: 180).shadow(color: project.accentColor.opacity(0.4), radius: 25, y: 20).padding(.vertical, 20); VStack(spacing: 12) { Text("Lovely!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You made a Heart!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
struct SailboatVictory: View { let project: OrigamiProject; var dismissAction: DismissAction; var body: some View { VStack(spacing: 40) { ZStack(alignment: .bottom) { Triangle().fill(Color.white).frame(width: 120, height: 160).offset(x: -20, y: -40); BoatHullShape().fill(project.accentColor).frame(width: 260, height: 80) }.shadow(color: project.accentColor.opacity(0.4), radius: 20, y: 15); VStack(spacing: 12) { Text("Smooth Sailing!").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(.primary); Text("You did it!").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(project.accentColor) }; Button(action: { dismissAction() }) { Text("Back to Gallery").font(.system(.headline, design: .rounded)).fontWeight(.heavy).foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(project.accentColor, in: Capsule()).shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5) } }.padding(60).background(.thickMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous)).shadow(color: .black.opacity(0.1), radius: 30, y: 15).overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(project.accentColor.opacity(0.3), lineWidth: 5)) } }
