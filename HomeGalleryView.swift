import SwiftUI

struct HomeGalleryView: View {
    @State private var engine = OrigamiEngine()
    @Environment(\.colorScheme) var colorScheme
    
    let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 35)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. ADAPTIVE DAY/NIGHT BACKGROUND
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.1), Color.black]
                        : [Color(red: 0.8, green: 0.95, blue: 1.0), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                // Adaptive floating clouds/glows
                GeometryReader { geo in
                    Circle()
                        .fill(colorScheme == .dark ? Color.purple.opacity(0.15) : Color.white.opacity(0.8))
                        .frame(width: 250, height: 250)
                        .offset(x: -80, y: -60)
                    
                    Circle()
                        .fill(colorScheme == .dark ? Color.blue.opacity(0.15) : Color.white.opacity(0.6))
                        .frame(width: 400, height: 400)
                        .offset(x: geo.size.width - 200, y: geo.size.height * 0.4)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 40) {
                        
                        // 2. ADAPTIVE TYPOGRAPHY & MASCOT HEADER
                        VStack(spacing: 12) {
                            
                            // ✨ YOUR NEW FLOATING MASCOT ✨
                            OrigamiBirdMascot()
                                .padding(.bottom, 10)
                            
                            Text("Origami Fun!")
                                .font(.system(size: 54, weight: .heavy, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.4, blue: 0.9))
                                .shadow(color: colorScheme == .dark ? .purple.opacity(0.3) : .blue.opacity(0.2), radius: 5, y: 5)
                            
                            Text("Pick a paper adventure ✨")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.4, green: 0.6, blue: 1.0))
                        }
                        .padding(.top, 40)
                        
                        // 3. ADAPTIVE CARDS GRID
                        LazyVGrid(columns: columns, spacing: 35) {
                            ForEach(OrigamiEngine.mockProjects) { project in
                                NavigationLink(value: project) {
                                    KidProjectCard(project: project)
                                }
                                .buttonStyle(BouncyKidCardStyle())
                            }
                        }
                        .padding(.horizontal, 25)
                    }
                    .padding(.bottom, 50)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: OrigamiProject.self) { project in
                WorkspaceView(project: project)
                    .environment(engine)
            }
        }
    }
}

// MARK: - ✨ THE ORIGAMI BIRD MASCOT ✨
struct OrigamiBirdMascot: View {
    @State private var isFloating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Back Wing (Dark Blue)
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.6, y: 0.3)])
                .fill(Color(red: 0.2, green: 0.4, blue: 0.9))
            
            // Tail (Light Blue)
            PaperShape(points: [CGPoint(x: 0.1, y: 0.8), CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.3, y: 0.9)])
                .fill(Color(red: 0.4, green: 0.7, blue: 1.0))
            
            // Body (Cyan)
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.8, y: 0.6), CGPoint(x: 0.1, y: 0.8)])
                .fill(Color.cyan)
            
            // Front Wing (Adapts to Dark/Light Mode)
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.3, y: 0.0), CGPoint(x: 0.7, y: 0.4)])
                .fill(colorScheme == .dark ? Color.white.opacity(0.8) : Color.white)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
            
            // Neck
            PaperShape(points: [CGPoint(x: 0.8, y: 0.6), CGPoint(x: 0.9, y: 0.2), CGPoint(x: 0.7, y: 0.5)])
                .fill(Color(red: 0.2, green: 0.4, blue: 0.9))
                
            // Beak (Orange)
            PaperShape(points: [CGPoint(x: 0.9, y: 0.2), CGPoint(x: 1.0, y: 0.15), CGPoint(x: 0.85, y: 0.25)])
                .fill(Color.orange)
        }
        .frame(width: 140, height: 140)
        // Bouncy shadow
        .shadow(color: colorScheme == .dark ? .purple.opacity(0.4) : .blue.opacity(0.3), radius: isFloating ? 20 : 10, y: isFloating ? 25 : 10)
        .offset(y: isFloating ? -15 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

// MARK: - ADAPTIVE CHUNKY CARD
struct KidProjectCard: View {
    let project: OrigamiProject
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(project.accentColor.opacity(0.15))
                    .frame(height: 160)
                
                Image(systemName: project.iconName)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(project.accentColor)
                    .rotationEffect(.degrees(-8))
                    .shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.top, 35)
            
            VStack(spacing: 12) {
                Text(project.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                KidDifficultyBadge(difficulty: project.difficulty, color: project.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 35)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .shadow(color: project.accentColor.opacity(0.2), radius: 20, y: 15)
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(project.accentColor.opacity(0.6), lineWidth: 5)
        )
    }
}

struct KidDifficultyBadge: View {
    let difficulty: String
    let color: Color
    
    var stars: Int {
        switch difficulty.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "expert": return 3
        default: return 1
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(index < stars ? color : Color.gray.opacity(0.2))
            }
            
            Text(difficulty.uppercased())
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct BouncyKidCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? -2 : 0))
            .animation(.interpolatingSpring(stiffness: 250, damping: 15), value: configuration.isPressed)
    }
}
