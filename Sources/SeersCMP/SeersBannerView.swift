import Combine
import SwiftUI

/// Drop-in SwiftUI consent banner.
/// Add to your root view:
///
///     ContentView()
///         .seersBanner(settingsId: "YOUR_SDK_KEY")
///
public struct SeersBannerView: View {

    let payload: SeersBannerPayload
    @Binding var isPresented: Bool
    @State private var showPreferences = false
    @State private var showBanner = true
    @State private var showBadge = false
    @State private var badgeWorkItem: DispatchWorkItem?

    private var dialogue:  SeersCMPDialogue?  { payload.dialogue }
    private var banner:    SeersCMPBanner?    { payload.banner }
    private var lang:      SeersCMPLanguage?  { payload.language }

    private var bgColor:      Color { Color(hex: banner?.bannerBgColor      ?? "#ffffff") }
    private var agreeColor:   Color { Color(hex: banner?.agreeBtnColor      ?? "#3b6ef8") }
    private var agreeText:    Color { Color(hex: banner?.agreeTextColor     ?? "#ffffff") }
    private var declineColor: Color { Color(hex: banner?.disagreeBtnColor   ?? "#1a1a2e") }
    private var declineText:  Color { Color(hex: banner?.disagreeTextColor  ?? "#ffffff") }
    // prefFullStyle uses body_text_color for colour and border — matches Flutter _prefClr => _bodyClr
    private var bodyColor:    Color { Color(hex: banner?.bodyTextColor      ?? "#1a1a1a") }
    private var prefText:     Color { bodyColor }

    // Font size — read from dashboard exactly like Flutter
    private var fs: CGFloat        { min(max(CGFloat(Float(banner?.fontSize ?? "12") ?? 12), 10), 16) }
    private var titleFs: CGFloat   { fs + 2 }   // headings = fs + 2
    private var catNameFs: CGFloat { fs + 1 }   // category names = fs + 1
    private var catBodyFs: CGFloat { fs - 1 }   // category desc = fs - 1
    private var selectedFontName: String? {
        let value = (banner?.fontStyle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty || value == "none" || value == "inherit" { return nil }
        switch value {
        case "arial", "inter", "spezia", "sans-serif": return "Arial"
        case "serif": return "Times New Roman"
        case "monospace": return "Menlo"
        case "cursive": return "Snell Roundhand"
        case "fantasy": return "Papyrus"
        default: return value
        }
    }
    private func bannerFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let selectedFontName { return .custom(selectedFontName, size: size).weight(weight) }
        return .system(size: size, weight: weight)
    }

    // Button radius — matches Flutter _btnR
    private var btnRadius: CGFloat {
        let t = banner?.buttonType ?? "default"
        if t.contains("rounded") { return 20 }
        if t.contains("flat")    { return 0  }
        return 6
    }
    private var isStroke: Bool { (banner?.buttonType ?? "").contains("stroke") }
    private var hasBadge: Bool { dialogue?.hasBadge ?? false }
    private var bannerTimeout: Int { dialogue?.bannerTimeout ?? 0 }
    private var showLogo: Bool { (dialogue?.logoStatus ?? "default") != "none" }
    private var logoURL: String { dialogue?.logoLink ?? seersDefaultLogoURL }
    private var customBadgeURL: String? {
        guard dialogue?.badgeStatus == "custom" else { return nil }
        return dialogue?.badgeLink
    }

