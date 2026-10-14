import SwiftUI

/// Écran d'accueil central "Espace PureSocial".
/// Remplace la barre d'onglets permanente par un hub épuré où l'utilisateur
/// choisit intentionnellement d'ouvrir un réseau social en plein écran.
public struct HomeHubView: View {
    @ObservedObject public var config: ConfigManager
    public let onSelectPlatform: (SocialPlatform) -> Void
    public let onOpenSettings: () -> Void
    public let onRestartQuiz: () -> Void
    
    public init(
        config: ConfigManager = .shared,
        onSelectPlatform: @escaping (SocialPlatform) -> Void,
        onOpenSettings: @escaping () -> Void,
        onRestartQuiz: @escaping () -> Void
    ) {
        self.config = config
        self.onSelectPlatform = onSelectPlatform
        self.onOpenSettings = onOpenSettings
        self.onRestartQuiz = onRestartQuiz
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - En-tête Supérieur
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESPACE CONSCIENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        
                        Text("PureSocial")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    
                    // Bouton Niveaux de Gris Rapide
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            config.grayscaleMode.toggle()
                        }
                    }) {
                        Image(systemName: config.grayscaleMode ? "circle.lefthalf.filled" : "circle.dashed")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(config.grayscaleMode ? .primary : .secondary)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    
                    // Bouton Réglages
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // MARK: - Bannière Motivation issue du Quiz
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.accentColor)
                        Text("Objectif Actuel")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button(action: onRestartQuiz) {
                            Text("Modifier le quiz")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(config.quizPrimaryGoal)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Temps réinvesti vers : \(config.quizOffScreenActivity)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(18)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(18)
                .padding(.horizontal, 24)
                
                // MARK: - Grille des Réseaux Sociaux Épurés
                VStack(spacing: 16) {
                    ForEach(SocialPlatform.allCases) { platform in
                        platformCard(platform: platform)
                    }
                }
                .padding(.horizontal, 24)
                
                // MARK: - Note de Confidentialité & Sessions
                HStack(spacing: 8) {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(.green)
                    Text("Vos identifiants et cookies sont conservés en local sur votre appareil.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Carte de Réseau Social
    private func platformCard(platform: SocialPlatform) -> some View {
        Button(action: {
            onSelectPlatform(platform)
        }) {
            HStack(spacing: 16) {
                // Icône circulaire colorée
                ZStack {
                    Circle()
                        .fill(platform.themeColor.opacity(0.12))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: platform.sfSymbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(platform.themeColor)
                }
                
                // Textes explicatifs
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(platform.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(platform.modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Tag d'état
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Prêt • Connexion mémorisée")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(18)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
