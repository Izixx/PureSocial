import SwiftUI
import WebKit

/// Modèle d'état pour contrôler la navigation de la WebView depuis SwiftUI
public final class WebViewNavigationModel: ObservableObject {
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var estimatedProgress: Double = 0.0
    @Published public var isLoading: Bool = true
    @Published public var currentTitle: String = ""
    @Published public var currentURL: URL? = nil
    @Published public var hasFinishedInitialLoad: Bool = false
    
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
        
        // Bloque le son automatique sans interaction utilisateur
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        
        // Injection des scripts de blocage
        let userContentController = WKUserContentController()
        let scripts = ContentBlockerScripts.makeUserScripts(for: platform, config: config)
        for script in scripts {
            userContentController.addUserScript(script)
        }
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = config.customUserAgent
        
        // Évite tout clignotement ou écran noir opaque
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        
        // Support plein écran
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
        if webView.customUserAgent != config.customUserAgent {
            webView.customUserAgent = config.customUserAgent
        }
        
        let updatedCSS = ContentBlockerScripts.makeCSS(for: platform, config: config)
        let updateScript = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
        webView.evaluateJavaScript(updateScript, completionHandler: nil)
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
            
            observers.append(webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.isLoading = view.isLoading
                    if !view.isLoading {
                        view.scrollView.refreshControl?.endRefreshing()
                        self?.parent.navigationModel.hasFinishedInitialLoad = true
                    }
                }
            })
            
            observers.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.navigationModel.estimatedProgress = view.estimatedProgress
                }
            })
            
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
            
            // RÈGLE PRIORITAIRE : Ne JAMAIS bloquer ou rediriger les pages d'authentification et de connexion !
            let isAuthFlow = path.contains("/login") ||
                             path.contains("/accounts") ||
                             path.contains("/signup") ||
                             path.contains("/signin") ||
                             path.contains("/auth") ||
                             path.contains("/checkpoint") ||
                             path.contains("/challenge") ||
                             host.contains("accounts.google.com") ||
                             host.contains("appleid.apple.com")
            
            if isAuthFlow {
                decisionHandler(.allow)
                return
            }
            
            // Filtrage ciblé Instagram Reels uniquement (sans toucher à l'écran de Login)
            if host.contains("instagram.com") {
                if parent.config.hideInstaReels && (path.contains("/reels/") || path.hasPrefix("/reel/")) {
                    decisionHandler(.cancel)
                    if let inboxURL = URL(string: "https://www.instagram.com/direct/inbox/") {
                        webView.load(URLRequest(url: inboxURL))
                    }
                    return
                }
            }
            
            // Filtrage ciblé YouTube Shorts -> Conversion en vidéo classique
            if host.contains("youtube.com") {
                if parent.config.hideYTShorts && path.hasPrefix("/shorts/") {
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
            
            // Liens externes ou cibles _blank : maintien dans la même vue
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let updatedCSS = ContentBlockerScripts.makeCSS(for: parent.platform, config: parent.config)
            let script = ContentBlockerScripts.makeCSSInjectionScript(cssContent: updatedCSS)
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.navigationModel.isLoading = false
            print("[PureSocial] Navigation failed: \(error.localizedDescription)")
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.navigationModel.isLoading = false
            print("[PureSocial] Provisional navigation failed: \(error.localizedDescription)")
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
