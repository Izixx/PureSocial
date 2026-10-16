import SwiftUI

/// Vue maîtresse de PureSocial gérant le cycle de vie de l'application :
/// 1. Questionnaire initial (Onboarding Quiz)
/// 2. Écran d'accueil central (Home Hub)
/// 3. Navigation plein écran immersive sans barre parasite
public struct MainView: View {
    @StateObject private var config = ConfigManager.shared
    
    // Plateforme active (si nil, l'utilisateur est sur l'écran d'accueil)
    @State private var activePlatform: SocialPlatform? = nil
    
    // États de contrôle
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
                .zIndex(20)
            } else {
                // 2. Hub d'Accueil principal
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
                .opacity(activePlatform == nil ? 1 : 0)
                .allowsHitTesting(activePlatform == nil && !showingFriction)
                
                // 3. Application immersive active (Plein écran bord à bord)
                if let platform = activePlatform {
                    ImmersiveSocialView(platform: platform, config: config) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activePlatform = nil
                        }
                    }
                    .transition(.opacity)
                    .zIndex(5)
                }
                
                // 4. Écran de pause / friction intentionnelle (In-line ZStack : Zéro bug UIKit modal)
                if showingFriction, let targetPlatform = pendingPlatform {
                    FrictionView(
                        platform: targetPlatform,
                        durationSeconds: config.frictionDurationSeconds,
                        onProceed: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                activePlatform = targetPlatform
                                pendingPlatform = nil
                                showingFriction = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                pendingPlatform = nil
                                showingFriction = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(15)
                }
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
            withAnimation(.easeInOut(duration: 0.25)) {
                showingFriction = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                activePlatform = platform
            }
        }
    }
}
