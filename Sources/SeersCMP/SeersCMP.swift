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
        let body: [String: Any] = ["sdk_key": sdkKey, "platform": config?.platform ?? "ios",
            "consent": consent.value, "categories": ["necessary": consent.necessary,
            "preferences": consent.preferences, "statistics": consent.statistics, "marketing": consent.marketing],
            "timestamp": consent.timestamp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    private func shouldShow(dialogue: SeersCMPDialogue?, region: SeersRegion?) -> Bool {
        guard let d = dialogue else { return false }
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
    private let payload: SeersBannerPayload
    private let onDismiss: () -> Void

    public init(payload: SeersBannerPayload, onDismiss: @escaping () -> Void) {
        self.payload = payload
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupBanner()
    }

    private func setupBanner() {
        let b   = payload.banner
        let l   = payload.language
        let d   = payload.dialogue

        let bgColor     = color(b?.bannerBgColor     ?? "#ffffff")
        let bodyColor   = color(b?.bodyTextColor     ?? "#1a1a1a")
        let agreeColor  = color(b?.agreeBtnColor     ?? "#3b6ef8")
        let agreeText   = color(b?.agreeTextColor    ?? "#ffffff")
        let declineColor= color(b?.disagreeBtnColor  ?? "#1a1a2e")
        let declineText = color(b?.disagreeTextColor ?? "#ffffff")
        let fs          = CGFloat(Float(b?.fontSize ?? "14") ?? 14)
        let btnType     = b?.buttonType ?? "default"
        let btnRadius   = btnType.contains("rounded") ? CGFloat(20) : btnType.contains("flat") ? CGFloat(0) : CGFloat(4)
        let allowReject = d?.allowReject ?? true
        let poweredBy   = d?.poweredBy ?? true

        let bodyText   = l?.body               ?? "We use cookies to personalize content and ads."
        let btnAgree   = l?.btnAgreeTitle      ?? "Allow All"
        let btnDecline = l?.btnDisagreeTitle   ?? "Disable All"
        let btnPref    = l?.btnPreferenceTitle ?? "Cookie settings"

        // Container
        let container = UIView()
        container.backgroundColor = bgColor
        container.layer.cornerRadius = 12
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 5; stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Body label
        let bodyLabel = UILabel()
        bodyLabel.text = bodyText; bodyLabel.textColor = bodyColor; bodyLabel.font = .systemFont(ofSize: fs)
        bodyLabel.numberOfLines = 0; bodyLabel.alpha = 0.9
        stack.addArrangedSubview(bodyLabel)

        // Cookie settings outline
        stack.addArrangedSubview(makeBtn(btnPref, bg: .clear, fg: bodyColor, fs: fs, radius: btnRadius, outline: true) { [weak self] in
            self?.dismiss(animated: true)
        })

        // Decline
        if allowReject {
            stack.addArrangedSubview(makeBtn(btnDecline, bg: declineColor, fg: declineText, fs: fs, radius: btnRadius) { [weak self] in
                SeersCMP.saveConsent(value: "disagree", preferences: false, statistics: false, marketing: false)
                self?.dismiss(animated: true) { self?.onDismiss() }
            })
        }

        // Allow All
        stack.addArrangedSubview(makeBtn(btnAgree, bg: agreeColor, fg: agreeText, fs: fs, radius: btnRadius) { [weak self] in
            SeersCMP.saveConsent(value: "agree", preferences: true, statistics: true, marketing: true)
            self?.dismiss(animated: true) { self?.onDismiss() }
        })

        if poweredBy {
            let pw = UILabel()
            pw.text = "Powered by Seers"; pw.textColor = UIColor(white: 0.67, alpha: 1)
            pw.font = .systemFont(ofSize: fs * 0.7); pw.textAlignment = .center
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

    private func makeBtn(_ title: String, bg: UIColor, fg: UIColor, fs: CGFloat, radius: CGFloat, outline: Bool = false, action: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal); btn.setTitleColor(fg, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: fs)
        btn.backgroundColor = bg; btn.layer.cornerRadius = radius
        if outline { btn.layer.borderWidth = 1.5; btn.layer.borderColor = fg.cgColor }
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return btn
    }

    private func color(_ hex: String) -> UIColor {
        var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: h).scanHexInt64(&int)
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
    public let mobileTemplate: String?
    enum CodingKeys: String, CodingKey {
        case regionDetection = "region_detection"; case agreementExpire = "agreement_expire"
        case defaultLanguage = "default_language"; case allowReject = "allow_reject"
        case poweredBy = "powered_by"; case mobileTemplate = "mobile_template"
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        regionDetection = (try? c.decode(Bool.self, forKey: .regionDetection)) ?? false
        agreementExpire = (try? c.decode(Int.self,  forKey: .agreementExpire)) ?? 365
        defaultLanguage = try? c.decode(String.self, forKey: .defaultLanguage)
        allowReject     = (try? c.decode(Bool.self, forKey: .allowReject)) ?? true
        poweredBy       = (try? c.decode(Bool.self, forKey: .poweredBy))   ?? true
        mobileTemplate  = try? c.decode(String.self, forKey: .mobileTemplate)
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