    public var body: some View {
        ZStack(alignment: position == "top" ? .top : .bottom) {
            if showPreferences || showBanner {
                if showPreferences {
                    SeersPreferencesView(
                        payload: payload,
                        showPreferences: $showPreferences,
                        onSave: saveConsent
                    )
                    .transition(.move(edge: .bottom))
                } else if mobileTemplate == "dialog" {
                    dialogBanner
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if mobileTemplate == "bottom_sheet" {
                    bottomSheetBanner
                        .transition(.move(edge: position == "top" ? .top : .bottom))
                } else {
                    popupBanner
                        .transition(.move(edge: position == "top" ? .top : .bottom))
                }
            }

            if showBadge && hasBadge {
                badgeOverlay
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPreferences)
        .onDisappear { badgeWorkItem?.cancel() }
    }

    // ── Popup — 3 stacked buttons, no title ──
    private var popupBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(lang?.body ?? "We use cookies to personalize content and ads, to provide social media features and to analyze our traffic.")
                    .font(bannerFont(size: fs))
                    .foregroundColor(bodyColor)
                    .lineSpacing(fs * 0.42)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)

                primaryBtn(lang?.btnAgreeTitle ?? "Allow All") { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }
                if dialogue?.allowReject ?? true {
                    darkBtn(lang?.btnDisagreeTitle ?? "Disable All") { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }
                }
                outlineBtn(lang?.btnPreferenceTitle ?? "Cookie settings") {
                    badgeWorkItem?.cancel()
                    withAnimation { showPreferences = true }
                }

                if dialogue?.poweredBy ?? true {
                    Text("Powered by Seers")
                        .font(bannerFont(size: fs * 0.7))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(12)
            .background(bgColor)
            .cornerRadius(12, corners: position == "top" ? [.bottomLeft, .bottomRight] : [.topLeft, .topRight])
        }
    }

    // ── Bottom Sheet — handle + title + body + row buttons + pref full ──
    private var bottomSheetBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Handle (layout=rounded only)
                if (banner?.layout ?? "default") == "rounded" {
                    Capsule()
                        .fill(Color(hex: "#cccccc"))
                        .frame(width: 32, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                }
                Text(lang?.title ?? "We use cookies")
                    .font(bannerFont(size: titleFs, weight: .bold))
                    .foregroundColor(Color(hex: banner?.titleTextColor ?? "#1a1a1a"))
                    .padding(.bottom, 4)
                Text(lang?.body ?? "We use cookies to improve your experience.")
                    .font(bannerFont(size: fs))
                    .foregroundColor(bodyColor)
                    .lineSpacing(fs * 0.42)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 7)

                // btn-row-primary: btn-item padding:4px, font-weight:600
                HStack(spacing: 4) {
                    if dialogue?.allowReject ?? true {
                        Button(action: { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }) {
                            Text(lang?.btnDisagreeTitle ?? "Decline")
                                .font(bannerFont(size: fs, weight: .semibold))
                                .foregroundColor(declineText)
                                .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                                .background(declineColor).cornerRadius(btnRadius)
                        }
                    }
                    Button(action: { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }) {
                        Text(lang?.btnAgreeTitle ?? "Accept All")
                            .font(bannerFont(size: fs, weight: .semibold))
                            .foregroundColor(agreeText)
                            .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                            .background(agreeColor).cornerRadius(btnRadius)
                    }
                }
                .padding(.bottom, 4)

                // btn-pref-full: padding:4px 6px, margin-bottom:3px, border:1px, font-weight:600
                prefFullBtn(lang?.btnPreferenceTitle ?? "Manage Preferences") {
                    badgeWorkItem?.cancel()
                    withAnimation { showPreferences = true }
                }

