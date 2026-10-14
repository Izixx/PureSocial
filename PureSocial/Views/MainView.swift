import SwiftUI

/// Vue maîtresse de PureSocial gérant le cycle de vie de l'application :
/// 1. Questionnaire initial (Onboarding Quiz)
/// 2. Écran d'accueil central (Home Hub)
/// 3. Navigation plein écran immersive sans barre parasite
public struct MainView: View {
    @StateObject private var config = ConfigManager.shared
    
    // Plateforme active (si nil, l'utilisateur est sur l'écran d'accueil)
    @State private var activePlatform: SocialPlatform? = nil
    
    // États modaux
    @State private var showingSettings: Bool = false
    @State private var showingFriction: Bool = false
    @State private var pendingPlatform: SocialPlatform? = nil
    @State private var isRedoingQuiz: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // 1. Questionnaire initial si premier lancement ou si réinitialisation demandée
            if !config.hasCompletedOnboarding || isRedoingQuiz {
                OnboardingQuizView(config: config) {
                    isRedoingQuiz = false
                }
                .transition(.opacity)
            } else {
                // 2. Si aucune plateforme n'est ouverte : Affichage de l'Écran d'Accueil Hub
                if let platform = activePlatform {
                    ImmersiveSocialView(platform: platform, config: config) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activePlatform = nil
                        }
                    }
                    .transition(.opacity)
                } else {
                    HomeHubView(
                        config: config,
                        onSelectPlatform: { platform in
                            handlePlatformSelection(platform)
                        },
                        onOpenSettings: {
                            showingSettings = true
                        },
                        onRestartQuiz: {
                            withAnimation {
                                isRedoingQuiz = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        // Écran de friction intentionnelle avant d'ouvrir un réseau
        .fullScreenCover(isPresented: $showingFriction) {
            if let targetPlatform = pendingPlatform {
                FrictionView(
                    platform: targetPlatform,
                    durationSeconds: config.frictionDurationSeconds,
                    onProceed: {
                        showingFriction = false
                        // Léger délai pour permettre la fermeture propre de la vue modale
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            activePlatform = targetPlatform
                            pendingPlatform = nil
                        }
                    },
                    onCancel: {
                        showingFriction = false
                        pendingPlatform = nil
                    }
                )
            }
        }
        // Panneau de réglages
        .sheet(isPresented: $showingSettings) {
            SettingsView(config: config)
        }
    }
    
    private func handlePlatformSelection(_ platform: SocialPlatform) {
        if config.intentionalFrictionEnabled {
            pendingPlatform = platform
            showingFriction = true
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                activePlatform = platform
            }
        }
    }
}
