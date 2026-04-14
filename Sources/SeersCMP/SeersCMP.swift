import Foundation
import UIKit

// MARK: - Models

public struct SeersConsent: Codable {
    public let sdkKey: String
    public let value: String
    public let necessary: Bool
    public let preferences: Bool
    public let statistics: Bool
    public let marketing: Bool
    public let timestamp: String
    public let expiry: String
    enum CodingKeys: String, CodingKey {
        case sdkKey = "sdk_key"
        case value, necessary, preferences, statistics, marketing, timestamp, expiry
    }
}

public struct SeersConsentMap {
    public let statistics:   SeersCategory
    public let marketing:    SeersCategory
    public let preferences:  SeersCategory
    public let unclassified: SeersCategory
}

public struct SeersCategory {
    public let allowed: Bool
    public let sdks: [String]
}

public struct SeersBlockResult {
    public let blocked: Bool
    public let category: String?
}

// MARK: - SeersCMP

public final class SeersCMP {

    public static func initialize(
        settingsId: String,
        onShowBanner: ((SeersBannerPayload) -> Void)? = nil,
        onConsent: ((SeersConsent, SeersConsentMap) -> Void)? = nil,
        onConsentRestored: ((SeersConsent, SeersConsentMap) -> Void)? = nil
    ) {
        shared.settingsId       = settingsId
        shared.onShowBanner     = onShowBanner
        shared.onConsent        = onConsent
        shared.onConsentRestored = onConsentRestored
        shared.start()
    }

    public static func shouldBlock(_ identifier: String) -> Bool { shared.checkShouldBlock(identifier).blocked }

    /// Regulation type derived from region API response.
    public static var regulation: String { shared._lastPayload?.regulation ?? "gdpr" }
    public static var isGdpr: Bool { regulation == "gdpr" }
    public static var isCcpa: Bool { regulation == "ccpa" }
    public static var isNone: Bool { regulation == "none" }

