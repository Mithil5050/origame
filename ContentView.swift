import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @State private var foldAngle: Double = 0.0
    @State private var isFolded: Bool = false
    
    var body: some View {
        ZStack {
            // LAYER 1 & 2: The Desk and Cutting Mat
            CuttingMatBackground()
            
            // LAYER 3: The Work-in-Progress Paper (The Hero)
            VStack(spacing: 0) {
                // Top Half (Flat on the mat)
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: 240, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 5)
                
                // Bottom Half (The Interactive Fold)
                Rectangle()
                    // If folded past 90 degrees, show the "white" back of the paper
                    .fill(foldAngle < -90 ? Color.white : Color.cyan.opacity(0.95))
                    .frame(width: 240, height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "hand.draw")
                                .font(.title)
                            Text("Drag up to fold")
                                .font(.caption.bold())
                        }
                        .foregroundColor(foldAngle < -90 ? .clear : .white)
                    )
                    // The 3D Hinge Magic
                    .rotation3DEffect(
                        .degrees(foldAngle),
                        axis: (x: 1.0, y: 0.0, z: 0.0),
                        anchor: .top,
                        perspective: 0.4 // Gives it realistic 3D camera depth
                    )
                    .shadow(color: .black.opacity(0.4), radius: isFolded ? 2 : 15, x: 0, y: isFolded ? 2 : 20)
                    // The Gesture
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isFolded else { return }
                                let fraction = max(0, min(1, -value.translation.height / 120))
                                foldAngle = fraction * -180
                            }
                            .onEnded { value in
                                guard !isFolded else { return }
                                let fraction = max(0, min(1, -value.translation.height / 120))
                                
                                if fraction > 0.5 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        foldAngle = -180
                                        isFolded = true
                                    }
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                        foldAngle = 0
                                    }
                                }
                            }
                    )
            }
            // A visual "crease line" to guide the user
            .overlay(
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 2),
                alignment: .center
            )
            
            // LAYER 4: The Floating HIG UI
            VStack {
                HStack {
                    Button(action: { /* Reset logic later */ }) {
                        Image(systemName: "chevron.left")
                        Text("Gallery")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Text("Step 1 of 12")
                        .font(.headline.monospacedDigit())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Button(action: { /* Hint logic later */ }) {
                        Image(systemName: "lightbulb.fill")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Circle())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Procedural Background Component
struct CuttingMatBackground: View {
    var body: some View {
        ZStack {
            // Layer 1: Walnut Desk Gradient
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.22, blue: 0.15), Color(red: 0.15, green: 0.08, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Layer 2: The Mat & Canvas Grid
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.40, blue: 0.28))
                        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 15)
                    
                    Canvas { context, size in
                        let spacing: CGFloat = 25
                        var path = Path()
                        
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .padding(30)
            }
        }
    }
}
