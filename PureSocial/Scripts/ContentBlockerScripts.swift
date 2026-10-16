import Foundation
import WebKit

/// Fournit les feuilles de style CSS et les scripts JavaScript (MutationObserver)
/// pour bloquer les composants addictifs (Reels dans le fil, Shorts, vidéos TikTok),
/// neutraliser le son automatique, et forcer le mode Messagerie Pure sur TikTok.
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
        
        // 2. Règles ciblées par plateforme
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
        
        return rules.joined(separator: "\n\n")
    }
    
    // MARK: - CSS Instagram (Suppression des Reels dans le fil, Explore, et bannières)
    
    private static func makeInstagramCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        // Masquage strict de la bannière intrusive "Use the app" / "Utiliser l'application"
        css.append("""
        /* Masquage de la bannière 'Use the app' */
        div[role="dialog"]:has(a[href*="instagram.com/download"]),
        div[style*="fixed"]:has(a[href*="apple.com"]),
        div:has(> a[href*="app.apps.apple.com"]) {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
        }
        """)
        
        if config.hideInstaReels {
            css.append("""
            /* 1. Masquage des publications Reels et Vidéos dans le fil d'actualité */
            article:has(video),
            article:has(a[href*="/reel/"]),
            article:has(a[href*="/reels/"]),
            div[data-tracking-duration-id*="reels"],
            div:has(> a[href*="/reel/"]) {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
                overflow: hidden !important;
            }
            
            /* 2. Masquage de l'icône Reels dans la barre de navigation */
            a[href*="/reels/"],
            a[href^="/reels/"],
            svg[aria-label*="Reels"],
            svg[aria-label*="reels"],
            svg[aria-label*="Clips"] {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
            }
            """)
        }
        
        if config.hideInstaExplore {
            css.append("""
            /* Masquage de l'icône Explorer dans la navigation */
            a[href*="/explore/"],
            a[href^="/explore/"],
            svg[aria-label*="Explorer"],
            svg[aria-label*="explorer"],
            svg[aria-label*="Recherche et exploration"],
            svg[aria-label*="Explore"],
            svg[aria-label*="explore"],
            svg[aria-label*="Recherche"] {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
            }
            """)
        }
        
        if config.hideInstaMainFeed {
            css.append("""
            /* Mode Essentiel : Masquer tous les articles du fil sous les Stories (uniquement quand connecté) */
            body:not(:has(input[type="password"])) main[role="main"] article,
            body:not(:has(input[type="password"])) main article {
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
    
    // MARK: - CSS YouTube Mobile (Supprime les Shorts SANS bloquer l'accueil)
    
    private static func makeYouTubeCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideYTShorts {
            css.append("""
            /* Masquage Shorts dans la barre pivot et étagères */
            ytm-pivot-bar-item-renderer[tab-content-type="shorts"],
            ytm-pivot-bar-item-renderer:has(div.pivot-shorts),
            a[href*="/shorts"],
            [aria-label*="Shorts"],
            [aria-label*="shorts"],
            ytm-reel-shelf-renderer,
            ytm-shorts-lockup-view-model,
            ytm-reel-item-renderer {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                overflow: hidden !important;
                pointer-events: none !important;
            }
            """)
        }
        
        if config.hideYTRelatedVideos {
            css.append("""
            /* Masquage des vidéos suggérées sous le lecteur */
            ytm-item-section-renderer[section-identifier="related-items"],
            ytm-related-chip-cloud-renderer {
                display: none !important;
            }
            """)
        }
        
        if config.hideYTComments {
            css.append("""
            /* Masquage des commentaires */
            ytm-comments-entry-point-header-renderer,
            ytm-comment-section-renderer {
                display: none !important;
            }
            """)
        }
        
        return css.joined(separator: "\n")
    }
    
    // MARK: - CSS TikTok (Mode Messagerie Pure : Masquer tout le flux vidéo)
    
    private static func makeTikTokCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        css.append("""
        /* 1. Masquer tout le flux de vidéos TikTok */
        div[data-e2e="recommend-list-item-container"],
        div[data-e2e="feed-for-you"],
        div[data-e2e="feed-following"],
        div[data-e2e="feed-live"],
        div[class*="DivVideoFeed"],
        div[class*="DivFeedContainer"],
        #main-content-homepage_hot,
        div[data-e2e="user-post-item-list"],
        div:has(> video),
        main > div:has(video),
        div[class*="DivPlayerContainer"],
        div[class*="DivVideoWrapper"],
        div[class*="VideoCard"] {
            display: none !important;
            visibility: hidden !important;
        }

        /* 2. Masquer les onglets et boutons Pour Toi / Suivis / Amis / Live / Créer */
        a[href="/"],
        a[href*="/foryou"],
        a[href*="/following"],
        a[href*="/explore"],
        a[href*="/friends"],
        a[href*="/live"],
        div[data-e2e="nav-foryou"],
        div[data-e2e="nav-following"],
        div[data-e2e="nav-explore"],
        div[data-e2e="nav-friends"],
        div[data-e2e="nav-live"],
        div[data-e2e="nav-upload"],
        div[data-e2e="bottom-nav-foryou"],
        div[data-e2e="bottom-nav-following"],
        div[data-e2e="bottom-nav-home"],
        div[data-e2e="bottom-nav-upload"] {
            display: none !important;
            visibility: hidden !important;
            pointer-events: none !important;
        }
        """)
        
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
            var target = document.head || document.documentElement;
            if (!target) return;
            var id = 'pure-social-injected-style';
            var existing = document.getElementById(id);
            if (existing) {
                existing.textContent = `\(escapedCSS)`;
                return;
            }
            var style = document.createElement('style');
            style.id = id;
            style.textContent = `\(escapedCSS)`;
            target.appendChild(style);
        })();
        """
    }
    
    // MARK: - Script JS MutationObserver & Nettoyage Dynamique (.atDocumentEnd)
    
    public static func makeMutationObserverScript(for platform: SocialPlatform, config: ConfigManager) -> String {
        return """
        (function() {
            // Neutralisation du son automatique des vidéos
            function silenceVideos() {
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
                silenceVideos();
                
                var platform = "\(platform.rawValue)";
                
                // Nettoyage Instagram
                if (platform === "Instagram") {
                    document.querySelectorAll('div, section').forEach(function(el) {
                        if (el.innerText && el.innerText.trim().startsWith('Use the app') && el.children.length < 5) {
                            el.style.display = 'none';
                        }
                    });
                    
                    if (\(config.hideInstaReels)) {
                        document.querySelectorAll('article').forEach(function(article) {
                            if (article.querySelector('video') || article.querySelector('a[href*="/reel/"]') || article.querySelector('a[href*="/reels/"]')) {
                                article.style.display = 'none';
                            }
                        });
                        
                        document.querySelectorAll('a[href*="/reels/"], svg[aria-label*="Reels"], svg[aria-label*="reels"]').forEach(function(el) {
                            var btn = el.closest('a, div[role="tab"], div[role="listitem"]');
                            if (btn) btn.style.display = 'none';
                        });
                    }
                    
                    if (\(config.hideInstaMainFeed) && window.location.pathname === "/") {
                        var isLoginPage = !!document.querySelector('input[type="password"]');
                        if (!isLoginPage) {
                            document.querySelectorAll('article').forEach(function(article) {
                                article.style.display = 'none';
                            });
                        }
                    }
                }
                
                // Nettoyage TikTok (Mode Messagerie Pure)
                if (platform === "TikTok") {
                    var path = window.location.pathname;
                    var full = window.location.href;
                    var isAuth = full.indexOf("login") !== -1 || full.indexOf("passport") !== -1 || full.indexOf("auth") !== -1;
                    
                    // Si on atterrit sur le flux vidéo (/ ou /foryou), forcer la redirection vers /messages (hors page de login)
                    if (!isAuth && !document.querySelector('input[type="password"]')) {
                        if (path === "/" || path === "/foryou" || path === "/following" || path === "/explore" || path.indexOf("/video/") !== -1) {
                            window.location.replace("/messages");
                            return;
                        }
                    }
                    
                    // Masquer tout lecteur vidéo sur TikTok et couper le son
                    document.querySelectorAll('video').forEach(function(v) {
                        v.pause();
                        v.muted = true;
                        var feedItem = v.closest('div[data-e2e="recommend-list-item-container"], div[class*="DivVideoFeed"], div[class*="DivFeedContainer"], div[class*="DivPlayerContainer"]');
                        if (feedItem) feedItem.style.display = 'none';
                    });
                    
                    // Masquer les boutons Pour Toi / Navigation
                    document.querySelectorAll('a[href="/"], a[href*="/foryou"], a[href*="/following"], a[href*="/explore"], div[data-e2e*="foryou"], div[data-e2e*="home"]').forEach(function(el) {
                        el.style.display = 'none';
                    });
                }
                
                // Nettoyage YouTube
                if (platform === "YouTube" && \(config.hideYTShorts)) {
                    document.querySelectorAll('ytm-pivot-bar-item-renderer[tab-content-type="shorts"], ytm-reel-shelf-renderer').forEach(function(el) {
                        el.remove();
                    });
                }
            }
            
            cleanDOM();
            
            var observer = new MutationObserver(function() {
                cleanDOM();
            });
            
            if (document.body) {
                observer.observe(document.body, { childList: true, subtree: true });
            }
        })();
        """
    }
    
    public static func makeUserScripts(for platform: SocialPlatform, config: ConfigManager) -> [WKUserScript] {
        var scripts: [WKUserScript] = []
        
        let css = makeCSS(for: platform, config: config)
        scripts.append(WKUserScript(
            source: makeCSSInjectionScript(cssContent: css),
            injectionTime: .atDocumentEnd,
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
