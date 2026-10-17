import SwiftUI

/// Représente les plateformes de réseaux sociaux prises en charge par PureSocial.
public enum SocialPlatform: String, CaseIterable, Identifiable, Codable {
    case instagram = "Instagram"
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case x = "X (Twitter)"
    
    public var id: String { rawValue }
    
    /// URL initiale de la plateforme
    public var initialURL: URL {
        switch self {
        case .instagram:
            return URL(string: "https://www.instagram.com")!
        case .youtube:
            return URL(string: "https://m.youtube.com")!
        case .tiktok:
            return URL(string: "https://www.tiktok.com/messages")!
        case .x:
            return URL(string: "https://x.com")!
        }
    }
    
    /// Nom de domaine principal pour le filtrage et l'injection
    public var hostKeyword: String {
        switch self {
        case .instagram: return "instagram.com"
        case .youtube:   return "youtube.com"
        case .tiktok:    return "tiktok.com"
        case .x:         return "x.com" // Inclut aussi twitter.com via détection de sous-chaîne
        }
    }
    
    /// Icône SF Symbol associée
    public var sfSymbol: String {
        switch self {
        case .instagram: return "camera.fill"
        case .youtube:   return "play.rectangle.fill"
        case .tiktok:    return "music.note"
        case .x:         return "bubble.left.and.bubble.right.fill"
        }
    }
    
    /// Couleur thématique de l'icône
    public var themeColor: Color {
        switch self {
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42) // Magenta/Pink Instagram
        case .youtube:   return Color(red: 1.0, green: 0.0, blue: 0.0)    // YouTube Red
        case .tiktok:    return Color(red: 0.0, green: 0.95, blue: 0.85)  // TikTok Cyan
        case .x:         return Color.primary
        }
    }
    
    /// Description du mode de restriction actif
    public var modeDescription: String {
        switch self {
        case .instagram:
            return "Mode Essentiel (Stories & DM uniquement, sans Reels ni Explore)"
        case .youtube:
            return "Mode Productif (Sans Shorts, sans fil infini, sans suggestions)"
        case .tiktok:
            return "Mode Messagerie Pure (Accès direct et exclusif aux Messages)"
        case .x:
            return "Mode Suivi (Flux Abonnements uniquement, sans Pour Vous)"
        }
    }
    
    /// User-Agent adapté à chaque plateforme.
    /// TikTok requiert impérativement un User-Agent Desktop (Safari macOS) pour servir
    /// l'application Web de messagerie directe (/messages) et le flux de connexion,
    /// sous peine de renvoyer un code 404 sur sa passerelle mobile (serverless.tiktok.mobile).
    public func effectiveUserAgent(defaultAgent: String) -> String {
        switch self {
        case .tiktok:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        default:
            return defaultAgent.isEmpty ? "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1" : defaultAgent
        }
    }
}