                if dialogue?.poweredBy ?? true {
                    Text("Powered by Seers")
                        .font(bannerFont(size: fs * 0.7)).foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(12)
            .background(bgColor)
            .cornerRadius(14, corners: position == "top" ? [.bottomLeft, .bottomRight] : [.topLeft, .topRight])
        }
    }

    // ── Dialog — centered modal ──
    private var dialogBanner: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lang?.title ?? "We use cookies")
                .font(bannerFont(size: titleFs, weight: .bold))
                .foregroundColor(Color(hex: banner?.titleTextColor ?? "#1a1a1a"))
            Text(lang?.body ?? "We use cookies to improve your experience.")
                .font(bannerFont(size: fs)).foregroundColor(bodyColor)
                .lineSpacing(fs * 0.42)
                .fixedSize(horizontal: false, vertical: true)
            primaryBtn(lang?.btnAgreeTitle ?? "Allow All") { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }
            if dialogue?.allowReject ?? true {
                darkBtn(lang?.btnDisagreeTitle ?? "Disable All") { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }
            }
            outlineBtn(lang?.btnPreferenceTitle ?? "Cookie settings") {
                badgeWorkItem?.cancel()
                withAnimation { showPreferences = true }
            }
        }
        .padding(12)
        .background(bgColor)
        .cornerRadius(dialogRadius)
        .shadow(color: .black.opacity(0.22), radius: 24)
        .frame(width: UIScreen.main.bounds.width * 0.88)
    }

    private var logoBlock: some View {
        SeersRemoteImageView(url: logoURL)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .padding(.bottom, 6)
    }

    private var badgeOverlay: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack {
                    Button(action: reopenFromBadge) {
                        badgeArtwork
                    }
                    Spacer()
                }
            }
            .padding(.leading, 12)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var badgeArtwork: some View {
        if let customBadgeURL {
            SeersRemoteImageView(url: customBadgeURL, fallback: seersDefaultBadgeImage())
                .frame(width: 34, height: 34)
        } else if let uiImage = seersDefaultBadgeImage() {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
        }
    }

    // ── Shared button builders ──
    // btn-pref-full: padding:4px 6px, margin-bottom:3px, border:1px, font-weight:600
    private func prefFullBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(bannerFont(size: fs, weight: .semibold)).foregroundColor(prefText)
                .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                .overlay(RoundedRectangle(cornerRadius: btnRadius).stroke(prefText, lineWidth: 1))
        }
        .padding(.bottom, 3)
    }

    // stk-outline: padding:5px 8px, no margin-bottom (always last), border:1.5px, font-weight:700
    private func outlineBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(bannerFont(size: fs, weight: .bold)).foregroundColor(prefText)
                .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                .overlay(RoundedRectangle(cornerRadius: btnRadius).stroke(prefText, lineWidth: 1.5))
        }
    }

    // stk-dark: padding:5px 8px, margin-bottom:5px, font-weight:700
    private func darkBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(bannerFont(size: fs, weight: .bold)).foregroundColor(declineText)
                .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                .background(declineColor).cornerRadius(btnRadius)
        }
        .padding(.bottom, 5)
    }

    // stk-primary: padding:5px 8px, margin-bottom:5px, font-weight:700
    private func primaryBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(bannerFont(size: fs, weight: .bold))
                .foregroundColor(isStroke ? agreeColor : agreeText)
                .frame(maxWidth: .infinity, minHeight: 32).padding(.vertical, 5).padding(.horizontal, 8)
                .background(isStroke ? Color.clear : agreeColor).cornerRadius(btnRadius)
                .overlay(isStroke ? RoundedRectangle(cornerRadius: btnRadius).stroke(agreeColor, lineWidth: 1) : nil)
        }
        .padding(.bottom, 5)
    }

    // ── Helpers ──
    private var mobileTemplate: String { dialogue?.mobileTemplate ?? "popup" }
    private var position: String       { banner?.position ?? "bottom" }

    private var dialogRadius: CGFloat {
        let lay = banner?.layout ?? "default"
        if lay == "rounded" { return 20 }
        if lay == "flat"    { return 0  }
        return 10
    }

    private func saveConsent(value: String, pref: Bool, stat: Bool, mkt: Bool) {
        badgeWorkItem?.cancel()
        SeersCMP.saveConsent(value: value, preferences: pref, statistics: stat, marketing: mkt)
        if hasBadge {
            withAnimation {
                showPreferences = false
                showBanner = false
                showBadge = true
            }
        } else {
            withAnimation { isPresented = false }
        }
    }

    private func reopenFromBadge() {
        badgeWorkItem?.cancel()
        withAnimation {
            showBadge = false
            showBanner = true
        }

        guard hasBadge, bannerTimeout > 0 else { return }
        let workItem = DispatchWorkItem {
            withAnimation {
                showPreferences = false
                showBanner = false
                showBadge = true
            }
        }
        badgeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(bannerTimeout), execute: workItem)
    }
}

