import Foundation
import UIKit

let seersDefaultBadgeBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAADwAAAA8CAYAAAA6/NlyAAAACXBIWXMAAAAAAAAAAQCEeRdzAAAIOUlEQVR4nNWb+1NVVRTH7w+KCJX4mB5T/QUqkf5G+KipqV9ENGCa/gCSaFIYzWpGbCRFkEZRa2pMp5pRtB/yBb6Q91MBTVR8AD7zBYiioKDIaX+Od5/ZHLjAPedcTq2Z78g5Z59993evtddae52txxMgCQ4ODp05c+ZH8fHx36YkJ//+Q1ZW9a9btjTvzMlp37N7dw/gb+7xLHnJkt/i4uK+mTFjxoe8G6hxOSqTJk16LSYmJiUzM7NcEHqSu3+/ZgW8m5mRURYzf37yxIkTX3Wb1wAJDw9/97uVK/P27d3ba5WkL9DnytTU3OnTp891m6cnIiLi/XWZmRVOk/QFLOet8PD3Rp0oppuSkvLHaBE1IzU1df+UKVPeHBWys2fP/uTPXbs63CIrsWvnzvtRUVFxASMaFBQUnJSU9LPbRM1ITEz8cezYseMcJSvCxAtpaWlH3CbnC+lr1hSFhoZOcIRs2IQJL2/Mzj7pNqnhkJ2dfYKx2iIbEhLyUvaGDXVukxkpNm/aVC80HWaJLGsWU3GbhL9YvXp1gaU1/UVS0i9uD94qFi1atNkvsrOiouLdHrRdzJ0z59MRkZ08efLr/4U4axfEaRKkYQkvX758l9uDdQpLly7dPiRZcmOnf7Tg6FGtoaFBa21p0R49eqT19vZqT58+1bq6urTbt29r9adOaUcOHw4Y6SE3HSTnTv3Q4UOHtKtXrmjPnj3ThhMm4Py5c9rBAwccJ5y1bl3loGTZ4jn1I2WlpdojoUEp3d3d2uVLl7STJ05o1VVVOv4+eVK7dvWq1iOeSbnX3h4QbU+bNm32AMLsZ536gY6ODkNzp+vrtQN5ecYztIj25fWhgwe1C+fPG5bQ2dk5gPSx6up+ffgLdlf9yIaFhb2yd8+ep1Y6YyA1NTXaJaFBNAahekHy5s2bWmFBgUESk+18+NDQ5pMnT7Tr169rRUVFepsqoXUmCLlz506/3zhz5oxuJVbNHm5wNAgvXLBgqRWiOKOenh6DxMMHDwYMCNIPFaJm6evr0ydIalLKibo6o4/8I0cGve8PoqOjF9tyVuVlZc9JCjKnT5/Wjh87ptXW1vZrg7liolKjaIj3SoqLdatoEZqUwvrmHbSur+d79/r1Jftpamy0RHhtenqJTpYKIRVEfztgnaHhvNxcnahcg5UVFUabxosXjbUMycH6aRQE5ISwtukX0mZN3hJLBLlx44YlwnDUq6GURa10oJMWpnapuVk3S+Tx48eGwzman6/HXKTh7FnjHSaI99Rr3kNOiZhsWFB5uXZFhLUCrx/4x6v5FtP69gdvR0R84KFubLWDtrY2wyRJKoq9DkjXyK1b+v0HYl1DStUUE3RMLAFz28uXLxv3pLkzoVzjEHWHJpIVq+ONjY1d7qFIbrWDZq92GYwaSqQpm02c+DuY82lrbdXvscblvXYRk5Fr167p163eNk1NTZYJL1m8eJuHqr/VDvDA+Yp54qGvejWBnBXhRDVdtC2tQcZV3pfrv0KZHNrokyBiNNfS7M2O0R/oWde2rVuvWO1AJVMnNNalZFfnhENT2xCnpaiDbvI6LQhK02cypF+oE22xHin4Bqvj5LOOJ2fHjrt2yOJo5OwjxOXjx4/3a0PiIOWm4mVxXjLZUK2hWHh0KaUlJUZ8vn//vi3F7Ni+vdVjJSSpkGEFjbBZMKeFmKTUFiZNbJbPpLNSTRzUiAmTfepZmugDuXjhgi3Cu//6q9s2YTYKeFIZPgztCeIydiIkKOp6J9GQUmOyiLMijCGkk+rEkLTYJmzXpM1gHUJG3QURStQNQ1FhoWHKODlzH83CEyNkV1zjGyCvhjfLJu2E0wKYJKFGemIE72t2XoAdFNJ+9+6guyCDsLAKriFuJxxJ6E4rKyurym5HmC+poSotLS26Jn1NTq3IpX3tfNgryzWMV8ZP+OrLH/Cl01bioYISDsK/eFX1GY6KLAovW2ha64D26ju0lybPxKmOzg70xMNOaqmCzUHxIBsEdlEyiUDkrkgCR4YmQbVCut5r9oiardmBnlra2TwMBTwqRTopECIVNTseruXWD8dE0U8+Y/2Trzs1JoqUnnHjxoXYDU0qyIxk3isFR1YxhJYIbTK9xCOr69VOaUcFHOH6vACQkVHmFGGSfSkU8igOmLWKFqsqK/vdw4nJBIX1SwZnNwypWJueXmxUPDh541THOBgSBfJl84CpX7GvlcTuirCkOjHqWt3e+I2mnXJWIHrevC8dKeKNBIQWEgxJVBW0qToynBhFPKccFRhQxEM4GuQ00VKxNtkrq8V4NhckEeyeZEUEOSNMP1ATnrpixb4BdWk+STj9QzLpl5ok+VfNFOdEsQ5ptFicGwmmTp06a/BPLQ46Lwm+HV0QRH19UWCd46WddFAq+jkrs3DoK1CzLEF8JutyKl0cCvv37esb9DOLKl8tW5YTqAGgbXU9s4bNaaiT4PDckGQRPiLzMTlQg8Bjk3EBO+Wa4SA43BvxwVROuAXS1EYD70RGfjwislI+T0z8ye1BW0VCQkK2X2QRjv5wBMjtwfuL79PS8seMGRPkN2Fk/PjxL/7PDqadsn0EkeN8HOtzm8xw2LB+fa3to4dS9MOlq1YddpuUL7D0OCbpCFkprGlOuLlNzozPEhI2Wl6zIxFCViDj9EhBnI2MjFwYMKKqENDJYkjd3CDr/S8Ab4wKWVXYYWWsXVs6WkQ5tjBsbjwawiCY9UAUEeiT/azPLZ6bQljgtAya4DuOVZK8y7aOsoxjoSbQQoWQMxVxsbFfUwDnYzSfOviWJf8rHn9zj2e0oS3vGNXFAMi/90FAXtptfksAAAAASUVORK5CYII="
let seersDefaultLogoURL =
    "https://seers-application-assets.s3.amazonaws.com/images/logo/seersco-logo.png"

