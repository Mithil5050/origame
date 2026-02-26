import SwiftUI

struct ContentView: View {
    @State private var engine = OrigamiEngine()
    
    // Interaction States
    @State private var foldAngle: Double = 0.0
    @State private var isFolded: Bool = false
    
    // The fixed canvas size for our paper (320 points for pro-level visibility)
    let paperDisplaySize: CGFloat = 320
    
    var body: some View {
        ZStack {
            // LAYER 1: The Procedural Studio Background
            CuttingMatBackground()
            
            // LAYER 2: THE GAMEPLAY AREA
            if engine.isProjectComplete {
                // VICTORY STATE: The 100% Accurate End Result
                // This creates the final Sailboat silhouette seen in the video
                VStack(spacing: 40) {
                    ZStack(alignment: .bottom) {
                        // The Central Sail (White-backed side)
                        Triangle()
                            .fill(Color.white)
                            .frame(width: 120, height: 160)
                            .offset(x: -20, y: -40)
                        
                        // The Finished Hull (Primary Blue side)
                        BoatHullShape()
                            .fill(Color.blue)
                            .frame(width: 260, height: 80)
                    }
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 15)
                    
                    VStack(spacing: 12) {
                        Text("Accuracy Achieved!")
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundColor(.white)
                        Text("Vector Precision: High | Steps: 6/6")
                            .font(.subheadline.monospaced())
                            .foregroundColor(.cyan)
                    }
                    
                    Button("Restart Tutorial") {
                        withAnimation {
                            engine.startProject(OrigamiEngine.mockProjects[0])
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                }
                .padding(50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
                
            } else if let step = engine.activeStep {
                // ACTIVE VECTOR TUTORIAL STATE
                VStack {
                    Spacer()
                    
                    ZStack {
                        // 1. THE DYNAMIC PAPER BASE (The Polygon)
                        PaperShape(points: step.paperPoints)
                            .fill(Color.blue)
                            .frame(width: paperDisplaySize, height: paperDisplaySize)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: step.paperPoints)
                        
                        // 2. THE VECTOR CREASE LINE (Diagrammatic Guide)
                        VectorCreaseLine(points: step.creasePoints)
                            .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 8]))
                            .frame(width: paperDisplaySize, height: paperDisplaySize)
                            .opacity(isFolded ? 0 : 1)
                        
                        // 3. THE INTERACTIVE VECTOR FLAP
                        // We use white for the 'inside' of the fold to mimic real paper
                        PaperShape(points: step.flapPoints)
                            .fill(abs(foldAngle) > 90 ? Color.white : Color.blue.opacity(0.95))
                            .frame(width: paperDisplaySize, height: paperDisplaySize)
                            .rotation3DEffect(
                                .degrees(foldAngle),
                                axis: (x: step.rotationAxis.x, y: step.rotationAxis.y, z: step.rotationAxis.z),
                                anchor: step.anchor.unitPoint,
                                perspective: 0.4
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isFolded {
                                            // Handle multi-directional dragging for diagonal folds
                                            let drag = value.translation.height + value.translation.width
                                            foldAngle = max(-180, min(180, drag))
                                        }
                                    }
                                    .onEnded { value in
                                        if abs(foldAngle) > 130 {
                                            // SUCCESS SNAP
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                                foldAngle = step.targetAngle
                                                isFolded = true
                                            }
                                            
                                            // ADVANCE LOGIC
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                engine.completeCurrentStep()
                                                
                                                // Reset interaction for next vector flap
                                                foldAngle = 0
                                                isFolded = false
                                            }
                                        } else {
                                            // FAIL SNAP
                                            withAnimation(.spring()) { foldAngle = 0 }
                                        }
                                    }
                            )
                    }
                    
                    Spacer()
                }
            }
            
            // LAYER 3: TOP UI BAR
            VStack {
                HStack {
                    Text(engine.progressText)
                        .font(.headline.monospacedDigit())
                        .padding()
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    if let step = engine.activeStep {
                        Text(step.instruction)
                            .font(.subheadline.bold())
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: 240)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 50)
                
                Spacer()
            }
        }
        .onAppear {
            engine.startProject(OrigamiEngine.mockProjects[0])
        }
    }
}

// MARK: - FINAL RESULT COMPONENTS

/// A classic triangular sail for the victory screen
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

/// A geometrically accurate boat hull trapezoid matching the tutorial geometry
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

// MARK: - VECTOR COMPONENTS

struct PaperShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: points[i].x * rect.width, y: points[i].y * rect.height))
        }
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
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: points[i].x * rect.width, y: points[i].y * rect.height))
        }
        return path
    }
}

struct CuttingMatBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.1), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.1, green: 0.3, blue: 0.2))
                        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 15)
                    
                    Canvas { context, size in
                        let spacing: CGFloat = 30
                        var path = Path()
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 1)
                    }.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }.padding(30)
            }
        }
    }
}