// MARK: - Preferences View

final class SeersRemoteImageLoader: ObservableObject {
    @Published var image: UIImage?

    init(url: String?, fallback: UIImage? = nil) {
        image = fallback
        seersLoadRemoteImage(url) { [weak self] remoteImage in
            if let remoteImage {
                self?.image = remoteImage
            }
        }
    }
}

struct SeersRemoteImageView: View {
    @ObservedObject private var loader: SeersRemoteImageLoader

    init(url: String?, fallback: UIImage? = nil) {
        loader = SeersRemoteImageLoader(url: url, fallback: fallback)
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
    }
}

struct SeersPreferencesView: View {

    let payload: SeersBannerPayload
    @Binding var showPreferences: Bool
    let onSave: (String, Bool, Bool, Bool) -> Void

    @State private var prefOn  = false
    @State private var statOn  = false
    @State private var mktOn   = false
    @State private var expanded: Set<String> = []

    init(payload: SeersBannerPayload,
         showPreferences: Binding<Bool>,
         onSave: @escaping (String, Bool, Bool, Bool) -> Void) {
        self.payload = payload
        self._showPreferences = showPreferences
        self.onSave = onSave
        self._prefOn = State(initialValue: payload.dialogue?.preferencesChecked ?? false)
        self._statOn = State(initialValue: payload.dialogue?.statisticsChecked ?? false)
        self._mktOn = State(initialValue: payload.dialogue?.targetingChecked ?? false)
    }

    private var lang:   SeersCMPLanguage? { payload.language }
    private var banner: SeersCMPBanner?   { payload.banner }
    private var accentColor: Color { Color(hex: banner?.agreeBtnColor  ?? "#3b6ef8") }
    private var agreeTextClr: Color { Color(hex: banner?.agreeTextColor ?? "#ffffff") }
    private var bgColor:     Color { Color(hex: banner?.bannerBgColor  ?? "#ffffff") }
    private var textColor:   Color { Color(hex: banner?.bodyTextColor  ?? "#1a1a1a") }
    private var titleColor:  Color { Color(hex: banner?.titleTextColor ?? "#1a1a1a") }
    private var showLogo: Bool { (payload.dialogue?.logoStatus ?? "default") != "none" }
    private var logoURL: String { payload.dialogue?.logoLink ?? seersDefaultLogoURL }

    // Font sizes — same derivation as SeersBannerView
    private var fs:        CGFloat { min(max(CGFloat(Float(banner?.fontSize ?? "12") ?? 12), 10), 16) }
    private var titleFs:   CGFloat { fs + 2 }
    private var catNameFs: CGFloat { fs + 1 }
    private var catBodyFs: CGFloat { fs - 1 }
    private var arrowFs:   CGFloat { (fs * 0.75).rounded() }
    private var prefFs: CGFloat { fs }
    private var prefTitleFs: CGFloat { prefFs + 2 }
    private var prefCatNameFs: CGFloat { prefFs + 1 }
    private var prefCatBodyFs: CGFloat { prefFs - 1 }
    private var prefArrowFs: CGFloat { (prefFs * 0.75).rounded() }
    private var selectedFontName: String? {
        let value = (banner?.fontStyle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty || value == "none" || value == "inherit" { return nil }
        switch value {
        case "arial", "inter", "spezia", "sans-serif": return "Arial"
        case "serif": return "Times New Roman"
        case "monospace": return "Menlo"
        case "cursive": return "Snell Roundhand"
        case "fantasy": return "Papyrus"
        default: return value
        }
    }
    private func bannerFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let selectedFontName { return .custom(selectedFontName, size: size).weight(weight) }
        return .system(size: size, weight: weight)
    }