// Seers CMP registered ID (IAB TCF)
private let seersCmpId      = 158
private let seersCmpVersion = 1
// Google Consent Mode v2 developer ID
private let seersGoogleDevId = "dNmU0M2"
// Allowlist of trusted Seers hosts — prevents SSRF (CWE-918)
private let seersAllowedHosts = ["consents.dev", "seers.ai", "seersco.com", "cdn.consents.dev"]

private func seersIsAllowedHost(_ urlString: String) -> Bool {
    guard let host = URL(string: urlString)?.host else { return false }
    return seersAllowedHosts.contains { h in host == h || host.hasSuffix("." + h) }
}

// Seers CMP registered ID (IAB TCF)
func seersDefaultBadgeImage() -> UIImage? {
    guard let data = Data(base64Encoded: seersDefaultBadgeBase64) else { return nil }
    return UIImage(data: data)
}

func seersLoadRemoteImage(_ urlString: String?, completion: @escaping (UIImage?) -> Void) {
    guard let urlString, let url = URL(string: urlString) else {
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: url) { data, _, _ in
        let image = data.flatMap(UIImage.init(data:))
        DispatchQueue.main.async {
            completion(image)
        }
    }.resume()
}

// MARK: - IAB TCF v2.3

/// Stores IAB TCF v2.3 consent signals in UserDefaults using the standard IABTCF_* keys.
/// Spec: https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework
public struct SeersIABTCF {

    // IAB TCF v2.3 purpose IDs mapped to Seers categories
    // Purposes 1-10 are standard IAB TCF purposes
    static let statisticsPurposes  = [7, 8, 9]   // Measure ad/content performance, audience insights
    static let marketingPurposes   = [1, 2, 3, 4] // Store/access info, personalised ads, ad selection
    static let preferencesPurposes = [5, 6]        // Personalised content, content selection

    /// Write all IABTCF_* keys based on consent choices.
    public static func store(
        necessary: Bool,
        preferences: Bool,
        statistics: Bool,
        marketing: Bool,
        cmpId: Int = seersCmpId,
        cmpVersion: Int = seersCmpVersion
    ) {
        let d = UserDefaults.standard

        // Core CMP metadata
        d.set(1,          forKey: "IABTCF_CmpSdkID")          // Our CMP ID
        d.set(cmpVersion, forKey: "IABTCF_CmpSdkVersion")
        d.set(1,          forKey: "IABTCF_PolicyVersion")      // TCF policy v4 → stored as 1 (applies)
        d.set(1,          forKey: "IABTCF_gdprApplies")        // 1 = GDPR applies
        d.set(1,          forKey: "IABTCF_UseNonStandardTexts")

        // Build purpose consent string (10 purposes, index 0 = purpose 1)
        var purposeConsents = Array(repeating: "0", count: 10)
        purposeConsents[0] = "1" // Necessary (purpose 1) always on

        if marketing {
            for p in marketingPurposes   { if p <= 10 { purposeConsents[p-1] = "1" } }
        }
        if statistics {
            for p in statisticsPurposes  { if p <= 10 { purposeConsents[p-1] = "1" } }
        }
        if preferences {
            for p in preferencesPurposes { if p <= 10 { purposeConsents[p-1] = "1" } }
        }

        let purposeConsentsStr = purposeConsents.joined()
        d.set(purposeConsentsStr, forKey: "IABTCF_PurposeConsents")

        // Legitimate interests — only non-necessary purposes can use LI
        var purposeLI = Array(repeating: "0", count: 10)
        if statistics  { purposeLI[6] = "1"; purposeLI[7] = "1" } // purposes 7,8
        if preferences { purposeLI[5] = "1" }                      // purpose 6
        d.set(purposeLI.joined(), forKey: "IABTCF_PurposeLegitimateInterests")

        // Special feature opt-ins (all off by default)
        d.set("00", forKey: "IABTCF_SpecialFeaturesOptIns")

        // Vendor consents — simplified: allow all IAB vendors if category consented
        // In a full implementation this would use the GVL vendor list
        d.set("",   forKey: "IABTCF_VendorConsents")
        d.set("",   forKey: "IABTCF_VendorLegitimateInterests")

        // Publisher restrictions — none
        d.set("",   forKey: "IABTCF_PublisherRestrictions10")

        // Publisher TC
        d.set(purposeConsentsStr, forKey: "IABTCF_PublisherConsent")
        d.set(purposeLI.joined(), forKey: "IABTCF_PublisherLegitimateInterests")

        // Consent string — base64url encoded minimal TC string
        d.set(buildTCString(purposeConsents: purposeConsents, cmpId: cmpId, cmpVersion: cmpVersion),
              forKey: "IABTCF_TCString")

        // Timestamp
        d.set(Int(Date().timeIntervalSince1970), forKey: "IABTCF_ConsentTimestamp")
    }

