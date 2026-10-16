import Foundation
import WebKit

/// Fournit les feuilles de style CSS et les scripts JavaScript (MutationObserver)
/// pour bloquer les composants addictifs, neutraliser le son automatique,
/// et garantir que chaque application se charge instantanément sans écran noir.
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
    
    // MARK: - CSS Instagram (Ciblé : supprime Reels et Explore SANS casser la page)
    
    private static func makeInstagramCSS(config: ConfigManager) -> String {
        var css: [String] = []
        
        if config.hideInstaReels {
            css.append("""
            /* Masquage de l'icône Reels dans les barres de navigation */
            a[href*="/reels/"],
            a[href^="/reels/"],
            svg[aria-label*="Reels"],
            svg[aria-label*="reels"] {
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
    
    // MARK: - CSS TikTok
    
    private static func makeTikTokCSS(config: ConfigManager) -> String {
        var css: [String] = []
        if config.hideTikTokFYP {
            css.append("""
            div[data-e2e="recommend-list-item-container"] {
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
    
    // MARK: - Script JS MutationObserver & Neutralisation Audio (.atDocumentEnd)
    
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
            
            silenceVideos();
            
            // Masquage dynamique des icônes Reels / Shorts si ajoutées dynamiquement
            var observer = new MutationObserver(function() {
                silenceVideos();
                
                if ("\(platform.rawValue)" === "YouTube" && \(config.hideYTShorts)) {
                    document.querySelectorAll('ytm-pivot-bar-item-renderer[tab-content-type="shorts"], ytm-reel-shelf-renderer').forEach(function(el) {
                        el.remove();
                    });
                }
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
