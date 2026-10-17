import SwiftUI

/// Écran de friction intentionnelle affiché avant d'accéder à un réseau social.
/// Casse la boucle de dopamine réflexe en imposant une pause de réflexion consciente.
public struct FrictionView: View {
    public let platform: SocialPlatform
    public let durationSeconds: Int
    public let onProceed: () -> Void
    public let onCancel: () -> Void
    
    @State private var progress: Double = 0.0
    @State private var secondsRemaining: Int
    @State private var isCompleted: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var startDate: Date = Date()
    @State private var selectedPromptIndex: Int = 0
    
    private let totalTime: Double
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    private let mindfulnessPrompts = [
        "Quelle est ton intention précise en ouvrant cette application ?",
        "Est-ce un choix conscient ou un réflexe d'ennui ?",
        "Prends une inspiration lente et profonde.",
        "De quoi as-tu réellement besoin à cet instant précis ?"
    ]
    
    public init(
        platform: SocialPlatform,
        durationSeconds: Int = 5,
        onProceed: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.platform = platform
        let validDuration = max(1, durationSeconds)
        self.durationSeconds = validDuration
        self.totalTime = Double(validDuration)
        self._secondsRemaining = State(initialValue: validDuration)
        self.onProceed = onProceed
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            // Arrière-plan sombre/système
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Jauge circulaire de réflexion (Se remplit de 0% à 100% de manière fluide)
                ZStack {
                    // Anneau d'arrière-plan discret
                    Circle()
                        .stroke(platform.themeColor.opacity(0.18), lineWidth: 8)
                        .frame(width: 130, height: 130)
                    
                    // Boucle de progression qui se referme progressivement à 100%
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progress))
                        .stroke(
                            platform.themeColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 130, height: 130)
                    
                    VStack(spacing: 4) {
                        Image(systemName: isCompleted ? "checkmark" : platform.sfSymbol)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(platform.themeColor)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                        
                        Text(isCompleted ? "Prêt" : "\(secondsRemaining)s")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .scaleEffect(isCompleted ? 1.06 : (pulseAnimation ? 1.02 : 0.98))
                
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
                    // Bouton 1 : Faire demi-tour (Victoire Focus)
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
                    
                    // Bouton 2 : Continuer (Débloqué UNIQUEMENT lorsque la boucle est à 100% fermée)
                    Button(action: {
                        if isCompleted {
                            onProceed()
                        }
                    }) {
                        Text(isCompleted ? "Continuer vers \(platform.rawValue)" : "Pause de réflexion (\(secondsRemaining)s)...")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isCompleted ? platform.themeColor : Color.secondary.opacity(0.15))
                            .foregroundColor(isCompleted ? (platform == .tiktok ? .black : .white) : .secondary)
                            .cornerRadius(14)
                            .animation(.easeInOut(duration: 0.25), value: isCompleted)
                    }
                    .disabled(!isCompleted)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            startDate = Date()
            progress = 0.0
            secondsRemaining = durationSeconds
            isCompleted = false
            selectedPromptIndex = Int.random(in: 0..<mindfulnessPrompts.count)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onReceive(timer) { _ in
            guard !isCompleted else { return }
            let elapsed = Date().timeIntervalSince(startDate)
            let newProgress = min(1.0, elapsed / totalTime)
            progress = newProgress
            
            let remaining = max(0, Int(ceil(totalTime - elapsed)))
            secondsRemaining = remaining
            
            if elapsed >= totalTime && !isCompleted {
                isCompleted = true
                progress = 1.0
                secondsRemaining = 0
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}
