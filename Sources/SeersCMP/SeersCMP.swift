import Foundation

// MARK: - Models

public struct SeersConsent: Codable {
    public let sdkKey: String
    public let value: String          // "agree" | "disagree" | "custom"
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
    public let statistics:  SeersCategory
    public let marketing:   SeersCategory
    public let preferences: SeersCategory
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

    // MARK: Public API

    /// Initialize the SDK. Call once in AppDelegate or @main App.init()
    public static func initialize(
        settingsId: String,
        onShowBanner: ((SeersBannerPayload) -> Void)? = nil,
        onConsent: ((SeersConsent, SeersConsentMap) -> Void)? = nil,
        onConsentRestored: ((SeersConsent, SeersConsentMap) -> Void)? = nil
    ) {
        shared.settingsId = settingsId
        shared.onShowBanner = onShowBanner
        shared.onConsent = onConsent
        shared.onConsentRestored = onConsentRestored
        shared.start()
    }

    /// Check if a specific SDK should be blocked before initializing it.
    /// Call this BEFORE initializing any third-party SDK.
    ///
    ///     guard !SeersCMP.shouldBlock("com.google.firebase.analytics") else { return }
    ///     FirebaseApp.configure()
    public static func shouldBlock(_ identifier: String) -> Bool {
        return shared.checkShouldBlock(identifier).blocked
    }

    /// Get the full consent map — use at startup to batch-check all SDKs.
    public static func getConsentMap() -> SeersConsentMap {
        return shared.buildConsentMap()
    }

    /// Get stored consent — nil if user hasn't consented yet.
    public static func getConsent() -> SeersConsent? {
        guard let id = shared.settingsId else { return nil }
        return shared.loadStoredConsent(sdkKey: id)
    }

