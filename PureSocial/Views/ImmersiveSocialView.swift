import SwiftUI

/// Vue plein écran immersive affichant le réseau social sélectionné
/// sans aucune barre de navigation supérieure, reproduisant l'expérience de l'application native.
/// Fournit une pilule flottante déplaçable pour revenir à l'accueil à tout moment.
public struct ImmersiveSocialView: View {
    public let platform: SocialPlatform
    @ObservedObject public var config: ConfigManager
    public let onReturnHome: () -> Void
    
    @StateObject private var navModel = WebViewNavigationModel()
    
    // Position du bouton flottant (par défaut en bas à droite)
    @State private var floatingButtonOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    
    public init(
        platform: SocialPlatform,
        config: ConfigManager = .shared,
        onReturnHome: @escaping () -> Void
    ) {
        self.platform = platform
        self.config = config
        self.onReturnHome = onReturnHome
    }
    
    public var body: some View {
        ZStack {
            // Fond adaptatif clair/sombre
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // WKWebView pleine page affichée immédiatement sans aucun écran de masquage
            SocialWebView(
                platform: platform,
                config: config,
                navigationModel: navModel
            )
            .edgesIgnoringSafeArea(.all)
            
            // Barre de progression fine au sommet pendant le chargement
            if navModel.isLoading {
                VStack {
                    ProgressView(value: max(0.05, navModel.estimatedProgress), total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: platform.themeColor))
                        .frame(height: 3)
                    Spacer()
                }
                .ignoresSafeArea()
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
            
            // MARK: - Bouton Flottant Ingénieux "Retour Accueil"
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    floatingControlPill
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
                .padding(.trailing, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Pilule Flottante Déplaçable
    private var floatingControlPill: some View {
        HStack(spacing: 12) {
            // Bouton Retour Accueil PureSocial
            Button(action: onReturnHome) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Accueil")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.primary)
            }
            
            Divider()
                .frame(height: 14)
            
            // Bascule Rapide Niveaux de Gris (Grayscale)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    config.grayscaleMode.toggle()
                }
            }) {
                Image(systemName: config.grayscaleMode ? "circle.lefthalf.filled" : "circle.dashed")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(config.grayscaleMode ? .primary : .secondary)
            }
            
            // Menu d'actions d'appoint (Rafraîchir / Page précédente)
            Menu {
                if navModel.canGoBack {
                    Button(action: { navModel.goBack() }) {
                        Label("Page précédente", systemImage: "chevron.backward")
                    }
                }
                Button(action: { navModel.reload() }) {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
                Button(action: { navModel.load(url: platform.initialURL) }) {
                    Label("Recharger la page d'accueil", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}
