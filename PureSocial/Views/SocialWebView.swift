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
    @Published public var loadError: String? = nil
    
    fileprivate var actionGoBack: (() -> Void)?
    fileprivate var actionGoForward: (() -> Void)?
    fileprivate var actionReload: (() -> Void)?
    fileprivate var actionLoadURL: ((URL) -> Void)?
    fileprivate var actionEvaluateJavaScript: ((String, ((Result<Any, Error>) -> Void)?) -> Void)?
    
    public init() {}
    
    public func goBack() { actionGoBack?() }
    public func goForward() { actionGoForward?() }
    public func reload() {
        loadError = nil
        actionReload?()
    }
    public func load(url: URL) {
        loadError = nil
        actionLoadURL?(url)
    }
    public func evaluateJavaScript(_ script: String, completion: ((Result<Any, Error>) -> Void)? = nil) {
        actionEvaluateJavaScript?(script, completion)
    }
}

/// Wrapper UIViewRepresentable encapsulant WKWebView en plein écran immersif
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
        let configuration = WKWebViewConfiguration()
        
        // PERSISTANCE DES SESSIONS : default() garantit la conservation des cookies et des connexions
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.allowsInlineMediaPlayback = true
        
        // CRITIQUE : Laisser [] pour que les lecteurs vidéo React/HTML5 (Instagram, TikTok)
        // ne crashent pas avec "NotAllowedError", le son étant coupé par script JS (video.muted = true)
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Injection des scripts de blocage
        let userContentController = WKUserContentController()
        let scripts = ContentBlockerScripts.makeUserScripts(for: platform, config: config)
        for script in scripts {
            userContentController.addUserScript(script)
        }
        configuration.userContentController = userContentController
        
        // Initialiser avec la taille de l'écran pour éviter le bug de viewport 0x0
        let frame = UIScreen.main.bounds
        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Si aucun User-Agent personnalisé n'est forcé, utiliser le User-Agent standard Safari
        if !config.customUserAgent.isEmpty {
            webView.customUserAgent = config.customUserAgent
        }
        
        // Fond blanc/système pour éviter tout artefact noir
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        
        // Support plein écran natif
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Pull-to-refresh natif discret
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        context.coordinator.setupKVO(for: webView)
        context.coordinator.bindActions(to: navigationModel, webView: webView)
        
        let request = URLRequest(url: platform.initialURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(request)
        
        return webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        if !config.customUserAgent.isEmpty && webView.customUserAgent != config.customUserAgent {
            webView.customUserAgent = config.customUserAgent
        }
        
        // N'exécute le CSS dynamique que si la page est déjà prête
        if webView.url != nil && !webView.isLoading {
            let updatedCSS = ContentBlockerScripts.makeCSS(for: platform, config: config)
            let updateScript = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
            webView.evaluateJavaScript(updateScript, completionHandler: nil)
        }
    }
    
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
            
            observers.append(webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.isLoading = view.isLoading
                    if !view.isLoading {
                        view.scrollView.refreshControl?.endRefreshing()
                    }
                }
            })
            
            observers.append(webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.estimatedProgress = view.estimatedProgress
                }
            })
            
            observers.append(webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.canGoBack = view.canGoBack
                }
            })
            observers.append(webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.canGoForward = view.canGoForward
                }
            })
            observers.append(webView.observe(\.url, options: [.initial, .new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.currentURL = view.url
                }
            })
            observers.append(webView.observe(\.title, options: [.initial, .new]) { [weak self] view, _ in
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
            model.actionEvaluateJavaScript = { [weak webView] script, completion in
                webView?.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(result as Any))
                    }
                }
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
            let fullURL = url.absoluteString.lowercased()
            
            // FILTRAGE TIKTOK : Restreindre strictement aux messages directs
            if host.contains("tiktok.com") {
                let isLogin = fullURL.contains("login") || fullURL.contains("passport") || fullURL.contains("auth")
                if !isLogin {
                    if path == "/" || path == "/foryou" || path.hasPrefix("/foryou") || path.hasPrefix("/following") || path.hasPrefix("/explore") {
                        decisionHandler(.cancel)
                        if let messagesURL = URL(string: "https://www.tiktok.com/messages") {
                            webView.load(URLRequest(url: messagesURL))
                        }
                        return
                    }
                }
            }
            
            // FILTRAGE STRICTEMENT RÉSERVÉ AUX CLICS EXPLICITES SUR DES LIENS
            // Ne bloque JAMAIS les chargements de pages initiaux, ni les redirections de login !
            if navigationAction.navigationType == .linkActivated {
                // Bloquer les clics utilisateur vers les Reels
                if host.contains("instagram.com") && parent.config.hideInstaReels && (path.contains("/reels/") || path.hasPrefix("/reel/")) {
                    decisionHandler(.cancel)
                    return
                }
                
                // Convertir les clics Shorts en vidéos classiques
                if host.contains("youtube.com") && parent.config.hideYTShorts && path.hasPrefix("/shorts/") {
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
            
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.navigationModel.loadError = nil
            let updatedCSS = ContentBlockerScripts.makeCSS(for: parent.platform, config: parent.config)
            let script = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.navigationModel.isLoading = false
            parent.navigationModel.loadError = error.localizedDescription
            print("[PureSocial] Erreur de navigation : \(error.localizedDescription)")
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.navigationModel.isLoading = false
            parent.navigationModel.loadError = error.localizedDescription
            print("[PureSocial] Erreur de chargement initial : \(error.localizedDescription)")
        }
        
        public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
        
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