    /// Save consent after user makes a choice (Accept / Decline / Save choices).
    public static func saveConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool) {
        shared.persistConsent(value: value, preferences: preferences, statistics: statistics, marketing: marketing)
    }

    // MARK: Private

    static let shared = SeersCMP()
    private init() {}

    var settingsId: String?
    var config: SeersCMPConfig?
    var onShowBanner: ((SeersBannerPayload) -> Void)?
    var onConsent: ((SeersConsent, SeersConsentMap) -> Void)?
    var onConsentRestored: ((SeersConsent, SeersConsentMap) -> Void)?

    private func start() {
        guard let key = settingsId else { return }

        // Check stored consent first
        if let stored = loadStoredConsent(sdkKey: key), !isExpired(stored) {
            let map = buildConsentMap()
            onConsentRestored?(stored, map)
            return
        }

        // Fetch config from CDN / API
        fetchConfig(sdkKey: key) { [weak self] config in
            guard let self = self, let config = config, config.eligible else { return }
            self.config = config

            // Region check
            self.checkRegion(sdkKey: key) { region in
                guard self.shouldShow(dialogue: config.dialogue, region: region) else { return }
                let lang = self.resolveLanguage(config: config, region: region)
                let payload = SeersBannerPayload(
                    dialogue: config.dialogue,
                    banner: config.banner,
                    language: lang,
                    categories: config.categories,
                    blockList: self.buildBlockList(config: config),
                    regulation: region?.regulation,
                    sdkKey: key
                )
                DispatchQueue.main.async {
                    self.onShowBanner?(payload)
                }
            }
        }
    }

    // MARK: - Config fetch

    private func fetchConfig(sdkKey: String, completion: @escaping (SeersCMPConfig?) -> Void) {
        let cdnUrl = URL(string: "https://cdn.consents.dev/mobile/configs/\(sdkKey).json")!
        URLSession.shared.dataTask(with: cdnUrl) { data, response, _ in
            if let data = data,
               let config = try? JSONDecoder().decode(SeersCMPConfig.self, from: data) {
                completion(config)
            } else {
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Region check

    private func checkRegion(sdkKey: String, completion: @escaping (SeersRegion?) -> Void) {
        // Uses cx_host from config or hardcoded fallback
        let host = config?.cxHost ?? "https://vaporcmp.here"
        guard let url = URL(string: "\(host)/api/mobile/sdk/\(sdkKey)") else {
            completion(nil); return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let region = data.flatMap { try? JSONDecoder().decode(SeersRegion.self, from: $0) }
            completion(region)
        }.resume()
    }

    // MARK: - Block list

    func buildBlockList(config: SeersCMPConfig? = nil) -> SeersBlockList {
        let cfg = config ?? self.config
        guard let cfg = cfg else { return SeersBlockList() }

        var list = SeersBlockList()
        let catMap: [Int: String] = [3: "statistics", 4: "marketing", 5: "preferences", 6: "unclassified"]

        for item in cfg.blockingDomains {
            let identifier: String?
            let catId: Int?
            if cfg.blockingMode == "prior_consent" {
                identifier = item.d; catId = item.c
            } else {
                identifier = item.src; catId = item.category
            }
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
        let consent   = loadStoredConsent(sdkKey: key)
        let blockList = buildBlockList()
        let id        = identifier.lowercased()

        let categories: [(String, [String])] = [
            ("statistics",   blockList.statistics),
            ("marketing",    blockList.marketing),
            ("preferences",  blockList.preferences),
            ("unclassified", blockList.unclassified),
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
            return SeersConsentMap(
                statistics: SeersCategory(allowed: false, sdks: []),
                marketing: SeersCategory(allowed: false, sdks: []),
                preferences: SeersCategory(allowed: false, sdks: []),
                unclassified: SeersCategory(allowed: false, sdks: [])
            )
        }
        let consent   = loadStoredConsent(sdkKey: key)
        let blockList = buildBlockList()
        return SeersConsentMap(
            statistics:   SeersCategory(allowed: consent?.statistics  ?? false, sdks: blockList.statistics),
            marketing:    SeersCategory(allowed: consent?.marketing   ?? false, sdks: blockList.marketing),
            preferences:  SeersCategory(allowed: consent?.preferences ?? false, sdks: blockList.preferences),
            unclassified: SeersCategory(allowed: false,                          sdks: blockList.unclassified)
        )
    }

    // MARK: - Consent persistence

    func persistConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool) {
        guard let key = settingsId else { return }
        let expiry = Calendar.current.date(byAdding: .day, value: config?.dialogue?.agreementExpire ?? 365, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let consent = SeersConsent(
            sdkKey: key, value: value, necessary: true,
            preferences: preferences, statistics: statistics, marketing: marketing,
            timestamp: formatter.string(from: Date()),
            expiry: formatter.string(from: expiry)
        )
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

    // MARK: - Log consent to API

    private func logConsent(sdkKey: String, consent: SeersConsent) {
        let host = config?.cxHost ?? "https://vaporcmp.here"
        guard let url = URL(string: "\(host)/api/mobile/sdk/save-consent") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "sdk_key":    sdkKey,
            "platform":   config?.platform ?? "ios",
            "consent":    consent.value,
            "categories": [
                "necessary":   consent.necessary,
                "preferences": consent.preferences,
                "statistics":  consent.statistics,
                "marketing":   consent.marketing,
            ],
            "timestamp": consent.timestamp,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - Helpers

    private func shouldShow(dialogue: SeersCMPDialogue?, region: SeersRegion?) -> Bool {
        guard let d = dialogue else { return false }
        if d.regionDetection {
            return region?.eligible == true && region?.regulation != "none"
        }
        return true
    }

    private func resolveLanguage(config: SeersCMPConfig, region: SeersRegion?) -> SeersCMPLanguage? {
        if let lang = config.language { return lang }
        let code = region?.data?.countryIsoCode ?? config.dialogue?.defaultLanguage ?? "GB"
        return config.languages?.first(where: { $0.countryCode == code }) ?? config.languages?.first
    }
}

// MARK: - Config Models

public struct SeersCMPConfig: Codable {
    public let eligible: Bool
    public let sdkKey: String?
    public let platform: String?
    public let cxHost: String?
    public let dialogue: SeersCMPDialogue?
    public let banner: SeersCMPBanner?
    public let languages: [SeersCMPLanguage]?
    public let language: SeersCMPLanguage?
    public let categories: [SeersCMPCategory]?
    public let blockingMode: String?
    public let blockingDomains: [SeersCMPBlockDomain]

    enum CodingKeys: String, CodingKey {
        case eligible, platform, dialogue, banner, languages, language, categories
        case sdkKey = "sdk_key"
        case cxHost = "cx_host"
        case blockingMode = "blocking_mode"
        case blockingDomains = "blocking_domains"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        eligible       = (try? c.decode(Bool.self, forKey: .eligible)) ?? false
        sdkKey         = try? c.decode(String.self, forKey: .sdkKey)
        platform       = try? c.decode(String.self, forKey: .platform)
        cxHost         = try? c.decode(String.self, forKey: .cxHost)
        dialogue       = try? c.decode(SeersCMPDialogue.self, forKey: .dialogue)
        banner         = try? c.decode(SeersCMPBanner.self, forKey: .banner)
        languages      = try? c.decode([SeersCMPLanguage].self, forKey: .languages)
        language       = try? c.decode(SeersCMPLanguage.self, forKey: .language)
        categories     = try? c.decode([SeersCMPCategory].self, forKey: .categories)
        blockingMode   = try? c.decode(String.self, forKey: .blockingMode)
        blockingDomains = (try? c.decode([SeersCMPBlockDomain].self, forKey: .blockingDomains)) ?? []
    }
}

public struct SeersCMPDialogue: Codable {
    public let regionDetection: Bool
    public let agreementExpire: Int
    public let defaultLanguage: String?
    public let bannerBgColor: String?
    public let agreeBtnColor: String?
    public let agreeTextColor: String?
    public let disagreeBtnColor: String?
    public let disagreeTextColor: String?
    public let allowReject: Bool
    public let poweredBy: Bool
    public let mobileTemplate: String?

    enum CodingKeys: String, CodingKey {
        case regionDetection = "region_detection"
        case agreementExpire = "agreement_expire"
        case defaultLanguage = "default_language"
        case bannerBgColor   = "banner_bg_color"
        case agreeBtnColor   = "agree_btn_color"
        case agreeTextColor  = "agree_text_color"
        case disagreeBtnColor  = "disagree_btn_color"
        case disagreeTextColor = "disagree_text_color"
        case allowReject = "allow_reject"
        case poweredBy   = "powered_by"
        case mobileTemplate = "mobile_template"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        regionDetection  = (try? c.decode(Bool.self, forKey: .regionDetection)) ?? false
        agreementExpire  = (try? c.decode(Int.self,  forKey: .agreementExpire)) ?? 365
        defaultLanguage  = try? c.decode(String.self, forKey: .defaultLanguage)
        bannerBgColor    = try? c.decode(String.self, forKey: .bannerBgColor)
        agreeBtnColor    = try? c.decode(String.self, forKey: .agreeBtnColor)
        agreeTextColor   = try? c.decode(String.self, forKey: .agreeTextColor)
        disagreeBtnColor = try? c.decode(String.self, forKey: .disagreeBtnColor)
        disagreeTextColor = try? c.decode(String.self, forKey: .disagreeTextColor)
        allowReject      = (try? c.decode(Bool.self, forKey: .allowReject)) ?? true
        poweredBy        = (try? c.decode(Bool.self, forKey: .poweredBy)) ?? true
        mobileTemplate   = try? c.decode(String.self, forKey: .mobileTemplate)
    }
}

public struct SeersCMPBanner: Codable {
    public let bannerBgColor: String?
    public let agreeBtnColor: String?
    public let agreeTextColor: String?
    public let disagreeBtnColor: String?
    public let disagreeTextColor: String?
    public let preferencesBtnColor: String?
    public let preferencesTextColor: String?
    public let titleTextColor: String?
    public let bodyTextColor: String?
    public let fontStyle: String?
    public let fontSize: String?
    public let buttonType: String?
    public let layout: String?
    public let position: String?

    enum CodingKeys: String, CodingKey {
        case bannerBgColor       = "banner_bg_color"
        case agreeBtnColor       = "agree_btn_color"
        case agreeTextColor      = "agree_text_color"
        case disagreeBtnColor    = "disagree_btn_color"
        case disagreeTextColor   = "disagree_text_color"
        case preferencesBtnColor = "preferences_btn_color"
        case preferencesTextColor = "preferences_text_color"
        case titleTextColor      = "title_text_color"
        case bodyTextColor       = "body_text_color"
        case fontStyle           = "font_style"
        case fontSize            = "font_size"
        case buttonType          = "button_type"
        case layout, position
    }
}

public struct SeersCMPLanguage: Codable {
    public let countryCode: String?
    public let title: String?
    public let body: String?
    public let btnAgreeTitle: String?
    public let btnDisagreeTitle: String?
    public let btnPreferenceTitle: String?
    public let btnSaveMyChoices: String?
    public let aboutCookies: String?
    public let necessoryTitle: String?
    public let preferenceTitle: String?
    public let statisticsTitle: String?
    public let marketingTitle: String?

    enum CodingKeys: String, CodingKey {
        case countryCode       = "country_code"
        case title, body
        case btnAgreeTitle     = "btn_agree_title"
        case btnDisagreeTitle  = "btn_disagree_title"
        case btnPreferenceTitle = "btn_preference_title"
        case btnSaveMyChoices  = "btn_save_my_choices"
        case aboutCookies      = "about_cookies"
        case necessoryTitle    = "necessory_title"
        case preferenceTitle   = "preference_title"
        case statisticsTitle   = "statistics_title"
        case marketingTitle    = "marketing_title"
    }
}

public struct SeersCMPCategory: Codable {
    public let id: Int?
    public let customizeTitle: String?
    public let customizeBody: String?
    public let customizeChecked: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case customizeTitle   = "customize_title"
        case customizeBody    = "customize_body"
        case customizeChecked = "customize_checked"
    }
}

public struct SeersCMPBlockDomain: Codable {
    public let src: String?
    public let category: Int?
    public let d: String?
    public let c: Int?
}

public struct SeersRegion: Codable {
    public let eligible: Bool?
    public let regulation: String?
    public let data: SeersGeoData?
}

public struct SeersGeoData: Codable {
    public let countryIsoCode: String?
    public let countryName: String?
    enum CodingKeys: String, CodingKey {
        case countryIsoCode = "country_iso_code"
        case countryName    = "country_name"
    }
}

public struct SeersBlockList {
    public var statistics:   [String] = []
    public var marketing:    [String] = []
    public var preferences:  [String] = []
    public var unclassified: [String] = []
}

public struct SeersBannerPayload {
    public let dialogue:   SeersCMPDialogue?
    public let banner:     SeersCMPBanner?
    public let language:   SeersCMPLanguage?
    public let categories: [SeersCMPCategory]?
    public let blockList:  SeersBlockList
    public let regulation: String?
    public let sdkKey:     String
}
