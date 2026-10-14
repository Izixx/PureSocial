import SwiftUI

@main
struct PureSocialApp: App {
    @StateObject private var config = ConfigManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(config)
                .preferredColorScheme(nil) // Respecte le mode clair/sombre de l'appareil
        }
    }
}
