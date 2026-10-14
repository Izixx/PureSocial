import SwiftUI
import WebKit

/// Modèle d'état pour contrôler la navigation de la WebView depuis SwiftUI
public final class WebViewNavigationModel: ObservableObject {
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var estimatedProgress: Double = 0.0
    @Published public var isLoading: Bool = false
    @Published public var currentTitle: String = ""
    @Published public var currentURL: URL? = nil
    
    // Commandes déclenchées par l'interface utilisateur
    fileprivate var actionGoBack: (() -> Void)?
    fileprivate var actionGoForward: (() -> Void)?
    fileprivate var actionReload: (() -> Void)?
    fileprivate var actionLoadURL: ((URL) -> Void)?
    
    public init() {}
    
    public func goBack() { actionGoBack?() }
    public func goForward() { actionGoForward?() }
    public func reload() { actionReload?() }
    public func load(url: URL) { actionLoadURL?(url) }
}

/// Wrapper UIViewRepresentable encapsulant une instance optimisée de WKWebView
public struct SocialWebView: UIViewRepresentable {
    public let platform: SocialPlatform
    @ObservedObject public var config: ConfigManager
    @ObservedObject public var navigationModel: WebViewNavigationModel
    
    public init(
        platform: SocialPlatform,
        config: ConfigManager = .shared,
        navigationModel: WebViewNavigationModel
    ) {
        self.platform = platform
        self.config = config
        self.navigationModel = navigationModel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        // 1. Configuration du WebKit
        let configuration = WKWebViewConfiguration()
        
        // PERSISTANCE DES SESSIONS : default() garantit la conservation des cookies et tokens
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 2. Injection des scripts initiaux (CSS + JS)
        let userContentController = WKUserContentController()
        let scripts = ContentBlockerScripts.makeUserScripts(for: platform, config: config)
        for script in scripts {
            userContentController.addUserScript(script)
        }
        configuration.userContentController = userContentController
        
        // 3. Création de la WKWebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Gestes de balayage retour / avant natifs iOS
        webView.allowsBackForwardNavigationGestures = true
        
        // User-Agent Spoofing pour éviter le blocage OAuth (Google/YouTube/Instagram)
        webView.customUserAgent = config.customUserAgent
        
        // Pull-to-refresh natif
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        // 4. KVO Observers pour l'état de navigation et la barre de progression
        context.coordinator.setupKVO(for: webView)
        
        // 5. Liaisons d'actions du modèle de navigation
        context.coordinator.bindActions(to: navigationModel, webView: webView)
        
        // 6. Chargement de l'URL initiale
        let request = URLRequest(url: platform.initialURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(request)
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Met à jour le User-Agent si modifié dans les réglages
        if webView.customUserAgent != config.customUserAgent {
            webView.customUserAgent = config.customUserAgent
        }
        
        // Mise à jour dynamique du CSS sans recharger la page
        let updatedCSS = ContentBlockerScripts.makeCSS(for: platform, config: config)
        let updateScript = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
        webView.evaluateJavaScript(updateScript, completionHandler: nil)
    }
    
    // MARK: - Coordinateur (Navigation & KVO)
    
    public final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private var parent: SocialWebView
        private var observers: [NSKeyValueObservation] = []
        private weak var webView: WKWebView?
        
        init(_ parent: SocialWebView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            observers.forEach { $0.invalidate() }
            observers.removeAll()
        }
        
        func setupKVO(for webView: WKWebView) {
            self.webView = webView
            
            // Suivi du chargement
            observers.append(webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.isLoading = view.isLoading
                    if !view.isLoading {
                        view.scrollView.refreshControl?.endRefreshing()
                    }
                }
            })
            
            // Suivi de la progression
            observers.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.estimatedProgress = view.estimatedProgress
                }
            })
            
            // Suivi de l'historique retour / avant
            observers.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.canGoBack = view.canGoBack
                }
            })
            observers.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.canGoForward = view.canGoForward
                }
            })
            
            // Suivi de l'URL et du titre
            observers.append(webView.observe(\.url, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.currentURL = view.url
                }
            })
            observers.append(webView.observe(\.title, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.currentTitle = view.title ?? ""
                }
            })
        }
        
        func bindActions(to model: WebViewNavigationModel, webView: WKWebView) {
            model.actionGoBack = { [weak webView] in
                if webView?.canGoBack == true {
                    webView?.goBack()
                }
            }
            model.actionGoForward = { [weak webView] in
                if webView?.canGoForward == true {
                    webView?.goForward()
                }
            }
            model.actionReload = { [weak webView] in
                webView?.reload()
            }
            model.actionLoadURL = { [weak webView] url in
                let request = URLRequest(url: url)
                webView?.load(request)
            }
        }
        
        @objc func handleRefreshControl(_ sender: UIRefreshControl) {
            webView?.reload()
        }
        
        // MARK: - WKNavigationDelegate
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let host = url.host?.lowercased() ?? ""
            let path = url.path.lowercased()
            
            // 1. Filtrage strict Instagram (Reels & Explore)
            if host.contains("instagram.com") {
                if parent.config.hideInstaReels && (path.contains("/reels/") || path.hasPrefix("/reel/")) {
                    decisionHandler(.cancel)
                    // Redirection douce vers la boîte de réception
                    if let inboxURL = URL(string: "https://www.instagram.com/direct/inbox/") {
                        webView.load(URLRequest(url: inboxURL))
                    }
                    return
                }
                if parent.config.hideInstaExplore && path.hasPrefix("/explore/") {
                    decisionHandler(.cancel)
                    if let homeURL = URL(string: "https://www.instagram.com/") {
                        webView.load(URLRequest(url: homeURL))
                    }
                    return
                }
            }
            
            // 2. Filtrage strict YouTube Shorts
            if host.contains("youtube.com") {
                if parent.config.hideYTShorts && path.hasPrefix("/shorts/") {
                    // Convertir en vidéo classique
                    let videoID = url.lastPathComponent
                    if !videoID.isEmpty && videoID != "shorts" {
                        decisionHandler(.cancel)
                        if let watchURL = URL(string: "https://m.youtube.com/watch?v=\(videoID)") {
                            webView.load(URLRequest(url: watchURL))
                        }
                        return
                    }
                }
            }
            
            // 3. Gestion des liens externes ou cibles _blank : navigation dans la même vue
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Ré-injection de sécurité après le chargement complet
            let updatedCSS = ContentBlockerScripts.makeCSS(for: parent.platform, config: parent.config)
            let script = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        // MARK: - WKUIDelegate (ouverture des fenêtres popups dans la vue principale)
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
