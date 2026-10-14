import SwiftUI
import WebKit

/// Vue principale de l'application orchestrant la navigation multi-plateformes,
/// la barre d'outils navigateur, l'écran de friction et l'accès aux réglages.
public struct MainView: View {
    @StateObject private var config = ConfigManager.shared
    
    // Plateforme sélectionnée
    @State private var selectedPlatform: SocialPlatform = .instagram
    
    // Modèles de navigation distincts par plateforme pour préserver l'historique
    @StateObject private var instagramNav = WebViewNavigationModel()
    @StateObject private var youtubeNav = WebViewNavigationModel()
    @StateObject private var tiktokNav = WebViewNavigationModel()
    @StateObject private var xNav = WebViewNavigationModel()
    
    // États d'affichage
    @State private var showingSettings: Bool = false
    @State private var showingFriction: Bool = false
    @State private var pendingPlatform: SocialPlatform? = nil
    
    public init() {}
    
    private var currentNavModel: WebViewNavigationModel {
        switch selectedPlatform {
        case .instagram: return instagramNav
        case .youtube:   return youtubeNav
        case .tiktok:    return tiktokNav
        case .x:         return xNav
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - En-tête supérieur personnalisé (Statut & Contrôles Rapides)
                topControlBar
                
                // Barre de progression fine
                if currentNavModel.isLoading {
                    ProgressView(value: currentNavModel.estimatedProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: selectedPlatform.themeColor))
                        .frame(height: 2)
                } else {
                    Divider()
                }
                
                // MARK: - Conteneur WebViews
                // Utilisation d'un ZStack avec opacité pour maintenir les sessions et états de navigation
                ZStack {
                    SocialWebView(platform: .instagram, config: config, navigationModel: instagramNav)
                        .opacity(selectedPlatform == .instagram ? 1 : 0)
                        .allowsHitTesting(selectedPlatform == .instagram)
                    
                    SocialWebView(platform: .youtube, config: config, navigationModel: youtubeNav)
                        .opacity(selectedPlatform == .youtube ? 1 : 0)
                        .allowsHitTesting(selectedPlatform == .youtube)
                    
                    SocialWebView(platform: .tiktok, config: config, navigationModel: tiktokNav)
                        .opacity(selectedPlatform == .tiktok ? 1 : 0)
                        .allowsHitTesting(selectedPlatform == .tiktok)
                    
                    SocialWebView(platform: .x, config: config, navigationModel: xNav)
                        .opacity(selectedPlatform == .x ? 1 : 0)
                        .allowsHitTesting(selectedPlatform == .x)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // MARK: - Barre de Sélection des Plateformes & Navigation Inférieure
                bottomNavigationBar
            }
        }
        // Affichage de l'écran de friction intentionnelle
        .fullScreenCover(isPresented: $showingFriction) {
            if let targetPlatform = pendingPlatform ?? Optional(selectedPlatform) {
                FrictionView(
                    platform: targetPlatform,
                    durationSeconds: config.frictionDurationSeconds,
                    onProceed: {
                        selectedPlatform = targetPlatform
                        config.lastSelectedPlatform = targetPlatform
                        pendingPlatform = nil
                        showingFriction = false
                    },
                    onCancel: {
                        pendingPlatform = nil
                        showingFriction = false
                    }
                )
            }
        }
        // Panneau des réglages
        .sheet(isPresented: $showingSettings) {
            SettingsView(config: config)
        }
        .onAppear {
            selectedPlatform = config.lastSelectedPlatform
        }
    }
    
    // MARK: - Barre de Contrôle Supérieure
    
    private var topControlBar: some View {
        HStack(spacing: 16) {
            // Bouton Retour
            Button(action: { currentNavModel.goBack() }) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(currentNavModel.canGoBack ? .primary : .secondary.opacity(0.3))
            }
            .disabled(!currentNavModel.canGoBack)
            
            // Bouton Avancer
            Button(action: { currentNavModel.goForward() }) {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(currentNavModel.canGoForward ? .primary : .secondary.opacity(0.3))
            }
            .disabled(!currentNavModel.canGoForward)
            
            // Titre ou URL actuelle
            VStack(spacing: 2) {
                Text(selectedPlatform.rawValue)
                    .font(.system(size: 14, weight: .bold))
                
                Text(selectedPlatform.modeDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            // Bascule rapide Niveaux de Gris (Grayscale)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    config.grayscaleMode.toggle()
                }
            }) {
                Image(systemName: config.grayscaleMode ? "circle.lefthalf.filled" : "circle.dashed")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(config.grayscaleMode ? .primary : .secondary)
            }
            
            // Bouton Rafraîchir
            Button(action: { currentNavModel.reload() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Bouton Réglages
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Barre de Navigation Inférieure
    
    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(SocialPlatform.allCases) { platform in
                Button(action: {
                    handlePlatformSelection(platform)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: platform.sfSymbol)
                            .font(.system(size: 20, weight: selectedPlatform == platform ? .bold : .regular))
                            .foregroundColor(selectedPlatform == platform ? platform.themeColor : .secondary)
                        
                        Text(platform.rawValue)
                            .font(.system(size: 11, weight: selectedPlatform == platform ? .semibold : .regular))
                            .foregroundColor(selectedPlatform == platform ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Gestion de la sélection avec Friction Intentionnelle
    
    private func handlePlatformSelection(_ platform: SocialPlatform) {
        if platform == selectedPlatform {
            // Si on clique sur la plateforme courante, réinitialiser à l'accueil
            currentNavModel.load(url: platform.initialURL)
            return
        }
        
        if config.intentionalFrictionEnabled {
            pendingPlatform = platform
            showingFriction = true
        } else {
            selectedPlatform = platform
            config.lastSelectedPlatform = platform
        }
    }
}
