import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if isActive {
            HomeGalleryView()
                .transition(.opacity)
        } else {
            ZStack {
                // Background
                (colorScheme == .dark
                    ? Color(red: 0.05, green: 0.05, blue: 0.08)
                    : Color(red: 0.95, green: 0.97, blue: 1.0))
                    .ignoresSafeArea()
                
                // Soft ambient glow
                Circle()
                    .fill(Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 100)
                
                VStack(spacing: 24) {
                    // Mascot
                    OrigamiBirdMascot()
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App Name
                    Text("Origame")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                    Color.cyan,
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.4), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Text("Origame")
                                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                                )
                        )
                    
                    Text("Fold, Create, Enjoy ✨")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
            }
            .onAppear {
                // Animate in
                withAnimation(.easeOut(duration: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    textOpacity = 1.0
                }
                // Shimmer
                withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                    shimmerOffset = 200
                }
                // Transition to home
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