    var body: some View {
        VStack(spacing: 0) {
            // pref-scroll content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        if showLogo {
                            SeersRemoteImageView(url: logoURL)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 28)
                        } else {
                            Spacer()
                        }
                        Button(action: { withAnimation { showPreferences = false } }) {
                            Text("✕").font(bannerFont(size: prefFs, weight: .bold)).foregroundColor(titleColor)
                        }
                    }
                    .padding(.bottom, 2)

                    // pref-title: font-weight:700, fs+2
                    Text(lang?.aboutCookies ?? "About Our Cookies")
                        .font(bannerFont(size: prefTitleFs, weight: .bold))
                        .foregroundColor(titleColor)
                        .padding(.bottom, 4)

                    // pref-body: fs-1 (catBodyFs), opacity:0.85, line-height:1.4
                    Text(lang?.body ?? "We use cookies to personalize content and ads.")
                        .font(bannerFont(size: prefFs))
                        .foregroundColor(textColor.opacity(0.85))
                        .lineSpacing(prefFs * 0.42)
                        .padding(.bottom, 4)

                    // pref-policy-link: fs, font-weight:600, underline, agree_btn_color
                    Text("Read Cookie Policy ↗")
                        .font(bannerFont(size: prefFs, weight: .semibold))
                        .foregroundColor(accentColor)
                        .underline()
                        .padding(.bottom, 6)

                    // pref-allow-btn: padding:4px 6px, font-weight:700, border-radius:4px
                    Button(action: { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }) {
                        Text(lang?.btnAgreeTitle ?? "Allow All")
                            .font(bannerFont(size: prefFs, weight: .bold))
                            .foregroundColor(agreeTextClr)
                            .frame(maxWidth: .infinity, minHeight: 36).padding(.vertical, 7).padding(.horizontal, 10)
                            .background(accentColor).cornerRadius(6)
                    }
                    .padding(.bottom, 4)

                    // pref-disable-btn: padding:4px 6px, font-weight:700, border-radius:4px
                    Button(action: { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }) {
                        Text(lang?.btnDisagreeTitle ?? "Disable All")
                            .font(bannerFont(size: prefFs, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 36).padding(.vertical, 7).padding(.horizontal, 10)
                            .background(Color(hex: "#1a1a2e")).cornerRadius(6)
                    }
                    .padding(.bottom, 8)

                    // pref-categories: border-top:1px #e0e0e0, padding-top:4px, gap:3px
                    VStack(spacing: 3) {
                        categoryRow(key: "necessary",   label: lang?.necessoryTitle  ?? "Necessary",   isAlwaysActive: true,  isOn: .constant(true))
                        categoryRow(key: "preferences", label: lang?.preferenceTitle ?? "Preferences", isAlwaysActive: false, isOn: $prefOn)
                        categoryRow(key: "statistics",  label: lang?.statisticsTitle ?? "Statistics",  isAlwaysActive: false, isOn: $statOn)
                        categoryRow(key: "marketing",   label: lang?.marketingTitle  ?? "Marketing",   isAlwaysActive: false, isOn: $mktOn)
                    }
                    .padding(.top, 4)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#e0e0e0")), alignment: .top)
                }
                .padding(12)
                .padding(.bottom, 80) // space for sticky footer
            }
        }
        .background(bgColor)
        .overlay(
            // pref-footer: padding:12px, border-top:1px #e0e0e0, box-shadow
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    // pref-save-btn: padding:5px 6px, font-weight:700, border-radius:4px
                    Button(action: { saveConsent(value: "custom", pref: prefOn, stat: statOn, mkt: mktOn) }) {
                        Text(lang?.btnSaveMyChoices ?? "Save my choices")
                            .font(bannerFont(size: prefFs, weight: .bold))
                            .foregroundColor(agreeTextClr)
                            .frame(maxWidth: .infinity, minHeight: 38).padding(.vertical, 7).padding(.horizontal, 10)
                            .background(accentColor).cornerRadius(6)
                    }
                    .padding(12)
                    .background(bgColor)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#e0e0e0")), alignment: .top)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
                }
            }
        )
        .cornerRadius(18, corners: [.topLeft, .topRight])
        .frame(maxHeight: UIScreen.main.bounds.height * 0.92)
    }

    @ViewBuilder
    private func categoryRow(key: String, label: String, isAlwaysActive: Bool, isOn: Binding<Bool>) -> some View {
        // pref-cat-wrap: border:1px #e0e0e0, border-radius:5px
        VStack(spacing: 0) {
            // pref-cat-row: padding:4px 5px
            HStack(spacing: 3) {
                // pref-cat-arrow: arrowFs, rotates 90deg when open
                Text("▶")
                    .font(bannerFont(size: prefArrowFs))
                    .foregroundColor(accentColor)
                    .rotationEffect(.degrees(expanded.contains(key) ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: expanded.contains(key))
                // pref-cat-name: catNameFs (fs+1), font-weight:600
                Text(label)
                    .font(bannerFont(size: prefCatNameFs, weight: .semibold))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isAlwaysActive {
                    // pref-always-active: fs, font-weight:600
                    Text(lang?.alwaysActive ?? "Always Active")
                        .font(bannerFont(size: prefCatBodyFs, weight: .semibold))
                        .foregroundColor(accentColor)
                } else {
                    compactToggle(isOn: isOn)
                }
            }
            .frame(minHeight: 40)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if expanded.contains(key) { expanded.remove(key) } else { expanded.insert(key) }
                }
            }

            // pref-cat-body: padding:3px 7px 4px, catBodyFs (fs-1), opacity:0.8, border-top:1px #f0f0f0
            if expanded.contains(key) {
                Text(descriptionFor(key: key))
                    .font(bannerFont(size: prefCatBodyFs))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineSpacing(prefCatBodyFs * 0.42)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 9)
                    .background(Color.black.opacity(0.02))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#f0f0f0")), alignment: .top)
            }
        }
        .background(bgColor)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#e0e0e0"), lineWidth: 1))
        .cornerRadius(5)
        .clipped()
    }

    private func compactToggle(isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                Capsule()
                    .fill(isOn.wrappedValue ? accentColor : Color(hex: "#cccccc"))
                    .frame(width: 36, height: 20)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .padding(.horizontal, 2)
            }
            .frame(width: 36, height: 20)
        }
        .buttonStyle(.plain)
    }

    private func descriptionFor(key: String) -> String {
        switch key {
        case "necessary":   return lang?.necessoryBody  ?? "Required for the website to function. Cannot be switched off."
        case "preferences": return lang?.preferenceBody ?? "Allow the website to remember choices you make."
        case "statistics":  return lang?.statisticsBody ?? "Help us understand how visitors interact with the website."
        case "marketing":   return lang?.marketingBody  ?? "Used to track visitors and display relevant advertisements."
        default:            return ""
        }
    }

    private func saveConsent(value: String, pref: Bool, stat: Bool, mkt: Bool) {
        withAnimation {
            onSave(value, pref, stat, mkt)
        }
    }
}

// MARK: - View Modifier

struct SeersBannerModifier: ViewModifier {
    let settingsId: String
    @State private var showBanner = false
    @State private var payload: SeersBannerPayload?

    func body(content: Content) -> some View {
        ZStack {
            content
            if showBanner, let p = payload {
                SeersBannerView(payload: p, isPresented: $showBanner)
                    .ignoresSafeArea()
                    .zIndex(999)
            }
        }
        .onAppear {
            SeersCMP.initialize(settingsId: settingsId) { p in
                payload = p
                withAnimation { showBanner = true }
            }
        }
    }
}

public extension View {
    /// Attach Seers consent banner to any view.
    func seersBanner(settingsId: String) -> some View {
        modifier(SeersBannerModifier(settingsId: settingsId))
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
