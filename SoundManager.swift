import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private var players: [AVAudioPlayer] = []
    private var soundURL: URL?
    
    private init() {
        // Ensure sound plays even on silent mode and mixes gracefully
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Find the sound once
        if let url = findAudioFileURL() {
            self.soundURL = url
            
            // Pre-warm a player so the first fold doesn't lag
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = 1.0
                player.prepareToPlay()
                players.append(player)
            }
        }
    }
    
    func playFoldSound() {
        if let url = soundURL {
            do {
                // Find an available player, or create a new one to allow overlapping sounds during rapid folds
                if let availablePlayer = players.first(where: { !$0.isPlaying }) {
                    availablePlayer.play()
                } else {
                    let newPlayer = try AVAudioPlayer(contentsOf: url)
                    newPlayer.volume = 1.0
                    newPlayer.prepareToPlay()
                    newPlayer.play()
                    players.append(newPlayer)
                }
            } catch {
                print("❌ Playback Error: \(error.localizedDescription)")
                AudioServicesPlaySystemSound(1104) // Fallback click
            }
        } else {
            print("❌ Deep Scan Failed: The file isn't bundled. Try deleting the Resources folder and adding the file using the '+' button at the bottom left of the sidebar.")
            AudioServicesPlaySystemSound(1104) // Fallback click
        }
    }
    
    // MARK: - THE DEEP SCANNER
    // This recursively searches EVERY folder inside the app for the audio file
    private func findAudioFileURL() -> URL? {
        let fileManager = FileManager.default
        
        // 1. Check standard Bundle.main (For normal iOS Deployments)
        if let bundleURL = Bundle.main.resourceURL,
           let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent.hasPrefix("paper_fold") {
                    print("✅ Found via Bundle.main: \(fileURL.path)")
                    return fileURL
                }
            }
        }
        
        // 2. Check the raw file path directly (For Swift Playgrounds / Previews)
        let rootPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        if let enumerator = fileManager.enumerator(at: rootPath, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent.hasPrefix("paper_fold") {
                    print("✅ Found via absolute path: \(fileURL.path)")
                    return fileURL
                }
            }
        }
        
        return nil
    }
}
