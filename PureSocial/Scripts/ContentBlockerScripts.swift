import Foundation
import WebKit

/// Fournit les feuilles de style CSS et les scripts JavaScript (MutationObserver)
/// pour bloquer les composants addictifs, neutraliser le son automatique,
/// et garantir que les formulaires de connexion (Login) s'affichent toujours correctement.
public struct ContentBlockerScripts {
    
    // MARK: - Générateur de CSS Global & Spécifique
    
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
        
        // 2. Règles chirurgicales spécifiques à la plateforme
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
            padding: 24px 16px;
            margin: 16px auto;
            max-width: 440px;
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
            font-size: 15px;
            margin-bottom: 4px;
            color: #333333;
        }
        @media (prefers-color-scheme: dark) {
            .pure-social-banner-title { color: #f0f0f0; }
            .pure-social-banner { color: #aaaaaa; }
        }
        """)
        
        return rules.joined(separator: "\n\n")
    }
    
    // MARK: - CSS Instagram (Préservant absolument l'écran de Login)
    
    private static func makeInstagramCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideInstaReels {
            css.append("""
            /* Masquage de l'icône Reels dans les barres de navigation */
            a[href*="/reels/"],
            a[href^="/reels/"],
            svg[aria-label="Reels"],
            svg[aria-label*="Reels"],
            div[role="navigation"] a:has(svg[aria-label*="Reels"]),
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
            /* Masquage de l'icône Explorer dans la navigation */
            a[href*="/explore/"],
            a[href^="/explore/"],
            svg[aria-label="Explorer"],
            svg[aria-label="Recherche et exploration"],
            svg[aria-label*="Explore"],
            div[role="navigation"] a:has(svg[aria-label*="Explore"]),
            div[role="navigation"] a:has(svg[aria-label*="Recherche"]) {
                display: none !important;
            }
            """)
        }
        
        if config.hideInstaMainFeed {
            css.append("""
            /* Ne masque JAMAIS si la page contient un formulaire de connexion ou si non connecté */
            body:not(:has(form#loginForm)):not(:has(input[name="username"])) main[role="main"] > section > div > div > div:not(:first-child) article,
            body:not(:has(form#loginForm)):not(:has(input[name="username"])) main[role="main"] > div > div > article {
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
    
    // MARK: - CSS YouTube Mobile (Préservant la barre de recherche et les boutons de connexion)
    
    private static func makeYouTubeCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideYTShorts {
            css.append("""
            /* Masquage de l'onglet Shorts dans la barre pivot inférieure */
            ytm-pivot-bar-item-renderer[tab-content-type="shorts"],
            ytm-pivot-bar-item-renderer:has(div.pivot-shorts),
            ytm-pivot-bar-item-renderer:has(a[href*="/shorts"]),
            a[href*="/shorts"],
            [aria-label*="Shorts"],
            [aria-label*="shorts"],
            
            /* Étagères Shorts dans les recherches et l'accueil */
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
            /* Masque uniquement le contenu vidéo de l'accueil, en laissant visible le header et la loupe */
            ytm-browse[page-type="home"] ytm-section-list-renderer .item-section-renderer-contents,
            ytm-browse[page-type="home"] ytm-rich-grid-renderer {
                display: none !important;
            }
            """)
        }
        
        if config.hideYTRelatedVideos {
            css.append("""
            /* Masquage des vidéos suggérées sous le lecteur */
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
            /* Masquage des commentaires */
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
    
    // MARK: - CSS TikTok (Ciblé sans masquer le conteneur principal)
    
    private static func makeTikTokCSS(config: ConfigManager) -> String {
        var css: [String] = []
        if config.hideTikTokFYP {
            css.append("""
            /* Masquage ciblé des éléments de vidéos recommandées */
            div[data-e2e="recommend-list-item-container"],
            div[data-e2e="feed-for-you"] > div:not(:first-child) {
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
            nav[aria-label*="Fil d'actualité"] div[role="tablist"] > div[role="presentation"]:first-child,
            nav[aria-label*="Timeline"] div[role="tablist"] > div[role="presentation"]:first-child {
                display: none !important;
            }
            """)
        }
        return css.joined(separator: "\n")
    }
    
    // MARK: - Script d'injection CSS sécurisé
    
    public static func makeCSSInjectionScript(cssContent: String) -> String {
        let escapedCSS = cssContent
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        
        return """
        (function() {
            function applyStyle() {
                var target = document.head || document.documentElement;
                if (!target) {
                    if (document.readyState === 'loading') {
                        document.addEventListener('DOMContentLoaded', applyStyle);
                    } else {
                        setTimeout(applyStyle, 10);
                    }
                    return;
                }
                var existing = document.getElementById('pure-social-injected-style');
                if (existing) {
                    existing.textContent = `\(escapedCSS)`;
                    return;
                }
                var style = document.createElement('style');
                style.id = 'pure-social-injected-style';
                style.textContent = `\(escapedCSS)`;
                target.appendChild(style);
            }
            applyStyle();
        })();
        """
    }
    
    // MARK: - Script JS MutationObserver & Neutralisation Audio (.atDocumentEnd)
    
    public static func makeMutationObserverScript(for platform: SocialPlatform, config: ConfigManager) -> String {
        return """
        (function() {
            console.log("[PureSocial] Initialisation pour \(platform.rawValue)");
            
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
            
            // Neutralisation du son automatique des vidéos
            function silenceAllVideos() {
                var videos = document.querySelectorAll('video');
                videos.forEach(function(video) {
                    video.muted = true;
                    video.volume = 0;
                    video.setAttribute('muted', 'true');
                    video.setAttribute('playsinline', 'true');
                });
            }
            
            document.addEventListener('play', function(e) {
                if (e.target && e.target.tagName === 'VIDEO') {
                    e.target.muted = true;
                }
            }, true);
            
            function cleanDOM() {
                isCleaningScheduled = false;
                silenceAllVideos();
                
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
                    console.error("[PureSocial] Erreur DOM:", e);
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
                var path = window.location.pathname;
                
                // Si l'utilisateur est sur la page de connexion, on ne touche à RIEN !
                if (path.includes("/accounts/") || document.querySelector('form#loginForm') || document.querySelector('input[name="username"]')) {
                    return;
                }
                
                // Masquer les boutons Reels et Explore dans les barres de navigation
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
                
                // Bandeau zen si le fil infini est masqué
                if (config.hideInstaMainFeed && path === "/") {
                    var main = document.querySelector('main[role="main"]');
                    if (main && !document.getElementById('pure-social-insta-banner')) {
                        var banner = document.createElement('div');
                        banner.id = 'pure-social-insta-banner';
                        banner.className = 'pure-social-banner';
                        banner.innerHTML = '<div class="pure-social-banner-title">✨ Mode Essentiel Actif</div><div>Le fil infini est masqué pour préserver ton attention.<br>Tes Stories et Messages Directs restent 100% accessibles.</div>';
                        main.appendChild(banner);
                    }
                }
            }
            
            // --- YOUTUBE CLEANER ---
            function cleanYouTube() {
                var path = window.location.pathname;
                
                if (config.hideYTShorts && path.startsWith("/shorts/")) {
                    var parts = path.split('/');
                    var videoId = parts[2];
                    if (videoId) {
                        window.location.replace("/watch?v=" + videoId);
                    } else {
                        window.location.replace("/");
                    }
                    return;
                }
                
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
                
                if (config.hideYTHomeRecommendations && (path === "/" || path === "")) {
                    var app = document.querySelector('ytm-browse[page-type="home"]') || document.body;
                    if (app && !document.getElementById('pure-social-yt-banner')) {
                        var banner = document.createElement('div');
                        banner.id = 'pure-social-yt-banner';
                        banner.className = 'pure-social-banner';
                        banner.innerHTML = '<div class="pure-social-banner-title">🎯 YouTube Intentionnel</div><div>Les recommandations d\\'accueil sont masquées.<br>Utilise la loupe de recherche ci-dessus pour chercher ta vidéo.</div>';
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
                    var fypItems = document.querySelectorAll('div[data-e2e="recommend-list-item-container"]');
                    fypItems.forEach(function(item) { item.style.display = 'none'; });
                }
            }
            
            // --- X CLEANER ---
            function cleanX() {
                if (config.hideXForYouTab) {
                    var tabs = document.querySelectorAll('div[role="tablist"] a[role="tab"]');
                    if (tabs.length >= 2) {
                        var firstTab = tabs[0];
                        var secondTab = tabs[1];
                        if (firstTab.getAttribute('aria-selected') === 'true') {
                            secondTab.click();
                        }
                        firstTab.style.display = 'none';
                    }
                }
            }
            
            var targetRoot = document.documentElement || document.body;
            if (targetRoot) {
                var observer = new MutationObserver(function() { scheduleClean(); });
                observer.observe(targetRoot, { childList: true, subtree: true });
            }
            
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
            scheduleClean();
        })();
        """
    }
    
    public static func makeUserScripts(for platform: SocialPlatform, config: ConfigManager) -> [WKUserScript] {
        var scripts: [WKUserScript] = []
        
        let css = makeCSS(for: platform, config: config)
        scripts.append(WKUserScript(
            source: makeCSSInjectionScript(cssContent: css),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))
        
        scripts.append(WKUserScript(
            source: makeMutationObserverScript(for: platform, config: config),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        ))
        
        return scripts
    }
}
