# 🛡️ PureSocial - Anti-Dopamine Social Media for iOS

PureSocial est une application iOS native en Swift / SwiftUI conçue pour éliminer tous les pièges addictifs des réseaux sociaux (Instagram, YouTube, TikTok, X/Twitter) en les encapsulant dans des WebViews ultra-optimisées (`WKWebView`) avec injection dynamique de CSS et de JavaScript (`MutationObserver`).

Conçue spécifiquement pour être compilée et installée via **Sideloadly** ou **AltStore** avec un compte Apple gratuit (sans aucun Entitlement payant tel que FamilyControls / ScreenTime).

---

## 🎯 Fonctionnalités Clés

### 1. Instagram ("Mode Essentiel")
- ✅ **Messages Directs (DM)**, **Stories des suivis** et **Recherche de profils** 100% fonctionnels.
- 🚫 **Masquage strict des Reels** (icône de navigation retirée, lecteur vidéo bloqué et redirigé).
- 🚫 **Masquage de l'onglet Explorer** (suppression du flux de découverte algorithmique).
- 🚫 **Masquage du fil d'actualité infini** (option activée par défaut : seule la barre des Stories reste visible en haut, avec un bandeau zen d'invitation à la déconnexion).

### 2. YouTube ("Mode Productif")
- 🚫 **Élimination complète des YouTube Shorts** (icône dans la barre pivot, étagères d'accueil, résultats de recherche).
- 🚫 **Masquage des recommandations de l'accueil** (seule la barre de recherche reste active pour une utilisation 100% intentionnelle).
- 🚫 **Masquage des vidéos suggérées** sous le lecteur vidéo (fini le rabbit hole sans fin).
- 🚫 **Masquage des commentaires** (pour préserver votre calme mental).

### 3. TikTok & X / Twitter ("Mode Consultation Pure")
- 🚫 **TikTok** : Suppression du flux algorithmique "Pour Toi" (*For You Page*).
- 🚫 **X / Twitter** : Masquage et contournement automatique du flux algorithmique "Pour vous", forçant l'accès au flux "Abonnements" chronologique.

### 4. Outils Anti-Dopamine Globaux
- 🔲 **Mode Niveaux de Gris (Grayscale)** : Filtre CSS instantané (`grayscale(100%)`) commutable en 1 clic depuis la barre d'outils supérieure pour rendre l'interface visuellement neutre.
- ⏳ **Friction Intentionnelle** : Écran de pause avec compte à rebours de 5 secondes (paramétrable) et invite de pleine conscience avant d'ouvrir un réseau. Bouton "Faire demi-tour (Victoire Focus)" pour briser la boucle d'habitude.
- 🔐 **Persistance des sessions** : `WKWebsiteDataStore.default()` conserve vos cookies et sessions entre les lancements.
- 📱 **User-Agent Spoofing** : Empreinte Safari Mobile iOS moderne pour éviter tout blocage OAuth (Google Login / Instagram).

---

## 🏗️ Architecture du Projet

```text
PureSocial/
├── PureSocial.xcodeproj/           # Projet Xcode prêt à l'emploi
│   └── project.pbxproj
├── PureSocial/
│   ├── PureSocialApp.swift         # Point d'entrée de l'application (@main)
│   ├── Info.plist                  # Configuration de bundle (iOS 16+, arm64)
│   ├── Config/
│   │   └── ConfigManager.swift     # Préférences utilisateur (@AppStorage / UserDefaults)
│   ├── Models/
│   │   └── SocialPlatform.swift    # Enum des plateformes gérées
│   ├── Scripts/
│   │   └── ContentBlockerScripts.swift # Injections CSS (.atDocumentStart) & MutationObserver (.atDocumentEnd)
│   └── Views/
│       ├── MainView.swift          # Vue racine, sélecteur multi-plateforme, navigation
│       ├── SocialWebView.swift     # Wrapper WKWebView (UIViewRepresentable, KVO, pull-to-refresh)
│       ├── FrictionView.swift      # Compte à rebours de réflexion anti-réflexe
│       └── SettingsView.swift      # Panneau de réglages des filtres et vidage de cache
├── .github/workflows/
│   └── build-ipa.yml               # Workflow GitHub Actions pour générer le .ipa sans Mac
└── project.yml                     # Définition XcodeGen optionnelle
```

---

## 📦 Compilation & Installation via Sideloadly

### Option A : Si vous êtes sur Windows (Via GitHub Actions gratuit)

Aucun Mac requis ! Vous pouvez utiliser l'infrastructure macOS gratuite de GitHub Actions :

1. Créez un dépôt sur [GitHub](https://github.com) (privé ou public).
2. Poussez ce dossier vers votre dépôt :
   ```bash
   git init
   git add .
   git commit -m "Initial commit PureSocial"
   git branch -M main
   git remote add origin https://github.com/VOTRE_PSEUDO/PureSocial.git
   git push -u origin main
   ```
3. Rendez-vous sur votre dépôt GitHub, dans l'onglet **Actions**.
4. Le workflow **Build Unsigned IPA for Sideloadly** se lance automatiquement (durée : ~1 minute 30).
5. Une fois terminé, cliquez sur l'exécution, puis dans la section **Artifacts**, téléchargez l'archive **`PureSocial-Unsigned-IPA.zip`**.
6. Décompressez le fichier zip pour extraire **`PureSocial.ipa`**.

---

### Option B : Si vous disposez d'un Mac (Via Terminal ou Xcode)

Dans le dossier du projet, exécutez simplement :
```bash
# 1. Compiler l'application pour appareil iOS réel
xcodebuild clean build \
  -project PureSocial.xcodeproj \
  -scheme PureSocial \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

# 2. Créer l'archive IPA
mkdir -p Payload
cp -R build/Build/Products/Release-iphoneos/PureSocial.app Payload/
zip -r PureSocial.ipa Payload
rm -rf Payload build
```

---

### Étape Finale : Installation avec Sideloadly (Windows & Mac)

1. Téléchargez et installez **[Sideloadly](https://sideloadly.io/)** (compatible Windows 10/11 et macOS).
   - *Sur Windows, assurez-vous d'avoir installé iTunes et iCloud (versions web officielles Apple, non issues du Microsoft Store).*
2. Connectez votre iPhone à votre ordinateur en USB (déverrouillez-le et acceptez *"Faire confiance à cet ordinateur"*).
3. Ouvrez **Sideloadly** :
   - Glissez-déposez le fichier **`PureSocial.ipa`** dans la zone dédiée.
   - Saisissez votre **identifiant Apple (Apple ID gratuit)**.
   - Cliquez sur **Start**.
4. Sur votre iPhone :
   - Rendez-vous dans **Réglages** > **Général** > **Gestion des appareils & VPN** > sélectionnez votre compte Apple et appuyez sur **Faire confiance**.
   - *(Sous iOS 16+)* Activez le **Mode Développeur** dans **Réglages** > **Confidentialité et sécurité** > **Mode Développeur**, puis redémarrez votre iPhone.
5. Ouvrez **PureSocial** et profitez de vos réseaux débarrassés de toute toxicité algorithmique !
