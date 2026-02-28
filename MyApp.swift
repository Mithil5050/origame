import SwiftUI

@main
struct OrigameApp: App {
    init() {
        // Pre-warm audio so the first fold doesn't lag
        _ = SoundManager.shared
        
        // Set window background to match splash screen (reduces black flash)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.forEach { $0.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1) }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
}