    /// Call BEFORE initialising any third-party SDK.
    /// GDPR (region_selection 1|3) → pre-block until consent given.
    /// CCPA (region_selection 2)   → NOT pre-blocked; block only after explicit opt-out.
    /// none (region_selection 0)   → never block.
    ///
    ///     SeersCMP.shouldBlockNow("com.google.firebase.analytics") { blocked in
    ///         if !blocked { FirebaseApp.configure() }
    ///     }
    public static func shouldBlockNow(_ identifier: String, completion: @escaping (Bool) -> Void) {
        if isNone { completion(false); return }

        let stored = shared.loadStoredConsent(sdkKey: shared.settingsId ?? "")

        if let consent = stored, !shared.isExpired(consent) {
            completion(shared.checkBlockWithConsent(identifier, consent: consent))
            return
        }

        // No consent yet:
        if isGdpr {
            // GDPR → pre-block everything in block list
            completion(shared.checkShouldBlock(identifier).blocked)
        } else {
            // CCPA → don't pre-block
            completion(false)
        }
    }
    public static func getConsentMap() -> SeersConsentMap { shared.buildConsentMap() }
    public static func getConsent() -> SeersConsent? { guard let id = shared.settingsId else { return nil }; return shared.loadStoredConsent(sdkKey: id) }
    public static func saveConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool) {
        shared.persistConsent(value: value, preferences: preferences, statistics: statistics, marketing: marketing)
    }

    /// Set your app's bundle ID for security verification
    public static var appId: String?
    /// Last banner payload fetched from CDN
    public static var lastPayload: SeersBannerPayload? { shared._lastPayload }

    static let shared = SeersCMP()
    private init() {}

    var settingsId: String?
    var config: SeersCMPConfig?
    var _lastPayload: SeersBannerPayload?
    var onShowBanner: ((SeersBannerPayload) -> Void)?
    var onConsent: ((SeersConsent, SeersConsentMap) -> Void)?
    var onConsentRestored: ((SeersConsent, SeersConsentMap) -> Void)?

    private func start() {
        guard let key = settingsId else { return }
        if let stored = loadStoredConsent(sdkKey: key), !isExpired(stored) {
            let map = buildConsentMap()
            onConsentRestored?(stored, map)
            return
        }
        // Cache-busting: changes every minute
        let ts = Int(Date().timeIntervalSince1970) / 60
        fetchConfig(sdkKey: key, ts: ts) { [weak self] config in
            guard let self = self, let config = config, config.eligible else { return }
            self.config = config

            // App identity verification
            if let appId = SeersCMP.appId {
                let registered = config.bundleId ?? config.packageName
                if let reg = registered, !appId.lowercased().elementsEqual(reg.lowercased()) { return }
            }

            self.checkRegion(sdkKey: key) { region in
                guard self.shouldShow(dialogue: config.dialogue, region: region) else { return }
                let lang = self.resolveLanguage(config: config, region: region)
                let payload = SeersBannerPayload(
                    dialogue: config.dialogue, banner: config.banner, language: lang,
                    categories: config.categories, blockList: self.buildBlockList(config: config),
                    regulation: region?.regulation, sdkKey: key
                )
                self._lastPayload = payload
                DispatchQueue.main.async {
                    if let cb = self.onShowBanner {
                        cb(payload)
                    } else {
                        self.autoShowBanner(payload)
                    }
                }
            }
        }
    }

    private func autoShowBanner(_ payload: SeersBannerPayload) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        let bannerVC = SeersBannerViewController(payload: payload) {
            // dismiss
        }
        bannerVC.modalPresentationStyle = .overFullScreen
        bannerVC.modalTransitionStyle = .coverVertical
        window.rootViewController?.present(bannerVC, animated: true)
    }

    private func fetchConfig(sdkKey: String, ts: Int, completion: @escaping (SeersCMPConfig?) -> Void) {
        let urlStr = "https://cdn.consents.dev/mobile/configs/\(sdkKey).json?v=\(ts)"
        guard let url = URL(string: urlStr) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                completion(SeersCMPConfig(eligible: false))
                return
            }
            guard let data = data,
                  let config = try? JSONDecoder().decode(SeersCMPConfig.self, from: data) else {
                completion(nil); return
            }
            completion(config)
        }.resume()
    }

    private func checkRegion(sdkKey: String, completion: @escaping (SeersRegion?) -> Void) {
        let host = config?.cxHost ?? ""
        guard !host.isEmpty, let url = URL(string: "\(host)/api/mobile/sdk/\(sdkKey)") else {
            completion(nil); return
        }
        var req = URLRequest(url: url)
        if let appId = SeersCMP.appId { req.setValue(appId, forHTTPHeaderField: "X-App-ID") }
        URLSession.shared.dataTask(with: req) { data, _, _ in
            let region = data.flatMap { try? JSONDecoder().decode(SeersRegion.self, from: $0) }
            completion(region)
        }.resume()
    }

    func buildBlockList(config: SeersCMPConfig? = nil) -> SeersBlockList {
        let cfg = config ?? self.config
        guard let cfg = cfg else { return SeersBlockList() }
        var list = SeersBlockList()
        let catMap: [Int: String] = [3: "statistics", 4: "marketing", 5: "preferences", 6: "unclassified"]
        for item in cfg.blockingDomains {
            let identifier = cfg.blockingMode == "prior_consent" ? item.d : item.src
            let catId      = cfg.blockingMode == "prior_consent" ? item.c : item.category
            guard let id = identifier, let cid = catId, let cat = catMap[cid] else { continue }
            switch cat {
            case "statistics":   list.statistics.append(id)
            case "marketing":    list.marketing.append(id)
            case "preferences":  list.preferences.append(id)
            default:             list.unclassified.append(id)
            }
        }
        return list
    }

    func checkShouldBlock(_ identifier: String) -> SeersBlockResult {
        guard let key = settingsId else { return SeersBlockResult(blocked: false, category: nil) }
        let consent = loadStoredConsent(sdkKey: key)
        let blockList = buildBlockList()
        let id = identifier.lowercased()
        let categories: [(String, [String])] = [
            ("statistics", blockList.statistics), ("marketing", blockList.marketing),
            ("preferences", blockList.preferences), ("unclassified", blockList.unclassified)
        ]
        for (cat, sdks) in categories {
            for sdk in sdks where id.contains(sdk.lowercased()) {
                let allowed: Bool
                switch cat {
                case "statistics":  allowed = consent?.statistics  ?? false
                case "marketing":   allowed = consent?.marketing   ?? false
                case "preferences": allowed = consent?.preferences ?? false
                default:            allowed = false
                }
                return SeersBlockResult(blocked: !allowed, category: cat)
            }
        }
        return SeersBlockResult(blocked: false, category: nil)
    }

    func buildConsentMap() -> SeersConsentMap {
        guard let key = settingsId else {
            return SeersConsentMap(statistics: SeersCategory(allowed: false, sdks: []),
                marketing: SeersCategory(allowed: false, sdks: []),
                preferences: SeersCategory(allowed: false, sdks: []),
                unclassified: SeersCategory(allowed: false, sdks: []))
        }
        let consent = loadStoredConsent(sdkKey: key)
        let blockList = buildBlockList()
        return SeersConsentMap(
            statistics:   SeersCategory(allowed: consent?.statistics  ?? false, sdks: blockList.statistics),
            marketing:    SeersCategory(allowed: consent?.marketing   ?? false, sdks: blockList.marketing),
            preferences:  SeersCategory(allowed: consent?.preferences ?? false, sdks: blockList.preferences),
            unclassified: SeersCategory(allowed: false,                          sdks: blockList.unclassified)
        )
    }

    func persistConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool) {
        guard let key = settingsId else { return }
        let expiry = Calendar.current.date(byAdding: .day, value: config?.dialogue?.agreementExpire ?? 365, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let consent = SeersConsent(sdkKey: key, value: value, necessary: true,
            preferences: preferences, statistics: statistics, marketing: marketing,
            timestamp: formatter.string(from: Date()), expiry: formatter.string(from: expiry))
        if let data = try? JSONEncoder().encode(consent) {
            UserDefaults.standard.set(data, forKey: "SeersConsent_\(key)")
        }
        logConsent(sdkKey: key, consent: consent)
        let map = buildConsentMap()
        onConsent?(consent, map)
    }

    func loadStoredConsent(sdkKey: String) -> SeersConsent? {
        guard let data = UserDefaults.standard.data(forKey: "SeersConsent_\(sdkKey)") else { return nil }
        return try? JSONDecoder().decode(SeersConsent.self, from: data)
    }

    func isExpired(_ consent: SeersConsent) -> Bool {
        let formatter = ISO8601DateFormatter()
        guard let expiry = formatter.date(from: consent.expiry) else { return true }
        return Date() > expiry
    }

    private func logConsent(sdkKey: String, consent: SeersConsent) {
        let host = config?.cxHost ?? ""
        guard !host.isEmpty, let url = URL(string: "\(host)/api/mobile/sdk/save-consent") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "sdk_key":    sdkKey,
            "platform":   config?.platform ?? "ios",
            "consent":    consent.value,
            "categories": [
                "necessary":   consent.necessary,
                "preferences": consent.preferences,
                "statistics":  consent.statistics,
                "marketing":   consent.marketing,
            ],
            "timestamp":  consent.timestamp,
        ]
        if let v = SeersCMP.appVersion { body["app_version"] = v }
        if let e = SeersCMP.userEmail  { body["email"]       = e }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    /// Optional: set app version for consent log enrichment.
    ///   SeersCMP.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    public static var appVersion: String?

    /// Optional: set user email for consent log enrichment.
    ///   SeersCMP.userEmail = "user@example.com"
    public static var userEmail: String?

    func checkBlockWithConsent(_ identifier: String, consent: SeersConsent) -> Bool {
        let result = checkShouldBlock(identifier)
        guard result.blocked, let cat = result.category else { return false }
        switch cat {
        case "statistics":  return !consent.statistics
        case "marketing":   return !consent.marketing
        case "preferences": return !consent.preferences
        default:            return false
        }
    }

    private func shouldShow(dialogue: SeersCMPDialogue?, region: SeersRegion?) -> Bool {
        guard let d = dialogue else { return false }
        // region_selection=0 → never show banner
        if d.regionSelection == 0 { return false }
        if d.regionDetection { return region?.eligible == true && region?.regulation != "none" }
        return true
    }

    private func resolveLanguage(config: SeersCMPConfig, region: SeersRegion?) -> SeersCMPLanguage? {
        if let lang = config.language { return lang }
        let code = region?.data?.countryIsoCode ?? config.dialogue?.defaultLanguage ?? "GB"
        return config.languages?.first(where: { $0.countryCode == code }) ?? config.languages?.first
    }
}

