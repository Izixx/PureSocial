import SwiftUI
import WebKit

/// Panneau complet de réglages des filtres anti-addiction et outils de contrôle du temps d'écran.
public struct SettingsView: View {
    @ObservedObject public var config: ConfigManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingClearCacheAlert = false
    @State private var showingResetAlert = false
    @State private var cacheClearedNotification = false
    
    public init(config: ConfigManager = .shared) {
        self.config = config
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // MARK: - Section Outils Globaux Anti-Dopamine
                Section {
                    Toggle(isOn: $config.grayscaleMode) {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mode Niveaux de Gris")
                                    .fontWeight(.medium)
                                Text("Applique un filtre noir et blanc pour désaturer les stimuli visuels.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $config.intentionalFrictionEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "hourglass")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Friction Intentionnelle")
                                    .fontWeight(.medium)
                                Text("Affiche un compte à rebours et une réflexion avant l'ouverture.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if config.intentionalFrictionEnabled {
                        Picker("Durée de la pause", selection: $config.frictionDurationSeconds) {
                            Text("3 secondes").tag(3)
                            Text("5 secondes (Recommandé)").tag(5)
                            Text("10 secondes").tag(10)
                            Text("15 secondes").tag(15)
                        }
                    }
                } header: {
                    Label("Outils Anti-Dopamine Globaux", systemImage: "brain.head.profile")
                }
                
                // MARK: - Section Instagram
                Section {
                    Toggle(isOn: $config.hideInstaReels) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer les Reels")
                                .fontWeight(.medium)
                            Text("Supprime l'icône Reels et bloque le lecteur de vidéos courtes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideInstaExplore) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer l'onglet Explorer")
                                .fontWeight(.medium)
                            Text("Supprime la grille de recommandations algorithmiques infinies.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideInstaMainFeed) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer le Fil d'Actualité")
                                .fontWeight(.medium)
                            Text("Conserve uniquement la barre des Stories en haut et les Messages Directs (DM).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Instagram (Mode Essentiel)", systemImage: "camera.fill")
                        .foregroundColor(Color(red: 0.88, green: 0.19, blue: 0.42))
                } footer: {
                    Text("Vos messages privés (DM), Stories de vos proches et la recherche directe de profils restent pleinement accessibles.")
                }
                
                // MARK: - Section YouTube
                Section {
                    Toggle(isOn: $config.hideYTShorts) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer les YouTube Shorts")
                                .fontWeight(.medium)
                            Text("Supprime l'onglet Shorts, les étagères d'accueil et les résultats de recherche.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideYTHomeRecommendations) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer l'Accueil (Recommandations)")
                                .fontWeight(.medium)
                            Text("Affiche uniquement la barre de recherche pour un visionnage intentionnel.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideYTRelatedVideos) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer les Vidéos Suggérées")
                                .fontWeight(.medium)
                            Text("Supprime le carrousel de vidéos connexes sous le lecteur.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideYTComments) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer les Commentaires")
                                .fontWeight(.medium)
                            Text("Élimine les débats distrayants sous chaque vidéo.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("YouTube (Mode Productif)", systemImage: "play.rectangle.fill")
                        .foregroundColor(.red)
                }
                
                // MARK: - Section TikTok & X
                Section {
                    Toggle(isOn: $config.hideTikTokFYP) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Masquer 'Pour Toi' sur TikTok")
                                .fontWeight(.medium)
                            Text("Bloque le flux vidéo infini pour restreindre aux recherches ciblées.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $config.hideXForYouTab) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Forcer l'onglet 'Abonnements' sur X")
                                .fontWeight(.medium)
                            Text("Bascule automatiquement et masque le flux 'Pour vous'.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("TikTok & X (Mode Consultation Pure)", systemImage: "shield.lefthalf.filled")
                }
                
                // MARK: - Gestion des Sessions et du Cache
                Section {
                    Button(role: .destructive) {
                        showingClearCacheAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Déconnecter tous les comptes & Vider le cache")
                        }
                    }
                } header: {
                    Text("Sessions & Confidentialité")
                } footer: {
                    Text("PureSocial conserve vos cookies localement dans le stockage sécurisé de votre appareil afin que vous n'ayez pas à vous reconnecter à chaque lancement.")
                }
                
                // MARK: - Réinitialisation
                Section {
                    Button {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Rétablir les réglages stricts par défaut")
                        }
                    }
                }
            }
            .navigationTitle("Réglages PureSocial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            // Alerte de confirmation de vidage de cache
            .alert("Déconnexion & Vidage du cache", isPresented: $showingClearCacheAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    clearWebKitData()
                }
            } message: {
                Text("Cette action supprimera tous les cookies de connexion et l'historique des WebViews. Vous devrez vous reconnecter à vos comptes.")
            }
            // Alerte de réinitialisation
            .alert("Rétablir la configuration par défaut", isPresented: $showingResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Rétablir", role: .destructive) {
                    config.resetToStrictDefaults()
                }
            } message: {
                Text("Tous les filtres anti-addiction seront réactivés au niveau de protection maximal.")
            }
        }
    }
    
    /// Supprime l'ensemble des données WebKit locales
    private func clearWebKitData() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)
        
        dataStore.removeData(ofTypes: types, modifiedSince: dateFrom) {
            DispatchQueue.main.async {
                config.notifyConfigurationChanged()
            }
        }
    }
}
