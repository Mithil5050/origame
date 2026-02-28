import SwiftUI

struct HomeGalleryView: View {
    @State private var engine = OrigamiEngine()
    @Environment(\.colorScheme) var colorScheme
    
    // Group projects by difficulty
    var easyProjects: [OrigamiProject] { OrigamiEngine.mockProjects.filter { $0.difficulty == "Beginner" } }
    var intermediateProjects: [OrigamiProject] { OrigamiEngine.mockProjects.filter { $0.difficulty == "Intermediate" } }
    var hardProjects: [OrigamiProject] { OrigamiEngine.mockProjects.filter { $0.difficulty == "Expert" } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // AMBIENT BACKGROUND
                (colorScheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color(red: 0.95, green: 0.97, blue: 1.0))
                    .ignoresSafeArea()
                
                GeometryReader { geo in
                    Circle()
                        .fill(Color.purple.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        .frame(width: 400, height: 400)
                        .blur(radius: 120)
                        .offset(x: -100, y: -100)
                    
                    Circle()
                        .fill(Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        .frame(width: 500, height: 500)
                        .blur(radius: 150)
                        .offset(x: geo.size.width - 250, y: geo.size.height * 0.4)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 35) {
                        
                        // CENTERED HEADER
                        VStack(spacing: 12) {
                            OrigamiBirdMascot()
                            
                            Text("Origame")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Pick a paper adventure")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                        
                        // EASY SECTION
                        if !easyProjects.isEmpty {
                            DifficultySection(title: "Easy", iconName: "leaf.fill", color: .green, projects: easyProjects)
                        }
                        
                        // INTERMEDIATE SECTION
                        if !intermediateProjects.isEmpty {
                            DifficultySection(title: "Intermediate", iconName: "star.fill", color: .orange, projects: intermediateProjects)
                        }
                        
                        // HARD SECTION
                        if !hardProjects.isEmpty {
                            DifficultySection(title: "Hard", iconName: "flame.fill", color: .red, projects: hardProjects)
                        }
                    }
                    .padding(.bottom, 60)
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

// MARK: - DIFFICULTY SECTION
struct DifficultySection: View {
    let title: String
    let iconName: String
    let color: Color
    let projects: [OrigamiProject]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                
                Capsule()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 22)
                    .overlay(
                        Text("\(projects.count)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(color)
                    )
            }
            .padding(.horizontal, 30)
            
            // Horizontal scrollable row of cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(projects) { project in
                        NavigationLink(value: project) {
                            KidProjectCard(project: project)
                                .frame(width: 260)
                        }
                        .buttonStyle(BouncyKidCardStyle())
                    }
                }
                .padding(.horizontal, 30)
            }
        }
    }
}

// MARK: - ✨ PREMIUM FROSTED GLASS CARD ✨
struct KidProjectCard: View {
    let project: OrigamiProject
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(project.accentColor.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: project.iconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(project.accentColor)
                    .shadow(color: project.accentColor.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.top, 24)
            
            VStack(spacing: 12) {
                Text(project.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                KidDifficultyBadge(difficulty: project.difficulty, color: project.accentColor)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        
        // ✨ THE GLASSMORPHISM MAGIC ✨
        // Uses ultraThinMaterial to blur the glowing background behind it
        .background(.ultraThinMaterial)
        .background(project.accentColor.opacity(0.05)) // Subtle tint
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 25, y: 15) // Soft, deep shadow
        
        // Elegant 1px translucent border instead of the thick neon stroke
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(colorScheme == .dark ? 0.2 : 0.6), .white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - REFINED BADGE
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
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(index < stars ? color : color.opacity(0.2))
            }
            
            Text(difficulty.uppercased())
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - SMOOTHER ANIMATION
struct BouncyKidCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - THE ORIGAMI BIRD MASCOT
struct OrigamiBirdMascot: View {
    @State private var isFloating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.6, y: 0.3)])
                .fill(Color(red: 0.2, green: 0.4, blue: 0.9))
            
            PaperShape(points: [CGPoint(x: 0.1, y: 0.8), CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.3, y: 0.9)])
                .fill(Color(red: 0.4, green: 0.7, blue: 1.0))
            
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.8, y: 0.6), CGPoint(x: 0.1, y: 0.8)])
                .fill(Color.cyan)
            
            PaperShape(points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.3, y: 0.0), CGPoint(x: 0.7, y: 0.4)])
                .fill(colorScheme == .dark ? Color.white.opacity(0.85) : Color.white)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
            
            PaperShape(points: [CGPoint(x: 0.8, y: 0.6), CGPoint(x: 0.9, y: 0.2), CGPoint(x: 0.7, y: 0.5)])
                .fill(Color(red: 0.2, green: 0.4, blue: 0.9))
                
            PaperShape(points: [CGPoint(x: 0.9, y: 0.2), CGPoint(x: 1.0, y: 0.15), CGPoint(x: 0.85, y: 0.25)])
                .fill(Color.orange)
        }
        .frame(width: 130, height: 130) // Slightly smaller
        .shadow(color: colorScheme == .dark ? .purple.opacity(0.4) : .blue.opacity(0.3), radius: isFloating ? 20 : 10, y: isFloating ? 25 : 10)
        .offset(y: isFloating ? -15 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}