// MARK: - Banner ViewController (auto-show)

public class SeersBannerViewController: UIViewController {

    private let payload:   SeersBannerPayload
    private let onDismiss: () -> Void

    /// Set to true before presenting to skip directly to the preferences panel.
    var isShowingPreferences: Bool = false

    // ── Preference toggle state (preferences starts ON — matches Flutter) ──
    private var prefOn = true
    private var statOn = false
    private var mktOn  = false
    private var expandedKeys = Set<String>()

    // ── Keep refs for toggle/arrow updates without full rebuild ──
    private var toggleSwitches = [String: UISwitch]()
    private var arrowLabels    = [String: UILabel]()
    private var descContainers = [String: UIView]()
    private var catStacks      = [String: UIStackView]()

    public init(payload: SeersBannerPayload, onDismiss: @escaping () -> Void) {
        self.payload   = payload
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        if isShowingPreferences { setupPreferences() } else { setupBanner() }
    }

    // MARK: - Theme helpers (shared by both views)

    private var themeColors: (bg: UIColor, body: UIColor, agree: UIColor, agreeText: UIColor,
                               decline: UIColor, declineText: UIColor, pref: UIColor) {
        let b = payload.banner
        return (
            bg:          color(b?.bannerBgColor    ?? "#ffffff"),
            body:        color(b?.bodyTextColor    ?? "#1a1a1a"),
            agree:       color(b?.agreeBtnColor    ?? "#3b6ef8"),
            agreeText:   color(b?.agreeTextColor   ?? "#ffffff"),
            decline:     color(b?.disagreeBtnColor ?? "#1a1a2e"),
            declineText: color(b?.disagreeTextColor ?? "#ffffff"),
            // prefFullStyle uses body_text_color — matches Flutter _prefClr => _bodyClr
            pref:        color(b?.bodyTextColor    ?? "#1a1a1a")
        )
    }

