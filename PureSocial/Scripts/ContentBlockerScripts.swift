import Foundation
import WebKit

/// Fournit les feuilles de style CSS et les scripts JavaScript (MutationObserver)
/// pour bloquer les composants addictifs sur chaque plateforme.
public struct ContentBlockerScripts {
    
    // MARK: - Générateur de CSS Global & Spécifique
    
    /// Génère le bloc CSS complet à injecter au tout début du chargement (.atDocumentStart)
    public static func makeCSS(for platform: SocialPlatform, config: ConfigManager) -> String {
        var rules: [String] = []
        
        // 1. Filtre Niveaux de Gris (Grayscale)
        if config.grayscaleMode {
            rules.append("""
            html, body {
                filter: grayscale(100%) !important;
                -webkit-filter: grayscale(100%) !important;
            }
            """)
        }
        
        // 2. Règles spécifiques à la plateforme
        switch platform {
        case .instagram:
            rules.append(makeInstagramCSS(config: config))
        case .youtube:
            rules.append(makeYouTubeCSS(config: config))
        case .tiktok:
            rules.append(makeTikTokCSS(config: config))
        case .x:
            rules.append(makeXCSS(config: config))
        }
        
        // Style visuel pour les bandeaux d'information PureSocial
        rules.append("""
        .pure-social-banner {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 32px 16px;
            margin: 20px auto;
            max-width: 480px;
            text-align: center;
            background: rgba(128, 128, 128, 0.08);
            border-radius: 16px;
            border: 1px dashed rgba(128, 128, 128, 0.3);
            color: #777777;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            font-size: 14px;
            line-height: 1.5;
            user-select: none;
        }
        .pure-social-banner-title {
            font-weight: 600;
            font-size: 16px;
            margin-bottom: 6px;
            color: #333333;
        }
        @media (prefers-color-scheme: dark) {
            .pure-social-banner-title { color: #f0f0f0; }
            .pure-social-banner { color: #aaaaaa; }
        }
        """)
        
        return rules.joined(separator: "\n\n")
    }
    
    // MARK: - CSS Instagram
    
    private static func makeInstagramCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideInstaReels {
            css.append("""
            /* Masquage de l'icône Reels dans la barre de navigation inférieure et latérale */
            a[href*="/reels/"],
            a[href^="/reels/"],
            svg[aria-label="Reels"],
            svg[aria-label*="Reels"],
            /* Conteneurs de boutons de navigation */
            div[role="navigation"] a:has(svg[aria-label="Reels"]),
            div[role="navigation"] a:has(svg[aria-label*="Reels"]),
            /* Lecteur Reels plein écran */
            div[data-reels-container],
            section:has(video[src*="instagram"]):has(a[href*="/reels/"]) {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
                height: 0 !important;
                overflow: hidden !important;
            }
            """)
        }
        
        if config.hideInstaExplore {
            css.append("""
            /* Masquage de l'onglet Explorer (Recherche & Découverte algorithmique) */
            a[href*="/explore/"],
            a[href^="/explore/"],
            svg[aria-label="Explorer"],
            svg[aria-label="Recherche et exploration"],
            svg[aria-label*="Explore"],
            div[role="navigation"] a:has(svg[aria-label="Explorer"]),
            div[role="navigation"] a:has(svg[aria-label="Recherche et exploration"]),
            div[role="navigation"] a:has(svg[aria-label*="Explore"]),
            /* Grille Explore */
            main[role="main"] div[style*="display: grid"] {
                display: none !important;
            }
            """)
        }
        
        if config.hideInstaMainFeed {
            css.append("""
            /* Masquage strict des publications du fil principal, tout en préservant la barre des Stories */
            main[role="main"] article,
            main article,
            div[role="presentation"] article {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            """)
        }
        
