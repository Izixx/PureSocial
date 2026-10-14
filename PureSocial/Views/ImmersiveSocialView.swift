import SwiftUI

/// Vue plein écran immersive affichant le réseau social sélectionné
/// sans aucune barre de navigation supérieure, reproduisant l'expérience de l'application native.
/// Affiche un écran de transition soigné pendant le chargement initial et fournit
/// une pilule flottante déplaçable pour revenir à l'accueil à tout moment.
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
            // Fond adaptatif clair/sombre pour éviter tout écran noir figé
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // WKWebView pleine page
            SocialWebView(
                platform: platform,
                config: config,
                navigationModel: navModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            
            // Écran de chargement initial gracieux
            if !navModel.hasFinishedInitialLoad {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(platform.themeColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: platform.sfSymbol)
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(platform.themeColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text(platform.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Connexion sécurisée en cours...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: platform.themeColor))
                        .scaleEffect(1.2)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .transition(.opacity)
            }
            
            // Barre de progression discrète en cours de navigation
            if navModel.isLoading && navModel.hasFinishedInitialLoad {
                VStack {
                    ProgressView(value: navModel.estimatedProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: platform.themeColor))
                        .frame(height: 2)
                    Spacer()
                }
                .ignoresSafeArea()
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