    private var fs: CGFloat      { CGFloat(Float(payload.banner?.fontSize ?? "14") ?? 14) }
    private var titleFs: CGFloat { fs + 2 }
    private var btnRadius: CGFloat {
        let t = payload.banner?.buttonType ?? "default"
        return t.contains("rounded") ? 20 : t.contains("flat") ? 0 : 4
    }
    private var isStroke: Bool { (payload.banner?.buttonType ?? "").contains("stroke") }

    // MARK: - Banner panel

    private func setupBanner() {
        let c   = themeColors
        let l   = payload.language
        let d   = payload.dialogue

        let allowReject = d?.allowReject ?? true
        let poweredBy   = d?.poweredBy   ?? true
        let bodyText    = l?.body               ?? "We use cookies to personalize content and ads."
        let btnAgree    = l?.btnAgreeTitle      ?? "Allow All"
        let btnDecline  = l?.btnDisagreeTitle   ?? "Disable All"
        let btnPref     = l?.btnPreferenceTitle ?? "Cookie settings"

        // Container — rounded top corners
        let container = UIView()
        container.backgroundColor = c.bg
        container.layer.cornerRadius = 12
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Body
        let bodyLabel = makeLabel(bodyText, size: fs, color: c.body, alpha: 0.9, lines: 0)
        stack.addArrangedSubview(bodyLabel)

        // Allow All
        let agreeBg = isStroke ? UIColor.clear : c.agree
        let agreeFg = isStroke ? c.agree       : c.agreeText
        stack.addArrangedSubview(makeBtn(btnAgree, bg: agreeBg, fg: agreeFg, outline: isStroke) { [weak self] in
            SeersCMP.saveConsent(value: "agree", preferences: true, statistics: true, marketing: true)
            self?.dismiss(animated: true) { self?.onDismiss() }
        })

        // Decline
        if allowReject {
            stack.addArrangedSubview(makeBtn(btnDecline, bg: c.decline, fg: c.declineText) { [weak self] in
                SeersCMP.saveConsent(value: "disagree", preferences: false, statistics: false, marketing: false)
                self?.dismiss(animated: true) { self?.onDismiss() }
            })
        }

        // Cookie settings — opens preferences
        stack.addArrangedSubview(makeBtn(btnPref, bg: .clear, fg: c.pref, outline: true) { [weak self] in
            guard let self = self else { return }
            let prefVC = SeersBannerViewController(payload: self.payload, onDismiss: self.onDismiss)
            prefVC.isShowingPreferences = true
            prefVC.modalPresentationStyle = .overFullScreen
            prefVC.modalTransitionStyle   = .coverVertical
            self.present(prefVC, animated: true)
        })

        if poweredBy {
            let pw = makeLabel("Powered by Seers", size: fs * 0.7, color: UIColor(white: 0.67, alpha: 1))
            pw.textAlignment = .center
            stack.addArrangedSubview(pw)
        }

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
    }

    // MARK: - Preferences panel