        return css.joined(separator: "\n")
    }
    
    // MARK: - CSS YouTube Mobile
    
    private static func makeYouTubeCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideYTShorts {
            css.append("""
            /* Masquage de l'onglet Shorts dans la barre de navigation (pivot bar) */
            ytm-pivot-bar-item-renderer[tab-content-type="shorts"],
            ytm-pivot-bar-item-renderer:has(div.pivot-shorts),
            ytm-pivot-bar-item-renderer:has(a[href*="/shorts"]),
            a[href*="/shorts"],
            [aria-label*="Shorts"],
            [aria-label*="shorts"],
            
            /* Étagères et sections Shorts dans l'accueil et la recherche */
            ytm-reel-shelf-renderer,
            ytm-rich-section-renderer:has(ytm-reel-shelf-renderer),
            ytm-shorts-lockup-view-model,
            ytm-reel-item-renderer,
            [is-shorts],
            ytm-video-with-context-renderer:has(a[href*="/shorts"]),
            ytm-compact-video-renderer:has(a[href*="/shorts"]) {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                min-height: 0 !important;
                overflow: hidden !important;
                pointer-events: none !important;
            }
            """)
        }
        
        if config.hideYTHomeRecommendations {
            css.append("""
            /* Masquage des flux de recommandations d'accueil sur m.youtube.com */
            ytm-browse[page-type="home"] ytm-section-list-renderer,
            ytm-browse[page-type="home"] ytm-rich-grid-renderer,
            ytm-browse[page-type="home"] #app ytm-item-section-renderer {
                display: none !important;
            }
            """)
        }
        
        if config.hideYTRelatedVideos {
            css.append("""
            /* Masquage des vidéos suggérées sous le lecteur vidéo en cours de lecture */
            ytm-item-section-renderer[section-identifier="related-items"],
            ytm-related-chip-cloud-renderer,
            ytm-single-column-watch-next-results-renderer-contents > ytm-item-section-renderer,
            .related-items,
            #related {
                display: none !important;
            }
            """)
        }
        
        if config.hideYTComments {
            css.append("""
            /* Masquage de la section des commentaires */
            ytm-comments-entry-point-header-renderer,
            ytm-comment-section-renderer,
            #comments,
            .comment-section-renderer {
                display: none !important;
            }
            """)
        }
        
        return css.joined(separator: "\n")
    }
    
    // MARK: - CSS TikTok
    
    private static func makeTikTokCSS(config: ConfigManager) -> String {
        var css: [String] = []
        if config.hideTikTokFYP {
            css.append("""
            /* Masquage du flux For You Page (Pour Toi) algorithmique */
            [data-e2e="recommend-list-item-container"],
            #main-content-homepage_hot,
            div[class*="DivFeedContainer"],
            div[class*="DivThreeColumnContainer"],
            div[data-e2e="feed-for-you"],
            div[class*="DivVideoFeed"] {
                display: none !important;
            }
            """)
        }
        return css.joined(separator: "\n")
    }
    
    // MARK: - CSS X (Twitter)
    
    private static func makeXCSS(config: ConfigManager) -> String {
        var css: [String] = []
        if config.hideXForYouTab {
            css.append("""
            /* Masquage de l'onglet algorithmique 'Pour vous' dans la navigation supérieure */
            nav[aria-label*="Fil d'actualité"] div[role="tablist"] > div[role="presentation"]:first-child,
            nav[aria-label*="Timeline"] div[role="tablist"] > div[role="presentation"]:first-child,
            div[role="tablist"] > div[role="presentation"]:has(a[href="/home"][aria-selected="true"]:not([href*="following"])) {
                /* Cible spécifiquement le premier onglet (Pour vous) */
            }
            """)
        }
        return css.joined(separator: "\n")
    }
    
    // MARK: - Script d'injection CSS au runtime (.atDocumentStart)
    
    /// Crée un script JS qui injecte une balise <style id="pure-social-injected-style">
    public static func makeCSSInjectionScript(cssContent: String) -> String {
        let escapedCSS = cssContent
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        
        return """
        (function() {
            var existing = document.getElementById('pure-social-injected-style');
            if (existing) {
                existing.textContent = `\(escapedCSS)`;
                return;
            }
            var style = document.createElement('style');
            style.id = 'pure-social-injected-style';
            style.textContent = `\(escapedCSS)`;
            (document.head || document.documentElement).appendChild(style);
        })();
        """
    }
    
    // MARK: - Script JS MutationObserver (.atDocumentEnd)
    
    /// Script complet de surveillance dynamique du DOM et de routage SPA
    public static func makeMutationObserverScript(for platform: SocialPlatform, config: ConfigManager) -> String {
        return """
        (function() {
            console.log("[PureSocial] Initialisation du moniteur anti-addiction pour \(platform.rawValue)");
            
            var config = {
                hideInstaReels: \(config.hideInstaReels),
                hideInstaExplore: \(config.hideInstaExplore),
                hideInstaMainFeed: \(config.hideInstaMainFeed),
                hideYTShorts: \(config.hideYTShorts),
                hideYTHomeRecommendations: \(config.hideYTHomeRecommendations),
                hideYTRelatedVideos: \(config.hideYTRelatedVideos),
                hideYTComments: \(config.hideYTComments),
                hideTikTokFYP: \(config.hideTikTokFYP),
                hideXForYouTab: \(config.hideXForYouTab)
            };
            
            var platform = "\(platform.rawValue)";
            var isCleaningScheduled = false;
            
            // Fonction de nettoyage exécutée à chaque frame disponible
            function cleanDOM() {
                isCleaningScheduled = false;
                
                try {
                    if (platform === "Instagram") {
                        cleanInstagram();
                    } else if (platform === "YouTube") {
                        cleanYouTube();
                    } else if (platform === "TikTok") {
                        cleanTikTok();
                    } else if (platform === "X (Twitter)") {
                        cleanX();
                    }
                } catch (e) {
                    console.error("[PureSocial] Erreur lors du nettoyage DOM:", e);
                }
            }
            
            function scheduleClean() {
                if (!isCleaningScheduled) {
                    isCleaningScheduled = true;
                    window.requestAnimationFrame(cleanDOM);
                }
            }
            
            // --- INSTAGRAM CLEANER ---
            function cleanInstagram() {
                // Interception des routes Reels et Explore si l'utilisateur clique dessus
                var path = window.location.pathname;
                if (config.hideInstaReels && (path.startsWith("/reels/") || path.startsWith("/reel/"))) {
                    window.location.replace("/direct/inbox/");
                    return;
                }
                if (config.hideInstaExplore && path.startsWith("/explore/")) {
                    window.location.replace("/");
                    return;
                }
                
                // Masquer les boutons Reels et Explore dans les barres d'onglets
                if (config.hideInstaReels) {
                    document.querySelectorAll('a[href*="/reels/"], svg[aria-label="Reels"]').forEach(function(el) {
                        var navItem = el.closest('div[role="tab"], div[role="listitem"], a');
                        if (navItem) navItem.style.display = 'none';
                    });
                }
                
                if (config.hideInstaExplore) {
                    document.querySelectorAll('a[href*="/explore/"], svg[aria-label="Explorer"], svg[aria-label="Recherche et exploration"]').forEach(function(el) {
                        var navItem = el.closest('div[role="tab"], div[role="listitem"], a');
                        if (navItem) navItem.style.display = 'none';
                    });
                }
                
                // Si le fil d'actualité est masqué, ajouter un message zen au-dessus du néant
                if (config.hideInstaMainFeed && path === "/") {
                    var main = document.querySelector('main[role="main"]');
                    if (main && !document.getElementById('pure-social-insta-banner')) {
                        var banner = document.createElement('div');
                        banner.id = 'pure-social-insta-banner';
                        banner.className = 'pure-social-banner';
                        banner.innerHTML = '<div class="pure-social-banner-title">✨ Mode Essentiel Actif</div><div>Le fil d\\'actualité infini est masqué.<br>Vos Stories et Messages Directs restent 100% accessibles.</div>';
                        main.appendChild(banner);
                    }
                }
            }
            
            // --- YOUTUBE CLEANER ---
            function cleanYouTube() {
                var path = window.location.pathname;
                
                // Rediriger si on tombe sur une URL /shorts/
                if (config.hideYTShorts && path.startsWith("/shorts/")) {
                    // Si on a un identifiant de vidéo shorts, on le convertit en vidéo standard
                    var parts = path.split('/');
                    var videoId = parts[2];
                    if (videoId) {
                        window.location.replace("/watch?v=" + videoId);
                    } else {
                        window.location.replace("/");
                    }
                    return;
                }
                
                // Supprimer les éléments Shorts dans la navigation et les étagères
                if (config.hideYTShorts) {
                    var shortsSelectors = [
                        'ytm-pivot-bar-item-renderer[tab-content-type="shorts"]',
                        'ytm-reel-shelf-renderer',
                        'ytm-shorts-lockup-view-model',
                        'ytm-reel-item-renderer',
                        'ytm-rich-section-renderer:has(ytm-reel-shelf-renderer)'
                    ];
                    document.querySelectorAll(shortsSelectors.join(',')).forEach(function(node) {
                        node.remove();
                    });
                }
                
                // Message zen sur la page d'accueil si les recommandations sont masquées
                if (config.hideYTHomeRecommendations && (path === "/" || path === "")) {
                    var app = document.querySelector('#app') || document.body;
                    if (app && !document.getElementById('pure-social-yt-banner')) {
                        var banner = document.createElement('div');
                        banner.id = 'pure-social-yt-banner';
                        banner.className = 'pure-social-banner';
                        banner.innerHTML = '<div class="pure-social-banner-title">🎯 YouTube Productif</div><div>Les recommandations d\\'accueil sont masquées.<br>Utilisez la loupe en haut pour rechercher une vidéo intentionnelle.</div>';
                        
                        // Insérer après l'en-tête de recherche
                        var header = document.querySelector('ytm-mobile-topbar-renderer') || app.firstChild;
                        if (header && header.parentNode) {
                            header.parentNode.insertBefore(banner, header.nextSibling);
                        } else {
                            app.appendChild(banner);
                        }
                    }
                }
            }
            
            // --- TIKTOK CLEANER ---
            function cleanTikTok() {
                if (config.hideTikTokFYP) {
                    var fypItems = document.querySelectorAll('[data-e2e="recommend-list-item-container"], div#main-content-homepage_hot');
                    fypItems.forEach(function(item) {
                        item.style.display = 'none';
                    });
                    
                    if (!document.getElementById('pure-social-tiktok-banner')) {
                        var main = document.querySelector('main') || document.body;
                        if (main) {
                            var banner = document.createElement('div');
                            banner.id = 'pure-social-tiktok-banner';
                            banner.className = 'pure-social-banner';
                            banner.innerHTML = '<div class="pure-social-banner-title">🛡️ Mode Consultation Pure</div><div>Le flux algorithmique 'Pour Toi' est désactivé.<br>Consultez uniquement vos créateurs suivis ou vos messages.</div>';
                            main.prepend(banner);
                        }
                    }
                }
            }
            
            // --- X (TWITTER) CLEANER ---
            function cleanX() {
                if (config.hideXForYouTab) {
                    // Si le premier onglet est "Pour vous", on clique automatiquement sur "Abonnements" si présent
                    var tabs = document.querySelectorAll('div[role="tablist"] a[role="tab"]');
                    if (tabs.length >= 2) {
                        var firstTab = tabs[0];
                        var secondTab = tabs[1];
                        // Si le premier onglet est sélectionné (Pour vous), basculer vers le second (Abonnements)
                        if (firstTab.getAttribute('aria-selected') === 'true') {
                            secondTab.click();
                        }
                        // Masquer visuellement le premier onglet
                        firstTab.style.display = 'none';
                    }
                }
            }
            
            // Observer les modifications DOM continues (Single Page Applications)
            var observer = new MutationObserver(function(mutations) {
                scheduleClean();
            });
            
            observer.observe(document.documentElement, {
                childList: true,
                subtree: true
            });
            
            // Interception des changements d'URL via pushState / replaceState
            var originalPushState = history.pushState;
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                scheduleClean();
            };
            
            var originalReplaceState = history.replaceState;
            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                scheduleClean();
            };
            
            window.addEventListener('popstate', scheduleClean);
            
            // Premier passage immédiat
            scheduleClean();
        })();
        """
    }
    
    // MARK: - Génération des WKUserScript pour WKWebViewConfiguration
    
    /// Génère la liste des scripts utilisateurs à attacher au contrôleur de contenu
    public static func makeUserScripts(for platform: SocialPlatform, config: ConfigManager) -> [WKUserScript] {
        var scripts: [WKUserScript] = []
        
        // 1. Injection CSS à .atDocumentStart (élimine tout clignotement)
        let css = makeCSS(for: platform, config: config)
        let cssScriptSource = makeCSSInjectionScript(cssContent: css)
        let cssScript = WKUserScript(
            source: cssScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        scripts.append(cssScript)
        
        // 2. Injection MutationObserver à .atDocumentEnd (gère les SPAs dynamiques)
        let jsSource = makeMutationObserverScript(for: platform, config: config)
        let jsScript = WKUserScript(
            source: jsSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        scripts.append(jsScript)
        
        return scripts
    }
}
