import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    
    private init() {
        // Ensure sound plays even on silent mode and mixes gracefully
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func playFoldSound() {
        if let url = findAudioFileURL() {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = 10.0
                player?.prepareToPlay()
                player?.play()
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
        
        // Get the root of the app
        guard let bundleURL = Bundle.main.resourceURL else { return nil }
        
        // Scan every single file and subfolder
        if let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                // If it finds ANY file starting with "paper_fold", it grabs it!
                if fileURL.lastPathComponent.hasPrefix("paper_fold") {
                    print("✅ Found the audio file at: \(fileURL.path)")
                    return fileURL
                }
            }
        }
        return nil
    }
}