    private func setupPreferences() {
        let c  = themeColors
        let l  = payload.language
        let panelHeight = UIScreen.main.bounds.height * 0.88

        let cats: [(key: String, label: String, desc: String)] = [
            ("necessary",   l?.necessoryTitle  ?? "Necessary",   l?.necessoryBody  ?? "Required for the website to function. Cannot be switched off."),
            ("preferences", l?.preferenceTitle ?? "Preferences", l?.preferenceBody ?? "Allow the website to remember choices you make."),
            ("statistics",  l?.statisticsTitle ?? "Statistics",  l?.statisticsBody ?? "Help us understand how visitors interact with the website."),
            ("marketing",   l?.marketingTitle  ?? "Marketing",   l?.marketingBody  ?? "Used to track visitors and display relevant advertisements."),
        ]

        // ── Root panel ──
        let panel = UIView()
        panel.backgroundColor = c.bg
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        // ── Scroll area ──
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(scroll)

        let content = UIStackView()
        content.axis = .vertical; content.spacing = 4
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        // ── Close ✕ ──
        let closeRow = UIView()
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(c.body, for: .normal)
        closeBtn.titleLabel?.font = .boldSystemFont(ofSize: fs)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeRow.addSubview(closeBtn)
        closeRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeBtn.trailingAnchor.constraint(equalTo: closeRow.trailingAnchor),
            closeBtn.topAnchor.constraint(equalTo: closeRow.topAnchor),
            closeBtn.bottomAnchor.constraint(equalTo: closeRow.bottomAnchor),
            closeRow.heightAnchor.constraint(equalToConstant: 28),
        ])
        closeBtn.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) { self?.onDismiss() }
        }, for: .touchUpInside)
        content.addArrangedSubview(closeRow)

        // ── "About Our Cookies" title ──
        let titleLbl = makeLabel(l?.aboutCookies ?? "About Our Cookies",
                                 size: titleFs, color: c.body, bold: true, lines: 0)
        content.addArrangedSubview(titleLbl)
        content.setCustomSpacing(4, after: titleLbl)

        // ── Body ──
        let bodyLbl = makeLabel(l?.body ?? "We use cookies to personalize content and ads.",
                                size: fs - 1, color: c.body, alpha: 0.85, lines: 0)
        content.addArrangedSubview(bodyLbl)
        content.setCustomSpacing(4, after: bodyLbl)

        // ── "Read Cookie Policy ↗" link ──
        let linkBtn = UIButton(type: .system)
        linkBtn.setTitle("Read Cookie Policy ↗", for: .normal)
        linkBtn.setTitleColor(c.agree, for: .normal)
        linkBtn.titleLabel?.font = .boldSystemFont(ofSize: fs - 2)
        linkBtn.contentHorizontalAlignment = .left
        content.addArrangedSubview(linkBtn)
        content.setCustomSpacing(6, after: linkBtn)

        // ── Allow All ──
        content.addArrangedSubview(makePrefActionBtn(
            l?.btnAgreeTitle ?? "Allow All", bg: c.agree, fg: c.agreeText) { [weak self] in
                SeersCMP.saveConsent(value: "agree", preferences: true, statistics: true, marketing: true)
                self?.dismiss(animated: true) { self?.onDismiss() }
        })
        content.setCustomSpacing(4, after: content.arrangedSubviews.last!)

        // ── Disable All ──
        content.addArrangedSubview(makePrefActionBtn(
            l?.btnDisagreeTitle ?? "Disable All",
            bg: color("#1a1a2e"), fg: .white) { [weak self] in
                SeersCMP.saveConsent(value: "disagree", preferences: false, statistics: false, marketing: false)
                self?.dismiss(animated: true) { self?.onDismiss() }
        })
        content.setCustomSpacing(8, after: content.arrangedSubviews.last!)

        // ── Separator ──
        let sep = UIView()
        sep.backgroundColor = UIColor(white: 0.88, alpha: 1)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        content.addArrangedSubview(sep)
        content.setCustomSpacing(4, after: sep)

        // ── Category accordion rows ──
        for cat in cats {
            content.addArrangedSubview(buildCatRow(cat: cat, colors: c))
            content.setCustomSpacing(3, after: content.arrangedSubviews.last!)
        }

        // ── Bottom padding so last row isn't hidden behind sticky footer ──
        let bottomPad = UIView()
        bottomPad.heightAnchor.constraint(equalToConstant: 80).isActive = true
        content.addArrangedSubview(bottomPad)

        // ── Sticky footer ──
        let footerSep = UIView()
        footerSep.backgroundColor = UIColor(white: 0.88, alpha: 1)
        footerSep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        footerSep.translatesAutoresizingMaskIntoConstraints = false

        let footer = UIView()
        footer.backgroundColor = c.bg
        footer.translatesAutoresizingMaskIntoConstraints = false

        // Footer shadow
        footer.layer.shadowColor  = UIColor.black.cgColor
        footer.layer.shadowOpacity = 0.08
        footer.layer.shadowRadius  = 8
        footer.layer.shadowOffset  = CGSize(width: 0, height: -2)

        let saveBtn = makePrefActionBtn(
            l?.btnSaveMyChoices ?? "Save my choices", bg: c.agree, fg: c.agreeText) { [weak self] in
                guard let self = self else { return }
                SeersCMP.saveConsent(value: "custom",
                    preferences: self.prefOn, statistics: self.statOn, marketing: self.mktOn)
                self.dismiss(animated: true) { self.onDismiss() }
        }
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(saveBtn)
        panel.addSubview(footer)

        NSLayoutConstraint.activate([
            // Panel
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panel.heightAnchor.constraint(equalToConstant: panelHeight),
            // Scroll fills panel above footer
            scroll.topAnchor.constraint(equalTo: panel.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: footer.topAnchor),
            // Content inside scroll
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 10),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -10),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -20),
            // Footer
            footer.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor),
            // Save button inside footer
            saveBtn.topAnchor.constraint(equalTo: footer.topAnchor, constant: 6),
            saveBtn.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 10),
            saveBtn.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -10),
            saveBtn.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -8),
        ])
    }

    /// Builds one expandable category row — border, arrow, label, toggle / "Always Active", expandable desc.
    private func buildCatRow(cat: (key: String, label: String, desc: String),
                             colors c: (bg: UIColor, body: UIColor, agree: UIColor, agreeText: UIColor,
                                        decline: UIColor, declineText: UIColor, pref: UIColor)) -> UIView {
        let isNec = cat.key == "necessary"

        // Wrapper with border
        let wrap = UIView()
        wrap.layer.borderColor  = UIColor(white: 0.88, alpha: 1).cgColor
        wrap.layer.borderWidth  = 1
        wrap.layer.cornerRadius = 5
        wrap.clipsToBounds      = true
        wrap.translatesAutoresizingMaskIntoConstraints = false

        let vStack = UIStackView()
        vStack.axis = .vertical; vStack.spacing = 0
        vStack.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: wrap.topAnchor),
            vStack.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
        ])

        // ── Header row ──
        let header = UIStackView()
        header.axis = .horizontal; header.spacing = 3; header.alignment = .center
        header.layoutMargins = UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 5)
        header.isLayoutMarginsRelativeArrangement = true

        // Arrow label
        let arrow = makeLabel("▶", size: fs * 0.6, color: c.agree)
        arrow.textAlignment = .center
        arrowLabels[cat.key] = arrow
        header.addArrangedSubview(arrow)

        // Category name
        let nameLbl = makeLabel(cat.label, size: fs * 0.85, color: c.body, bold: true)
        header.addArrangedSubview(nameLbl)
        header.setCustomSpacing(0, after: nameLbl) // spacer fills via flexible name label

        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        header.addArrangedSubview(spacer)

        // Always Active label OR UISwitch
        if isNec {
            let always = makeLabel(payload.language?.alwaysActive ?? "Always Active",
                                   size: fs * 0.75, color: c.agree, bold: true)
            header.addArrangedSubview(always)
        } else {
            let sw = UISwitch()
            sw.onTintColor = c.agree
            sw.transform   = CGAffineTransform(scaleX: 0.75, scaleY: 0.75)
            switch cat.key {
            case "preferences": sw.isOn = prefOn
            case "statistics":  sw.isOn = statOn
            default:            sw.isOn = mktOn
            }
            sw.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                switch cat.key {
                case "preferences": self.prefOn = sw.isOn
                case "statistics":  self.statOn = sw.isOn
                default:            self.mktOn  = sw.isOn
                }
            }, for: .valueChanged)
            toggleSwitches[cat.key] = sw
            header.addArrangedSubview(sw)
        }

        // ── Description (hidden by default) ──
        let descWrap = UIView()
        descWrap.backgroundColor = UIColor(white: 0, alpha: 0.02)
        descWrap.isHidden = true

        let topLine = UIView()
        topLine.backgroundColor = UIColor(white: 0.94, alpha: 1)
        topLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        topLine.translatesAutoresizingMaskIntoConstraints = false

        let descLbl = makeLabel(cat.desc, size: fs * 0.7, color: c.body, alpha: 0.8, lines: 0)
        descLbl.translatesAutoresizingMaskIntoConstraints = false

        descWrap.addSubview(topLine)
        descWrap.addSubview(descLbl)
        descWrap.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: descWrap.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: descWrap.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: descWrap.trailingAnchor),
            descLbl.topAnchor.constraint(equalTo: topLine.bottomAnchor, constant: 3),
            descLbl.leadingAnchor.constraint(equalTo: descWrap.leadingAnchor, constant: 7),
            descLbl.trailingAnchor.constraint(equalTo: descWrap.trailingAnchor, constant: -7),
            descLbl.bottomAnchor.constraint(equalTo: descWrap.bottomAnchor, constant: -4),
        ])

        descContainers[cat.key] = descWrap

        vStack.addArrangedSubview(header)
        vStack.addArrangedSubview(descWrap)

        // Tap header to expand/collapse
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCatTap(_:)))
        header.addGestureRecognizer(tap)
        header.tag = ["necessary": 0, "preferences": 1, "statistics": 2, "marketing": 3][cat.key] ?? 0
        header.isUserInteractionEnabled = true
        catStacks[cat.key] = header

        return wrap
    }

    @objc private func handleCatTap(_ gesture: UITapGestureRecognizer) {
        let keys = ["necessary", "preferences", "statistics", "marketing"]
        guard let tag = gesture.view?.tag, tag < keys.count else { return }
        let key = keys[tag]
        let isOpen = expandedKeys.contains(key)
        if isOpen { expandedKeys.remove(key) } else { expandedKeys.insert(key) }
        UIView.animate(withDuration: 0.2) {
            self.descContainers[key]?.isHidden  = isOpen
            self.arrowLabels[key]?.transform     = isOpen ? .identity : CGAffineTransform(rotationAngle: .pi / 2)
        }
    }

    // MARK: - Shared button/label factories

    private func makeBtn(_ title: String, bg: UIColor, fg: UIColor,
                         outline: Bool = false, action: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(fg, for: .normal)
        btn.titleLabel?.font   = .boldSystemFont(ofSize: fs)
        btn.backgroundColor    = bg
        btn.layer.cornerRadius = btnRadius
        if outline { btn.layer.borderWidth = 1.5; btn.layer.borderColor = fg.cgColor }
        btn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return btn
    }

    /// Full-width action button used inside the preferences panel (Allow / Disable / Save).
    private func makePrefActionBtn(_ title: String, bg: UIColor, fg: UIColor,
                                   action: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(fg, for: .normal)
        btn.titleLabel?.font   = .boldSystemFont(ofSize: fs)
        btn.backgroundColor    = bg
        btn.layer.cornerRadius = 4
        btn.contentEdgeInsets  = UIEdgeInsets(top: 5, left: 6, bottom: 5, right: 6)
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        // Stretch full width
        btn.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return btn
    }

    private func makeLabel(_ text: String, size: CGFloat, color: UIColor,
                           alpha: CGFloat = 1, bold: Bool = false, lines: Int = 1) -> UILabel {
        let lbl = UILabel()
        lbl.text          = text
        lbl.textColor     = color
        lbl.alpha         = alpha
        lbl.numberOfLines = lines
        lbl.font          = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return lbl
    }

    private func color(_ hex: String) -> UIColor {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat(int         & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Config Models

public struct SeersCMPConfig: Codable {
    public let eligible: Bool
    public let sdkKey: String?
    public let platform: String?
    public let cxHost: String?
    public let bundleId: String?
    public let packageName: String?
    public let dialogue: SeersCMPDialogue?
    public let banner: SeersCMPBanner?
    public let languages: [SeersCMPLanguage]?
    public let language: SeersCMPLanguage?
    public let categories: [SeersCMPCategory]?
    public let blockingMode: String?
    public let blockingDomains: [SeersCMPBlockDomain]

    enum CodingKeys: String, CodingKey {
        case eligible, platform, dialogue, banner, languages, language, categories
        case sdkKey = "sdk_key"; case cxHost = "cx_host"
        case bundleId = "bundle_id"; case packageName = "package_name"
        case blockingMode = "blocking_mode"; case blockingDomains = "blocking_domains"
    }

    public init(eligible: Bool) {
        self.eligible = eligible; sdkKey = nil; platform = nil; cxHost = nil
        bundleId = nil; packageName = nil; dialogue = nil; banner = nil
        languages = nil; language = nil; categories = nil; blockingMode = nil; blockingDomains = []
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        eligible      = (try? c.decode(Bool.self,   forKey: .eligible))      ?? false
        sdkKey        = try? c.decode(String.self,  forKey: .sdkKey)
        platform      = try? c.decode(String.self,  forKey: .platform)
        cxHost        = try? c.decode(String.self,  forKey: .cxHost)
        bundleId      = try? c.decode(String.self,  forKey: .bundleId)
        packageName   = try? c.decode(String.self,  forKey: .packageName)
        dialogue      = try? c.decode(SeersCMPDialogue.self,          forKey: .dialogue)
        banner        = try? c.decode(SeersCMPBanner.self,            forKey: .banner)
        languages     = try? c.decode([SeersCMPLanguage].self,        forKey: .languages)
        language      = try? c.decode(SeersCMPLanguage.self,          forKey: .language)
        categories    = try? c.decode([SeersCMPCategory].self,        forKey: .categories)
        blockingMode  = try? c.decode(String.self,                    forKey: .blockingMode)
        blockingDomains = (try? c.decode([SeersCMPBlockDomain].self,  forKey: .blockingDomains)) ?? []
    }
}

public struct SeersCMPDialogue: Codable {
    public let regionDetection: Bool; public let agreementExpire: Int
    public let defaultLanguage: String?; public let allowReject: Bool; public let poweredBy: Bool
    public let mobileTemplate: String?; public let regionSelection: Int
    enum CodingKeys: String, CodingKey {
        case regionDetection = "region_detection"; case agreementExpire = "agreement_expire"
        case defaultLanguage = "default_language"; case allowReject = "allow_reject"
        case poweredBy = "powered_by"; case mobileTemplate = "mobile_template"
        case regionSelection = "region_selection"
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        regionDetection  = (try? c.decode(Bool.self, forKey: .regionDetection)) ?? false
        agreementExpire  = (try? c.decode(Int.self,  forKey: .agreementExpire)) ?? 365
        defaultLanguage  = try? c.decode(String.self, forKey: .defaultLanguage)
        allowReject      = (try? c.decode(Bool.self, forKey: .allowReject)) ?? true
        poweredBy        = (try? c.decode(Bool.self, forKey: .poweredBy))   ?? true
        mobileTemplate   = try? c.decode(String.self, forKey: .mobileTemplate)
        // region_selection can be Int or String
        if let i = try? c.decode(Int.self, forKey: .regionSelection) {
            regionSelection = i
        } else if let s = try? c.decode(String.self, forKey: .regionSelection), let i = Int(s) {
            regionSelection = i
        } else {
            regionSelection = 1 // default GDPR
        }
    }
}

public struct SeersCMPBanner: Codable {
    public let bannerBgColor: String?; public let agreeBtnColor: String?; public let agreeTextColor: String?
    public let disagreeBtnColor: String?; public let disagreeTextColor: String?
    public let preferencesTextColor: String?; public let titleTextColor: String?; public let bodyTextColor: String?
    public let fontSize: String?; public let buttonType: String?; public let layout: String?; public let position: String?
    enum CodingKeys: String, CodingKey {
        case bannerBgColor = "banner_bg_color"; case agreeBtnColor = "agree_btn_color"
        case agreeTextColor = "agree_text_color"; case disagreeBtnColor = "disagree_btn_color"
        case disagreeTextColor = "disagree_text_color"; case preferencesTextColor = "preferences_text_color"
        case titleTextColor = "title_text_color"; case bodyTextColor = "body_text_color"
        case fontSize = "font_size"; case buttonType = "button_type"; case layout, position
    }
}

public struct SeersCMPLanguage: Codable {
    public let countryCode: String?; public let title: String?; public let body: String?
    public let btnAgreeTitle: String?; public let btnDisagreeTitle: String?
    public let btnPreferenceTitle: String?; public let btnSaveMyChoices: String?
    public let aboutCookies: String?; public let alwaysActive: String?
    public let necessoryTitle: String?; public let necessoryBody: String?
    public let preferenceTitle: String?; public let preferenceBody: String?
    public let statisticsTitle: String?; public let statisticsBody: String?
    public let marketingTitle: String?; public let marketingBody: String?
    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"; case title, body
        case btnAgreeTitle = "btn_agree_title"; case btnDisagreeTitle = "btn_disagree_title"
        case btnPreferenceTitle = "btn_preference_title"; case btnSaveMyChoices = "btn_save_my_choices"
        case aboutCookies = "about_cookies"; case alwaysActive = "always_active"
        case necessoryTitle = "necessory_title"; case necessoryBody = "necessory_body"
        case preferenceTitle = "preference_title"; case preferenceBody = "preference_body"
        case statisticsTitle = "statistics_title"; case statisticsBody = "statistics_body"
        case marketingTitle = "marketing_title"; case marketingBody = "marketing_body"
    }
}

public struct SeersCMPCategory: Codable {
    public let id: Int?; public let customizeTitle: String?; public let customizeBody: String?; public let customizeChecked: Bool?
    enum CodingKeys: String, CodingKey {
        case id; case customizeTitle = "customize_title"; case customizeBody = "customize_body"; case customizeChecked = "customize_checked"
    }
}

public struct SeersCMPBlockDomain: Codable {
    public let src: String?; public let category: Int?; public let d: String?; public let c: Int?
}

public struct SeersRegion: Codable {
    public let eligible: Bool?; public let regulation: String?; public let data: SeersGeoData?
}

public struct SeersGeoData: Codable {
    public let countryIsoCode: String?; public let countryName: String?
    enum CodingKeys: String, CodingKey { case countryIsoCode = "country_iso_code"; case countryName = "country_name" }
}

public struct SeersBlockList {
    public var statistics: [String] = []; public var marketing: [String] = []
    public var preferences: [String] = []; public var unclassified: [String] = []
}

public struct SeersBannerPayload {
    public let dialogue: SeersCMPDialogue?; public let banner: SeersCMPBanner?
    public let language: SeersCMPLanguage?; public let categories: [SeersCMPCategory]?
    public let blockList: SeersBlockList; public let regulation: String?; public let sdkKey: String
}