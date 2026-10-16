import SwiftUI

/// Vue plein écran immersive affichant le réseau social sélectionné
/// sans aucune barre de navigation supérieure, reproduisant l'expérience de l'application native.
/// Respecte la zone sûre supérieure (Safe Area) pour ne pas masquer les Messages Directs (DM),
/// et fournit un bouton bulle flottant compact déplaçable (AssistiveTouch style) qui ne bloque aucun onglet.
public struct ImmersiveSocialView: View {
    public let platform: SocialPlatform
    @ObservedObject public var config: ConfigManager
    public let isActive: Bool
    public let onReturnHome: () -> Void
    
    @StateObject private var navModel = WebViewNavigationModel()
    
    // Position du bouton bulle flottant (par défaut sur le bord droit au centre vertical)
    @State private var floatingButtonOffset: CGSize = CGSize(width: 0, height: -60)
    @State private var dragOffset: CGSize = .zero
    
    public init(
        platform: SocialPlatform,
        config: ConfigManager = .shared,
        isActive: Bool = true,
        onReturnHome: @escaping () -> Void
    ) {
        self.platform = platform
        self.config = config
        self.isActive = isActive
        self.onReturnHome = onReturnHome
    }
    
    public var body: some View {
        ZStack {
            // Fond adaptatif
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // WKWebView respectant la zone supérieure (Notch / Dynamic Island) pour libérer les Messages (DM)
            // et ignorant uniquement le bas pour une immersion totale
            SocialWebView(
                platform: platform,
                config: config,
                navigationModel: navModel
            )
            .ignoresSafeArea(.all, edges: .bottom)
            
            // Barre de progression fine au sommet pendant le chargement
            if navModel.isLoading {
                VStack {
                    ProgressView(value: max(0.05, navModel.estimatedProgress), total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: platform.themeColor))
                        .frame(height: 3)
                    Spacer()
                }
            }
            
            // Affichage d'un message clair en cas d'erreur réseau
            if let error = navModel.loadError {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Impossible de joindre \(platform.rawValue)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: {
                        navModel.reload()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Réessayer")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(platform.themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 24)
            }
            
            // MARK: - Bouton Bulle Flottant Compact (Style AssistiveTouch)
            // Positionné sur la tranche latérale pour ne jamais masquer les onglets de compte ou messages
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    smartFloatingButton
                        .offset(x: floatingButtonOffset.width + dragOffset.width,
                                y: floatingButtonOffset.height + dragOffset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    floatingButtonOffset.width += value.translation.width
                                    floatingButtonOffset.height += value.translation.height
                                    dragOffset = .zero
                                }
                        )
                }
                .padding(.trailing, 12)
                .padding(.bottom, 120) // Positionné au-dessus de la barre d'onglets inférieure
            }
        }
        .onChange(of: isActive) { active in
            if !active {
                // Pause immédiate de toutes les vidéos et sons dès que l'écran repasse en arrière-plan
                navModel.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(function(el){ el.pause(); });")
            }
        }
    }
    
    // MARK: - Bouton Bulle Compact & Rétractable
    private var smartFloatingButton: some View {
        Menu {
            // Option 1 : Retour Accueil immédiat
            Button(action: {
                navModel.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(function(el){ el.pause(); });")
                onReturnHome()
            }) {
                Label("Accueil PureSocial", systemImage: "house.fill")
            }
            
            // Option 2 : Bascule Niveaux de Gris
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    config.grayscaleMode.toggle()
                }
            }) {
                Label(
                    config.grayscaleMode ? "Désactiver Noir & Blanc" : "Activer Noir & Blanc",
                    systemImage: config.grayscaleMode ? "circle.lefthalf.filled" : "circle.dashed"
                )
            }
            
            // Option 3 : Actualiser
            Button(action: { navModel.reload() }) {
                Label("Actualiser la page", systemImage: "arrow.clockwise")
            }
            
            if navModel.canGoBack {
                Button(action: { navModel.goBack() }) {
                    Label("Page précédente", systemImage: "chevron.backward")
                }
            }
        } label: {
            ZStack {
                Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
        } primaryAction: {
            // Un tap direct coupe le son/média et retourne immédiatement à l'accueil
            navModel.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(function(el){ el.pause(); });")
            onReturnHome()
        }
    }
}