    /// Returns the stored TCF data as a dictionary (equivalent of getTCData).
    public static func getTCData() -> [String: Any] {
        let d = UserDefaults.standard
        return [
            "tcString":                    d.string(forKey: "IABTCF_TCString") ?? "",
            "cmpId":                       d.integer(forKey: "IABTCF_CmpSdkID"),
            "cmpVersion":                  d.integer(forKey: "IABTCF_CmpSdkVersion"),
            "gdprApplies":                 d.integer(forKey: "IABTCF_gdprApplies") == 1,
            "purposeConsents":             d.string(forKey: "IABTCF_PurposeConsents") ?? "",
            "purposeLegitimateInterests":  d.string(forKey: "IABTCF_PurposeLegitimateInterests") ?? "",
            "specialFeaturesOptIns":       d.string(forKey: "IABTCF_SpecialFeaturesOptIns") ?? "",
            "vendorConsents":              d.string(forKey: "IABTCF_VendorConsents") ?? "",
            "publisherConsent":            d.string(forKey: "IABTCF_PublisherConsent") ?? "",
            "consentTimestamp":            d.integer(forKey: "IABTCF_ConsentTimestamp"),
        ]
    }

    /// Clears all IABTCF_* keys (e.g. on consent withdrawal).
    public static func clear() {
        let keys = [
            "IABTCF_CmpSdkID", "IABTCF_CmpSdkVersion", "IABTCF_PolicyVersion",
            "IABTCF_gdprApplies", "IABTCF_UseNonStandardTexts", "IABTCF_PurposeConsents",
            "IABTCF_PurposeLegitimateInterests", "IABTCF_SpecialFeaturesOptIns",
            "IABTCF_VendorConsents", "IABTCF_VendorLegitimateInterests",
            "IABTCF_PublisherRestrictions10", "IABTCF_PublisherConsent",
            "IABTCF_PublisherLegitimateInterests", "IABTCF_TCString", "IABTCF_ConsentTimestamp",
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // Builds a minimal valid base64url TC string (TCF v2.2 core segment)
    private static func buildTCString(purposeConsents: [String], cmpId: Int, cmpVersion: Int) -> String {
        // Encode as 6-bit integers packed into bits, then base64url
        // Version(6) Created(36) LastUpdated(36) CmpId(12) CmpVersion(12)
        // ConsentScreen(6) ConsentLanguage(12) VendorListVersion(12) TcfPolicyVersion(6)
        // IsServiceSpecific(1) UseNonStandardTexts(1) SpecialFeatureOptIns(12)
        // PurposeConsents(24) PurposeLegitimateInterests(24) PurposeOneTreatment(1)
        // PublisherCC(12) VendorConsents(maxId=0,encoding=0,numEntries=0)
        // VendorLegitimateInterests(maxId=0,encoding=0,numEntries=0)
        // PublisherRestrictions(numRestrictions=0)
        let now = Int(Date().timeIntervalSince1970 * 10) // deciseconds
        var bits = ""
        bits += intToBits(2,          length: 6)   // version = 2
        bits += intToBits(now,        length: 36)  // created
        bits += intToBits(now,        length: 36)  // lastUpdated
        bits += intToBits(cmpId,      length: 12)  // cmpId
        bits += intToBits(cmpVersion, length: 12)  // cmpVersion
        bits += intToBits(0,          length: 6)   // consentScreen
        bits += langToBits("EN")                   // consentLanguage (12 bits)
        bits += intToBits(48,         length: 12)  // vendorListVersion
        bits += intToBits(4,          length: 6)   // tcfPolicyVersion = 4
        bits += "0"                                // isServiceSpecific
        bits += "0"                                // useNonStandardTexts
        bits += String(repeating: "0", count: 12)  // specialFeatureOptIns
        // purposeConsents: 24 bits (purposes 1-24, we use 1-10)
        let pcBits = purposeConsents.joined() + String(repeating: "0", count: 14)
        bits += pcBits
        bits += String(repeating: "0", count: 24)  // purposeLegitimateInterests
        bits += "0"                                // purposeOneTreatment
        bits += langToBits("AA")                   // publisherCC
        // VendorConsents: maxId=0, isRangeEncoding=0
        bits += intToBits(0, length: 16)           // maxVendorId
        bits += "0"                                // isRangeEncoding
        // VendorLegitimateInterests: maxId=0, isRangeEncoding=0
        bits += intToBits(0, length: 16)
        bits += "0"
        // PublisherRestrictions: numRestrictions=0
        bits += intToBits(0, length: 12)
        return base64urlEncode(bits)
    }

    private static func intToBits(_ value: Int, length: Int) -> String {
        let bin = String(value, radix: 2)
        let padded = String(repeating: "0", count: max(0, length - bin.count)) + bin
        return String(padded.suffix(length))
    }

    private static func langToBits(_ lang: String) -> String {
        let upper = lang.uppercased()
        let chars = Array(upper)
        guard chars.count >= 2 else { return String(repeating: "0", count: 12) }
        let a = max(0, Int(chars[0].asciiValue ?? 65) - 65)
        let b = max(0, Int(chars[1].asciiValue ?? 65) - 65)
        return intToBits(a, length: 6) + intToBits(b, length: 6)
    }

    private static func base64urlEncode(_ bits: String) -> String {
        var padded = bits
        let rem = padded.count % 6
        if rem != 0 { padded += String(repeating: "0", count: 6 - rem) }
        let dict = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        var result = ""
        var i = padded.startIndex
        while i < padded.endIndex {
            let end = padded.index(i, offsetBy: 6)
            let chunk = String(padded[i..<end])
            if let idx = Int(chunk, radix: 2), idx < dict.count {
                result.append(dict[idx])
            }
            i = end
        }
        return result
    }
}

// MARK: - Models

public struct SeersConsent: Codable {
    public let sdkKey: String
    public let value: String
    public let necessary: Bool
    public let preferences: Bool
    public let statistics: Bool
    public let marketing: Bool
    public let doNotSell: Bool?
    public let timestamp: String
    public let expiry: String
    enum CodingKeys: String, CodingKey {
        case sdkKey = "sdk_key"
        case doNotSell = "do_not_sell"
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
    public static func getPrivacyFrameworks() -> [String: Any] { shared.buildPrivacyFrameworks() }
    public static func frameworkEnabled(_ key: String) -> Bool {
        guard let value = shared.frameworkValue(key) else { return false }
        return (value as? Bool) == true || ((value as? [String: Any])?["enabled"] as? Bool) == true
    }
    public static func getConsentSignals(value: String = "custom", preferences: Bool = false, statistics: Bool = false, marketing: Bool = false, doNotSell: Bool? = nil, attStatus: String? = nil) -> [String: Any] {
        shared.buildConsentSignals(value: value, preferences: preferences, statistics: statistics, marketing: marketing, doNotSell: doNotSell, attStatus: attStatus)
    }
    public static func saveConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool, doNotSell: Bool? = nil, attStatus: String? = nil) {
        shared.persistConsent(value: value, preferences: preferences, statistics: statistics, marketing: marketing, doNotSell: doNotSell, attStatus: attStatus)
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
            // Still retry any queued consent in background
            retryQueuedConsentIfNeeded()
            return
        }
        let ts = Int(Date().timeIntervalSince1970) / 60
        fetchConfig(sdkKey: key, ts: ts) { [weak self] config in
            guard let self = self, let config = config, config.eligible else { return }
            self.config = config
            if let appId = SeersCMP.appId {
                let registered = config.bundleId ?? config.packageName
                if let reg = registered, !appId.lowercased().elementsEqual(reg.lowercased()) { return }
            }
            self.checkRegion(sdkKey: key) { region in
                guard self.shouldShow(dialogue: config.dialogue, region: region) else { return }
                let lang = self.resolveLanguage(config: config, region: region)
                let payload = SeersBannerPayload(
                    dialogue: config.dialogue, banner: config.banner, language: lang,
                    categories: config.categories, privacyFrameworks: self.buildPrivacyFrameworks(), blockList: self.buildBlockList(config: config),
                    regulation: region?.regulation, sdkKey: key
                )
                self._lastPayload = payload
                DispatchQueue.main.async {
                    if let cb = self.onShowBanner { cb(payload) } else { self.autoShowBanner(payload) }
                }
            }
        }
    }

    // Auto retry queued consent with exponential backoff (max 5 attempts)
    private func retryQueuedConsentIfNeeded() {
        guard let key = settingsId,
              UserDefaults.standard.data(forKey: "SeersConsentQueue_\(key)") != nil else { return }
        scheduleRetry(sdkKey: key, attempt: 1)
    }

    private func scheduleRetry(sdkKey: String, attempt: Int) {
        guard attempt <= 5 else { return }
        let delay = pow(2.0, Double(attempt)) // 2, 4, 8, 16, 32 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  let data = UserDefaults.standard.data(forKey: "SeersConsentQueue_\(sdkKey)"),
                  let consent = try? JSONDecoder().decode(SeersConsent.self, from: data) else { return }
            self.logConsent(sdkKey: sdkKey, consent: consent)
            // If still queued after attempt, schedule next
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
                if UserDefaults.standard.data(forKey: "SeersConsentQueue_\(sdkKey)") != nil {
                    self?.scheduleRetry(sdkKey: sdkKey, attempt: attempt + 1)
                }
            }
        }
    }

    private func autoShowBanner(_ payload: SeersBannerPayload) {
        // Use connectedScenes for iOS 13+ (UIApplication.shared.windows deprecated iOS 15+)
        let window: UIWindow?
        if #available(iOS 13.0, *) {
            window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            window = UIApplication.shared.keyWindow
        }
        guard let window = window else { return }
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
                // Network failed — try cached config
                completion(self.loadCachedConfig(sdkKey: sdkKey))
                return
            }
            self.cacheConfig(sdkKey: sdkKey, data: data)
            completion(config)
        }.resume()
    }

    private func cacheConfig(sdkKey: String, data: Data) {
        UserDefaults.standard.set(data, forKey: "SeersConfig_\(sdkKey)")
    }

    private func loadCachedConfig(sdkKey: String) -> SeersCMPConfig? {
        guard let data = UserDefaults.standard.data(forKey: "SeersConfig_\(sdkKey)") else { return nil }
        return try? JSONDecoder().decode(SeersCMPConfig.self, from: data)
    }

    private func checkRegion(sdkKey: String, completion: @escaping (SeersRegion?) -> Void) {
        let host = config?.cxHost ?? ""
        guard !host.isEmpty, seersIsAllowedHost(host), let url = URL(string: "\(host)/api/mobile/sdk/\(sdkKey)") else {
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

    func persistConsent(value: String, preferences: Bool, statistics: Bool, marketing: Bool, doNotSell: Bool? = nil, attStatus: String? = nil) {
        guard let key = settingsId else { return }
        let expiry = Calendar.current.date(byAdding: .day, value: config?.dialogue?.agreementExpire ?? 365, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let privacySignals = buildConsentSignals(value: value, preferences: preferences, statistics: statistics, marketing: marketing, doNotSell: doNotSell, attStatus: attStatus)
        let consent = SeersConsent(sdkKey: key, value: value, necessary: true,
            preferences: preferences, statistics: statistics, marketing: marketing,
            doNotSell: ((privacySignals["universalOptOut"] as? [String: Any])?["doNotSell"] as? Bool) == true,
            timestamp: formatter.string(from: Date()), expiry: formatter.string(from: expiry))
        if let data = try? JSONEncoder().encode(consent) {
            UserDefaults.standard.set(data, forKey: "SeersConsent_\(key)")
        }
        // Store IAB TCF v2.3 keys (only if enabled in dashboard)
        if config?.dialogue?.enableIabTcf == true {
            SeersIABTCF.store(necessary: true, preferences: preferences, statistics: statistics, marketing: marketing)
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

    // Returns a stable anonymous device ID scoped to this sdk_key.
    // Generated once, stored in UserDefaults, never changes.
    // Used for MAU deduplication — not linked to any PII.
    private func getOrCreateDeviceId(sdkKey: String) -> String {
        let key = "SeersDeviceId_\(sdkKey)"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    private func logConsent(sdkKey: String, consent: SeersConsent) {
        let host = config?.cxHost ?? ""
        guard !host.isEmpty, seersIsAllowedHost(host), let url = URL(string: "\(host)/api/mobile/sdk/save-consent") else {
            queueConsent(sdkKey: sdkKey, consent: consent)
            return
        }
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
            // Stable anonymous device ID for MAU deduplication — not PII
            "device_id":  getOrCreateDeviceId(sdkKey: sdkKey),
        ]
        body["do_not_sell"] = consent.doNotSell == true
        body["privacy_signals"] = buildConsentSignals(value: consent.value, preferences: consent.preferences, statistics: consent.statistics, marketing: consent.marketing, doNotSell: consent.doNotSell == true)
        if let v = SeersCMP.appVersion { body["app_version"] = v }
        if let e = SeersCMP.userEmail  { body["email"]       = e }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                self?.queueConsent(sdkKey: sdkKey, consent: consent)
            } else {
                self?.clearQueuedConsent(sdkKey: sdkKey)
            }
        }.resume()
    }

    private func queueConsent(sdkKey: String, consent: SeersConsent) {
        if let data = try? JSONEncoder().encode(consent) {
            UserDefaults.standard.set(data, forKey: "SeersConsentQueue_\(sdkKey)")
        }
    }

    private func clearQueuedConsent(sdkKey: String) {
        UserDefaults.standard.removeObject(forKey: "SeersConsentQueue_\(sdkKey)")
    }

    /// Call this when the app regains connectivity (e.g. from AppDelegate reachability callback).
    public static func retryQueuedConsent() {
        guard let key = shared.settingsId,
              let data = UserDefaults.standard.data(forKey: "SeersConsentQueue_\(key)"),
              let consent = try? JSONDecoder().decode(SeersConsent.self, from: data) else { return }
        shared.logConsent(sdkKey: key, consent: consent)
    }

    /// Returns IAB TCF v2.3 consent data (IABTCF_* keys).
    /// Use this to pass TCF data to ad SDKs that require it.
    public static func getTCData() -> [String: Any] { SeersIABTCF.getTCData() }

    /// Optional: set app version for consent log enrichment.
    ///   SeersCMP.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    public static var appVersion: String?

    /// Optional: set user email for consent log enrichment.
    ///   SeersCMP.userEmail = "user@example.com"
    public static var userEmail: String?

    func buildPrivacyFrameworks() -> [String: Any] {
        let d = config?.dialogue
        let platform = config?.platform
        return [
            "google_consent_mode_v2": ["enabled": d?.applyGoogleConsent == true],
            "iab_tcf": ["enabled": d?.enableIabTcf == true, "version": "2.3"],
            "apple_att": ["enabled": d?.appleAtt == true, "applies": ["ios", "both", "react_native", "flutter"].contains(platform ?? "")],
            "google_play_disclosure": ["enabled": d?.googlePlayDisclosure == true, "applies": ["android", "both", "react_native", "flutter"].contains(platform ?? "")],
            "universal_opt_out": ["enabled": d?.universalOptOut == true, "signal": "do_not_sell_or_share"],
            "conditional": [
                "gpp": d?.enableGpp == true,
                "microsoft_clarity": d?.microsoftClarityConsent == true,
                "meta_facebook_sdk": d?.metaSdkConsent == true,
                "microsoft_ads": d?.microsoftAdsConsent == true,
                "amazon_ads": d?.amazonAdsConsent == true,
            ],
        ]
    }

    func frameworkValue(_ key: String) -> Any? {
        var node: Any? = buildPrivacyFrameworks()
        for part in key.split(separator: ".").map(String.init) {
            guard let dict = node as? [String: Any] else { return nil }
            node = dict[part]
        }
        return node
    }

    func buildConsentSignals(value: String, preferences: Bool, statistics: Bool, marketing: Bool, doNotSell: Bool?, attStatus: String? = nil) -> [String: Any] {
        let frameworks = buildPrivacyFrameworks()
        let apple = frameworks["apple_att"] as? [String: Any] ?? [:]
        let play = frameworks["google_play_disclosure"] as? [String: Any] ?? [:]
        let google = frameworks["google_consent_mode_v2"] as? [String: Any] ?? [:]
        let iab = frameworks["iab_tcf"] as? [String: Any] ?? [:]
        let opt = frameworks["universal_opt_out"] as? [String: Any] ?? [:]
        let optOut = doNotSell ?? (value == "disagree")
        return [
            "appleATT": ["enabled": apple["enabled"] as? Bool == true, "applies": apple["applies"] as? Bool == true, "status": (attStatus as Any?) ?? NSNull()],
            "googlePlayDisclosure": ["enabled": play["enabled"] as? Bool == true, "applies": play["applies"] as? Bool == true],
            "googleConsentModeV2": [
                "enabled": google["enabled"] as? Bool == true,
                "analytics_storage": statistics ? "granted" : "denied",
                "ad_storage": marketing ? "granted" : "denied",
                "ad_user_data": marketing ? "granted" : "denied",
                "ad_personalization": marketing ? "granted" : "denied",
            ],
            "iabTCF": ["enabled": iab["enabled"] as? Bool == true, "version": iab["version"] ?? "2.3"],
            "universalOptOut": ["enabled": opt["enabled"] as? Bool == true, "signal": opt["signal"] ?? "do_not_sell_or_share", "doNotSell": optOut],
            "conditional": frameworks["conditional"] ?? [:],
        ]
    }

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

final class SeersPassthroughView: UIView {
    var passthroughViews: [UIView] = []
    var blocksAllTouches = true

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if blocksAllTouches {
            return super.point(inside: point, with: event)
        }

        return passthroughViews.contains { view in
            let converted = convert(point, to: view)
            return view.point(inside: converted, with: event)
        }
    }
}

public class SeersBannerViewController: UIViewController {

    private let payload:   SeersBannerPayload
    private let onDismiss: () -> Void

    /// Set to true before presenting to skip directly to the preferences panel.
    var isShowingPreferences: Bool = false
    private var bannerVisible = true
    private var badgeVisible = false
    private var badgeTimeoutWorkItem: DispatchWorkItem?
    private weak var badgeButton: UIButton?

    // ── Preference toggle state mirrors the backend dialogue defaults. ──
    private var prefOn = false
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
        self.prefOn    = payload.dialogue?.preferencesChecked ?? false
        self.statOn    = payload.dialogue?.statisticsChecked ?? false
        self.mktOn     = payload.dialogue?.targetingChecked ?? false
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func loadView() {
        view = SeersPassthroughView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI()
    }

    deinit {
        badgeTimeoutWorkItem?.cancel()
    }

    private var hasBadge: Bool { payload.dialogue?.hasBadge ?? false }
    private var bannerTimeout: Int { payload.dialogue?.bannerTimeout ?? 0 }
    private var showLogo: Bool { (payload.dialogue?.logoStatus ?? "default") != "none" }
    private var logoURL: String { payload.dialogue?.logoLink ?? seersDefaultLogoURL }
    private var customBadgeURL: String? {
        guard payload.dialogue?.badgeStatus == "custom" else { return nil }
        return payload.dialogue?.badgeLink
    }

    private func refreshUI() {
        badgeTimeoutWorkItem?.cancel()
        view.subviews.forEach { $0.removeFromSuperview() }
        badgeButton = nil

        let passthroughView = view as? SeersPassthroughView
        passthroughView?.passthroughViews = []
        passthroughView?.blocksAllTouches = isShowingPreferences || bannerVisible
        view.backgroundColor = .clear

        if isShowingPreferences {
            setupPreferences()
            return
        }

        if badgeVisible, hasBadge {
            setupBadge()
            return
        }

        guard bannerVisible else { return }
        setupBanner()
    }

    private func showBadgeOnly() {
        badgeTimeoutWorkItem?.cancel()
        if hasBadge {
            isShowingPreferences = false
            bannerVisible = false
            badgeVisible = true
            refreshUI()
            return
        }

        dismiss(animated: true) { self.onDismiss() }
    }

    private func reopenBannerFromBadge() {
        badgeTimeoutWorkItem?.cancel()
        badgeVisible = false
        bannerVisible = true
        refreshUI()

        guard hasBadge, bannerTimeout > 0 else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isShowingPreferences = false
            self.bannerVisible = false
            self.badgeVisible = true
            self.refreshUI()
        }
        badgeTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(bannerTimeout), execute: workItem)
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
    private var dialogRadius: CGFloat {
        let layout = payload.banner?.layout ?? "default"
        if layout == "rounded" { return 20 }
        if layout == "flat" { return 0 }
        return 10
    }
    private var sheetRadius: CGFloat {
        let layout = payload.banner?.layout ?? "default"
        if layout == "flat" { return 0 }
        if layout == "rounded" { return 16 }
        return 14
    }

    // MARK: - Banner panel

    private func setupBanner() {
        let c   = themeColors
        let l   = payload.language
        let d   = payload.dialogue
        let tmpl = d?.mobileTemplate ?? "popup"
        let layout = payload.banner?.layout ?? "default"
        let position = payload.banner?.position ?? "bottom"

        let allowReject = d?.allowReject ?? true
        let poweredBy   = d?.poweredBy   ?? true
        let bodyText    = l?.body               ?? "We use cookies to personalize content and ads."
        let titleText   = l?.title              ?? "We use cookies"
        let btnAgree    = l?.btnAgreeTitle      ?? "Allow All"
        let btnDecline  = l?.btnDisagreeTitle   ?? "Disable All"
        let btnPref     = l?.btnPreferenceTitle ?? "Cookie settings"

        let container = UIView()
        container.backgroundColor = c.bg
        container.layer.cornerRadius = dialogRadius
        if tmpl != "dialog" {
            container.layer.cornerRadius = sheetRadius
            container.layer.maskedCorners = position == "top"
                ? [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        if tmpl == "bottom_sheet", layout == "rounded" {
            let handle = UIView()
            handle.backgroundColor = UIColor(white: 0.8, alpha: 1)
            handle.layer.cornerRadius = 2
            handle.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                handle.widthAnchor.constraint(equalToConstant: 32),
                handle.heightAnchor.constraint(equalToConstant: 4),
            ])
            let wrap = UIView()
            wrap.translatesAutoresizingMaskIntoConstraints = false
            wrap.addSubview(handle)
            NSLayoutConstraint.activate([
                handle.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
                handle.topAnchor.constraint(equalTo: wrap.topAnchor),
                handle.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            ])
            stack.addArrangedSubview(wrap)
            stack.setCustomSpacing(6, after: wrap)
        }

        if tmpl != "popup" {
            let titleLabel = makeLabel(titleText, size: titleFs, color: color(payload.banner?.titleTextColor ?? "#1a1a1a"), bold: true, lines: 0)
            stack.addArrangedSubview(titleLabel)
            stack.setCustomSpacing(4, after: titleLabel)
        }

        let bodyLabel = makeLabel(bodyText, size: fs, color: c.body, alpha: 0.9, lines: 0)
        stack.addArrangedSubview(bodyLabel)
        stack.setCustomSpacing(tmpl == "dialog" ? 8 : 7, after: bodyLabel)

        if tmpl == "bottom_sheet" {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 4

            if allowReject {
                let declineBtn = makeRowButton(btnDecline, bg: c.decline, fg: c.declineText) { [weak self] in
                    self?.save(value: "disagree", pref: false, stat: false, mkt: false)
                }
                row.addArrangedSubview(declineBtn)
            }

            let agreeBtn = makeRowButton(btnAgree, bg: c.agree, fg: c.agreeText) { [weak self] in
                self?.save(value: "agree", pref: true, stat: true, mkt: true)
            }
            row.addArrangedSubview(agreeBtn)
            stack.addArrangedSubview(row)
            stack.setCustomSpacing(4, after: row)

            let prefBtn = makeBtn(btnPref, bg: .clear, fg: c.pref, outline: true) { [weak self] in
                self?.badgeTimeoutWorkItem?.cancel()
                self?.isShowingPreferences = true
                self?.refreshUI()
            }
            stack.addArrangedSubview(prefBtn)
        } else {
            let agreeBg = isStroke ? UIColor.clear : c.agree
            let agreeFg = isStroke ? c.agree : c.agreeText
            let agreeBtn = makeBtn(btnAgree, bg: agreeBg, fg: agreeFg, outline: isStroke) { [weak self] in
                self?.save(value: "agree", pref: true, stat: true, mkt: true)
            }
            stack.addArrangedSubview(agreeBtn)

            if allowReject {
                let declineBtn = makeBtn(btnDecline, bg: c.decline, fg: c.declineText) { [weak self] in
                    self?.save(value: "disagree", pref: false, stat: false, mkt: false)
                }
                stack.addArrangedSubview(declineBtn)
            }

            let prefBtn = makeBtn(btnPref, bg: .clear, fg: c.pref, outline: true) { [weak self] in
                self?.badgeTimeoutWorkItem?.cancel()
                self?.isShowingPreferences = true
                self?.refreshUI()
            }
            stack.addArrangedSubview(prefBtn)
        }

        if poweredBy, tmpl != "dialog" {
            let pw = makeLabel("Powered by Seers", size: fs * 0.7, color: UIColor(white: 0.67, alpha: 1))
            pw.textAlignment = .center
            stack.addArrangedSubview(pw)
        }

        var constraints = [
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
        ]

        if tmpl == "dialog" {
            constraints += [
                container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.88),
                stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            ]
        } else {
            constraints += [
                container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                position == "top"
                    ? container.topAnchor.constraint(equalTo: view.topAnchor)
                    : container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                stack.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupBadge() {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Open cookie settings"
        button.addAction(UIAction { [weak self] _ in
            self?.reopenBannerFromBadge()
        }, for: .touchUpInside)
        view.addSubview(button)
        badgeButton = button

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)

        if let customBadgeURL {
            seersLoadRemoteImage(customBadgeURL) { image in
                imageView.image = image ?? seersDefaultBadgeImage()
            }
        } else {
            imageView.image = seersDefaultBadgeImage()
        }

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34),
            imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: button.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])

        (view as? SeersPassthroughView)?.passthroughViews = [button]
    }

    private func makeRemoteImageView(url: String, height: CGFloat) -> UIImageView? {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        seersLoadRemoteImage(url) { image in
            imageView.image = image
        }
        return imageView
    }

    private func makeRowButton(_ title: String, bg: UIColor, fg: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = makeBtn(title, bg: bg, fg: fg, action: action)
        button.titleLabel?.font = .systemFont(ofSize: fs, weight: .semibold)
        return button
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

        // ── Header row: logo left, close right ──
        let closeRow = UIStackView()
        closeRow.axis = .horizontal
        closeRow.alignment = .center
        closeRow.spacing = 8

        if let logoView = makeRemoteImageView(url: logoURL, height: 28), showLogo {
            logoView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            closeRow.addArrangedSubview(logoView)
        } else {
            closeRow.addArrangedSubview(UIView())
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        closeRow.addArrangedSubview(spacer)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(c.body, for: .normal)
        closeBtn.titleLabel?.font = .boldSystemFont(ofSize: fs)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeRow.addArrangedSubview(closeBtn)
        NSLayoutConstraint.activate([
            closeRow.heightAnchor.constraint(equalToConstant: 28),
        ])
        closeBtn.addAction(UIAction { [weak self] _ in
            self?.isShowingPreferences = false
            self?.refreshUI()
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
                self?.save(value: "agree", pref: true, stat: true, mkt: true)
        })
        content.setCustomSpacing(4, after: content.arrangedSubviews.last!)

        // ── Disable All ──
        content.addArrangedSubview(makePrefActionBtn(
            l?.btnDisagreeTitle ?? "Disable All",
            bg: color("#1a1a2e"), fg: .white) { [weak self] in
                self?.save(value: "disagree", pref: false, stat: false, mkt: false)
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
                self.save(value: "custom", pref: self.prefOn, stat: self.statOn, mkt: self.mktOn)
        }
        saveBtn.accessibilityLabel = l?.btnSaveMyChoices ?? "Save my choices"
        saveBtn.accessibilityHint  = "Saves your cookie preferences and closes the panel"
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
            sw.accessibilityLabel = cat.label
            sw.accessibilityHint  = "Double tap to toggle \(cat.label) cookies"
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

    private func save(value: String, pref: Bool, stat: Bool, mkt: Bool) {
        SeersCMP.saveConsent(value: value, preferences: pref, statistics: stat, marketing: mkt)
        showBadgeOnly()
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
    public let defaultLanguage: String?
    public let preferencesChecked: Bool; public let statisticsChecked: Bool; public let targetingChecked: Bool
    public let allowReject: Bool; public let poweredBy: Bool
    public let mobileTemplate: String?; public let regionSelection: Int
    public let hasBadge: Bool; public let badgeLink: String?; public let badgeStatus: String?
    public let logoLink: String?; public let logoStatus: String?; public let bannerTimeout: Int
    public let enableIabTcf: Bool; public let applyGoogleConsent: Bool
    public let appleAtt: Bool; public let googlePlayDisclosure: Bool; public let universalOptOut: Bool
    public let enableGpp: Bool; public let microsoftClarityConsent: Bool; public let metaSdkConsent: Bool
    public let microsoftAdsConsent: Bool; public let amazonAdsConsent: Bool
    enum CodingKeys: String, CodingKey {
        case regionDetection = "region_detection"; case agreementExpire = "agreement_expire"
        case defaultLanguage = "default_language"
        case preferencesChecked = "preferences_checked"; case statisticsChecked = "statistics_checked"
        case targetingChecked = "targeting_checked"; case allowReject = "allow_reject"
        case poweredBy = "powered_by"; case mobileTemplate = "mobile_template"
        case regionSelection = "region_selection"
        case hasBadge = "has_badge"; case badgeLink = "badge_link"; case badgeStatus = "badge_status"
        case logoLink = "logo_link"; case logoStatus = "logo_status"; case bannerTimeout = "banner_timeout"
        case enableIabTcf = "enable_iab_tcf"; case applyGoogleConsent = "apply_google_consent"
        case appleAtt = "apple_att"; case googlePlayDisclosure = "google_play_disclosure"; case universalOptOut = "universal_opt_out"
        case enableGpp = "enable_gpp"; case microsoftClarityConsent = "microsoft_clarity_consent"; case metaSdkConsent = "meta_sdk_consent"
        case microsoftAdsConsent = "microsoft_ads_consent"; case amazonAdsConsent = "amazon_ads_consent"
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        regionDetection  = (try? c.decode(Bool.self, forKey: .regionDetection)) ?? false
        agreementExpire  = (try? c.decode(Int.self,  forKey: .agreementExpire)) ?? 365
        defaultLanguage  = try? c.decode(String.self, forKey: .defaultLanguage)
        if let value = try? c.decode(Bool.self, forKey: .preferencesChecked) {
            preferencesChecked = value
        } else if let value = try? c.decode(Int.self, forKey: .preferencesChecked) {
            preferencesChecked = value == 1
        } else if let value = try? c.decode(String.self, forKey: .preferencesChecked) {
            preferencesChecked = value == "1" || value.lowercased() == "true"
        } else {
            preferencesChecked = false
        }
        if let value = try? c.decode(Bool.self, forKey: .statisticsChecked) {
            statisticsChecked = value
        } else if let value = try? c.decode(Int.self, forKey: .statisticsChecked) {
            statisticsChecked = value == 1
        } else if let value = try? c.decode(String.self, forKey: .statisticsChecked) {
            statisticsChecked = value == "1" || value.lowercased() == "true"
        } else {
            statisticsChecked = false
        }
        if let value = try? c.decode(Bool.self, forKey: .targetingChecked) {
            targetingChecked = value
        } else if let value = try? c.decode(Int.self, forKey: .targetingChecked) {
            targetingChecked = value == 1
        } else if let value = try? c.decode(String.self, forKey: .targetingChecked) {
            targetingChecked = value == "1" || value.lowercased() == "true"
        } else {
            targetingChecked = false
        }
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
        if let value = try? c.decode(Bool.self, forKey: .hasBadge) {
            hasBadge = value
        } else if let value = try? c.decode(Int.self, forKey: .hasBadge) {
            hasBadge = value == 1
        } else if let value = try? c.decode(String.self, forKey: .hasBadge) {
            hasBadge = value == "1" || value.lowercased() == "true"
        } else {
            hasBadge = false
        }
        badgeLink = try? c.decode(String.self, forKey: .badgeLink)
        badgeStatus = try? c.decode(String.self, forKey: .badgeStatus)
        logoLink = try? c.decode(String.self, forKey: .logoLink)
        logoStatus = try? c.decode(String.self, forKey: .logoStatus)
        if let value = try? c.decode(Int.self, forKey: .bannerTimeout) {
            bannerTimeout = value
        } else if let value = try? c.decode(String.self, forKey: .bannerTimeout), let parsed = Int(value) {
            bannerTimeout = parsed
        } else {
            bannerTimeout = 0
        }
        enableIabTcf = (try? c.decode(Bool.self, forKey: .enableIabTcf)) ?? false
        applyGoogleConsent = (try? c.decode(Bool.self, forKey: .applyGoogleConsent)) ?? false
        appleAtt = (try? c.decode(Bool.self, forKey: .appleAtt)) ?? false
        googlePlayDisclosure = (try? c.decode(Bool.self, forKey: .googlePlayDisclosure)) ?? false
        universalOptOut = (try? c.decode(Bool.self, forKey: .universalOptOut)) ?? false
        enableGpp = (try? c.decode(Bool.self, forKey: .enableGpp)) ?? false
        microsoftClarityConsent = (try? c.decode(Bool.self, forKey: .microsoftClarityConsent)) ?? false
        metaSdkConsent = (try? c.decode(Bool.self, forKey: .metaSdkConsent)) ?? false
        microsoftAdsConsent = (try? c.decode(Bool.self, forKey: .microsoftAdsConsent)) ?? false
        amazonAdsConsent = (try? c.decode(Bool.self, forKey: .amazonAdsConsent)) ?? false
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
    public let eligible: Bool?
    public let regulation: String?
    public let regionSelection: Int?
    public let data: SeersGeoData?
    enum CodingKeys: String, CodingKey {
        case eligible, regulation, data
        case regionSelection = "region_selection"
    }
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
    public let privacyFrameworks: [String: Any]
    public let blockList: SeersBlockList; public let regulation: String?; public let sdkKey: String
}
