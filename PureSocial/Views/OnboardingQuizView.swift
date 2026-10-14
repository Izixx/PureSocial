import SwiftUI

/// Écran d'accueil et questionnaire initial anti-addiction inspiré des meilleures applications de bien-être numérique.
/// Évalue les habitudes de l'utilisateur et adapte les blocages de l'application en conséquence.
public struct OnboardingQuizView: View {
    @ObservedObject public var config: ConfigManager
    public let onCompleted: () -> Void
    
    @State private var currentStep: Int = 0
    
    // Réponses sélectionnées
    @State private var selectedHours: String = "3h à 5h"
    @State private var selectedGoal: String = "Stopper le doomscrolling"
    @State private var selectedActivity: String = "Sport & Projets"
    
    private let screenTimeOptions = [
        ("Moins de 1h", "Utilisation modérée", "leaf.fill", Color.green),
        ("1h à 3h", "Début de distraction", "hourglass", Color.yellow),
        ("3h à 5h", "Zone critique (Alerte)", "exclamationmark.triangle.fill", Color.orange),
        ("Plus de 5h", "Urgence Dopamine", "flame.fill", Color.red)
    ]
    
    private let goalOptions = [
        ("Stopper le doomscrolling", "Éliminer le défilement infini réflexe", "hand.raised.fill"),
        ("Garder uniquement les messages", "Discuter avec mes amis sans être distrait", "bubble.left.and.bubble.right.fill"),
        ("Supprimer Reels & Shorts", "En finir avec les formats courts ultra-addictifs", "xmark.circle.fill"),
        ("Retrouver ma concentration", "Libérer mon cerveau pour du travail profond", "brain.head.profile")
    ]
    
    private let activityOptions = [
        ("Sport & Remise en forme", "Prendre soin de mon corps et de ma santé", "figure.run"),
        ("Projets personnels & Travail", "Avancer sur mes objectifs concrets", "laptopcomputer"),
        ("Lire des livres & Étudier", "Nourrir mon esprit loin des écrans", "books.vertical.fill"),
        ("Temps réel avec mes proches", "Être 100% présent dans le monde réel", "person.2.fill")
    ]
    
    public init(config: ConfigManager = .shared, onCompleted: @escaping () -> Void) {
        self.config = config
        self.onCompleted = onCompleted
    }
    
    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Barre de progression en haut
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(height: 5)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer(minLength: 10)
                
                // Contenu dynamique selon l'étape
                Group {
                    if currentStep == 0 {
                        hoursStepView
                    } else if currentStep == 1 {
                        goalStepView
                    } else if currentStep == 2 {
                        activityStepView
                    } else {
                        summaryStepView
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
                
                Spacer(minLength: 10)
                
                // Bouton Continuer / Terminer
                Button(action: nextStep) {
                    HStack {
                        Text(currentStep == 3 ? "Entrer dans mon espace" : "Continuer")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Étape 1 : Temps d'écran
    private var hoursStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Bienvenue sur PureSocial")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .textCase(.uppercase)
                
                Text("Combien de temps passes-tu sur les réseaux chaque jour ?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(screenTimeOptions, id: \.0) { option in
                    Button(action: { selectedHours = option.0 }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.2)
                                .font(.title3)
                                .foregroundColor(option.3)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.0)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(option.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedHours == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(selectedHours == option.0 ? Color.accentColor.opacity(0.08) : Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedHours == option.0 ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Étape 2 : Objectif
    private var goalStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Étape 2 / 3")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                
                Text("Quel est ton objectif prioritaire ?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(goalOptions, id: \.0) { option in
                    Button(action: { selectedGoal = option.0 }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.2)
                                .font(.title3)
                                .foregroundColor(.accentColor)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.0)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(option.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedGoal == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(selectedGoal == option.0 ? Color.accentColor.opacity(0.08) : Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedGoal == option.0 ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Étape 3 : Activité de substitution
    private var activityStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Étape 3 / 3")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                
                Text("Que feras-tu du temps libéré ?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(activityOptions, id: \.0) { option in
                    Button(action: { selectedActivity = option.0 }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.2)
                                .font(.title3)
                                .foregroundColor(.accentColor)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.0)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(option.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedActivity == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(selectedActivity == option.0 ? Color.accentColor.opacity(0.08) : Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedActivity == option.0 ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Étape 4 : Bilan Personnalisé
    private var summaryStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("Profil PureSocial Prêt")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Ton application a été configurée sur-mesure pour briser le piège algorithmique.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 14) {
                // Carte impact annuel
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temps estimé récupéré")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("~700 heures / an")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                
                // Carte action
                HStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mission dédiée")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedActivity)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                
                // Carte mode actif
                HStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mode de protection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Reels & Shorts bannis • Audio sous contrôle")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if currentStep < 3 {
                currentStep += 1
            } else {
                config.applyQuizProfile(
                    dailyHours: selectedHours,
                    goal: selectedGoal,
                    activity: selectedActivity
                )
                onCompleted()
            }
        }
    }
}
