import SwiftUI

/// Écran de friction intentionnelle affiché avant d'accéder à un réseau social.
/// Casse la boucle de dopamine réflexe en imposant une pause de réflexion consciente.
public struct FrictionView: View {
    public let platform: SocialPlatform
    public let onProceed: () -> Void
    public let onCancel: () -> Void
    
    @State private var timeRemaining: Int
    @State private var timerActive: Bool = true
    @State private var pulseAnimation: Bool = false
    
    private let totalTime: Int
    
    public init(
        platform: SocialPlatform,
        durationSeconds: Int = 5,
        onProceed: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.platform = platform
        self.totalTime = max(1, durationSeconds)
        self._timeRemaining = State(initialValue: max(1, durationSeconds))
        self.onProceed = onProceed
        self.onCancel = onCancel
    }
    
    private let mindfulnessPrompts = [
        "Quelle est ton intention précise en ouvrant cette application ?",
        "Est-ce un choix conscient ou un réflexe d'ennui ?",
        "Prends une inspiration lente et profonde.",
        "De quoi as-tu réellement besoin à cet instant précis ?"
    ]
    
    @State private var selectedPromptIndex: Int = 0
    
    public var body: some View {
        ZStack {
            // Arrière-plan doux et apaisant
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icône de la plateforme avec indicateur de pause
                ZStack {
                    Circle()
                        .stroke(platform.themeColor.opacity(0.15), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalTime))
                        .stroke(
                            platform.themeColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 4) {
                        Image(systemName: platform.sfSymbol)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(platform.themeColor)
                        
                        Text("\(timeRemaining)s")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .scaleEffect(pulseAnimation ? 1.04 : 0.96)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                    selectedPromptIndex = Int.random(in: 0..<mindfulnessPrompts.count)
                }
                
                // Message de pleine conscience
                VStack(spacing: 12) {
                    Text("Pause Intentionnelle")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(mindfulnessPrompts[selectedPromptIndex])
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)
                        .frame(minHeight: 60)
                }
                
                Spacer()
                
                // Actions utilisateur
                VStack(spacing: 14) {
                    // Bouton de victoire : Faire demi-tour
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Faire demi-tour (Victoire Focus)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(14)
                    }
                    
                    // Bouton Continuer (Débloqué après expiration du chronomètre)
                    Button(action: {
                        if timeRemaining <= 0 {
                            onProceed()
                        }
                    }) {
                        Text(timeRemaining > 0 ? "Réflexion en cours (\(timeRemaining)s)..." : "Continuer vers \(platform.rawValue)")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(timeRemaining <= 0 ? platform.themeColor : Color.secondary.opacity(0.2))
                            .foregroundColor(timeRemaining <= 0 ? .white : .secondary)
                            .cornerRadius(14)
                    }
                    .disabled(timeRemaining > 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
}
