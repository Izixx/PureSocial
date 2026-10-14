import SwiftUI
import Combine

/// Gestionnaire centralisé des configurations, préférences et résultats du quiz de l'utilisateur.
public final class ConfigManager: ObservableObject {
    public static let shared = ConfigManager()
    
    // MARK: - Clés UserDefaults
    private enum Keys {
        static let hasCompletedOnboarding = "pure_hasCompletedOnboarding"
        static let quizDailyHours = "pure_quizDailyHours"
        static let quizPrimaryGoal = "pure_quizPrimaryGoal"
        static let quizOffScreenActivity = "pure_quizOffScreenActivity"
        
        static let hideInstaReels = "pure_hideInstaReels"
        static let hideInstaExplore = "pure_hideInstaExplore"
        static let hideInstaMainFeed = "pure_hideInstaMainFeed"
        
        static let hideYTShorts = "pure_hideYTShorts"
        static let hideYTHomeRecommendations = "pure_hideYTHomeRecommendations"
        static let hideYTRelatedVideos = "pure_hideYTRelatedVideos"
        static let hideYTComments = "pure_hideYTComments"
        
        static let hideTikTokFYP = "pure_hideTikTokFYP"
        static let hideXForYouTab = "pure_hideXForYouTab"
        
        static let grayscaleMode = "pure_grayscaleMode"
        static let intentionalFrictionEnabled = "pure_intentionalFrictionEnabled"
        static let frictionDurationSeconds = "pure_frictionDurationSeconds"
        static let customUserAgent = "pure_customUserAgent"
        static let lastSelectedPlatform = "pure_lastSelectedPlatform"
    }
    
    // User-Agent standard Safari iOS 17.5 pour iPhone.
    public static let defaultSafariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    
    // MARK: - État Onboarding & Profil Quiz
    @AppStorage(Keys.hasCompletedOnboarding) public var hasCompletedOnboarding: Bool = false {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.quizDailyHours) public var quizDailyHours: String = "3h - 5h" {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.quizPrimaryGoal) public var quizPrimaryGoal: String = "Stopper le doomscrolling" {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.quizOffScreenActivity) public var quizOffScreenActivity: String = "Sport & Projets" {
        didSet { notifyConfigurationChanged() }
    }
    
    // MARK: - Préférences Instagram
    @AppStorage(Keys.hideInstaReels) public var hideInstaReels: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideInstaExplore) public var hideInstaExplore: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideInstaMainFeed) public var hideInstaMainFeed: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    // MARK: - Préférences YouTube
    @AppStorage(Keys.hideYTShorts) public var hideYTShorts: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideYTHomeRecommendations) public var hideYTHomeRecommendations: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideYTRelatedVideos) public var hideYTRelatedVideos: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideYTComments) public var hideYTComments: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    // MARK: - Préférences TikTok & X
    @AppStorage(Keys.hideTikTokFYP) public var hideTikTokFYP: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.hideXForYouTab) public var hideXForYouTab: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    // MARK: - Outils Anti-Dopamine Globaux
    @AppStorage(Keys.grayscaleMode) public var grayscaleMode: Bool = false {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.intentionalFrictionEnabled) public var intentionalFrictionEnabled: Bool = true {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.frictionDurationSeconds) public var frictionDurationSeconds: Int = 5 {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.customUserAgent) public var customUserAgent: String = ConfigManager.defaultSafariUserAgent {
        didSet { notifyConfigurationChanged() }
    }
    
    @AppStorage(Keys.lastSelectedPlatform) public var lastSelectedPlatformRaw: String = SocialPlatform.instagram.rawValue
    
    public var lastSelectedPlatform: SocialPlatform {
        get { SocialPlatform(rawValue: lastSelectedPlatformRaw) ?? .instagram }
        set { lastSelectedPlatformRaw = newValue.rawValue }
    }
    
    @Published public private(set) var configurationRevision: UUID = UUID()
    
    public init() {}
    
    public func notifyConfigurationChanged() {
        configurationRevision = UUID()
        objectWillChange.send()
    }
    
    /// Adapte la configuration de l'application selon les réponses du quiz
    public func applyQuizProfile(dailyHours: String, goal: String, activity: String) {
        self.quizDailyHours = dailyHours
        self.quizPrimaryGoal = goal
        self.quizOffScreenActivity = activity
        self.hasCompletedOnboarding = true
        
        // Configuration stricte si temps d'écran élevé
        if dailyHours.contains("3h") || dailyHours.contains("5h") {
            self.hideInstaReels = true
            self.hideInstaExplore = true
            self.hideInstaMainFeed = true
            self.hideYTShorts = true
            self.hideYTHomeRecommendations = true
            self.hideYTRelatedVideos = true
            self.hideYTComments = true
            self.hideTikTokFYP = true
            self.hideXForYouTab = true
            self.intentionalFrictionEnabled = true
            self.frictionDurationSeconds = 5
        } else {
            // Configuration équilibrée
            self.hideInstaReels = true
            self.hideInstaExplore = true
            self.hideInstaMainFeed = false
            self.hideYTShorts = true
            self.hideYTHomeRecommendations = false
            self.hideYTRelatedVideos = true
            self.intentionalFrictionEnabled = true
            self.frictionDurationSeconds = 3
        }
        
        notifyConfigurationChanged()
    }
    
    public func resetToStrictDefaults() {
        hideInstaReels = true
        hideInstaExplore = true
        hideInstaMainFeed = true
        hideYTShorts = true
        hideYTHomeRecommendations = true
        hideYTRelatedVideos = true
        hideYTComments = true
        hideTikTokFYP = true
        hideXForYouTab = true
        grayscaleMode = false
        intentionalFrictionEnabled = true
        frictionDurationSeconds = 5
        customUserAgent = ConfigManager.defaultSafariUserAgent
        notifyConfigurationChanged()
    }
}
