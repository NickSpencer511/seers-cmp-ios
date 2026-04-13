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
    private var fs: CGFloat       { CGFloat(Float(banner?.fontSize ?? "14") ?? 14) }
    private var titleFs: CGFloat  { fs + 2 }

    // Button radius — matches Flutter _btnR
    private var btnRadius: CGFloat {
        let t = banner?.buttonType ?? "default"
        if t.contains("rounded") { return 20 }
        if t.contains("flat")    { return 0  }
        return 6
    }
    private var isStroke: Bool { (banner?.buttonType ?? "").contains("stroke") }

    public var body: some View {
        ZStack(alignment: position == "top" ? .top : .bottom) {
            // Dimmed overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            if showPreferences {
                SeersPreferencesView(
                    payload: payload,
                    isPresented: $isPresented
                )
                .transition(.move(edge: .bottom))
            } else if mobileTemplate == "dialog" {
                // ── DIALOG — centered modal ──
                dialogBanner
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if mobileTemplate == "bottom_sheet" {
                // ── BOTTOM SHEET ──
                bottomSheetBanner
                    .transition(.move(edge: position == "top" ? .top : .bottom))
            } else {
                // ── POPUP (default) ──
                popupBanner
                    .transition(.move(edge: position == "top" ? .top : .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPreferences)
    }

    // ── Popup — 3 stacked buttons, no title ──
    private var popupBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(lang?.body ?? "We use cookies to personalize content and ads, to provide social media features and to analyze our traffic.")
                    .font(.system(size: fs))
                    .foregroundColor(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)

                outlineBtn(lang?.btnPreferenceTitle ?? "Cookie settings") { withAnimation { showPreferences = true } }
                if dialogue?.allowReject ?? true {
                    darkBtn(lang?.btnDisagreeTitle ?? "Disable All") { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }
                }
                primaryBtn(lang?.btnAgreeTitle ?? "Allow All") { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }

                if dialogue?.poweredBy ?? true {
                    Text("Powered by Seers")
                        .font(.system(size: fs * 0.7))
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
                    .font(.system(size: titleFs, weight: .bold))
                    .foregroundColor(Color(hex: banner?.titleTextColor ?? "#1a1a1a"))
                    .padding(.bottom, 4)
                Text(lang?.body ?? "We use cookies to improve your experience.")
                    .font(.system(size: fs))
                    .foregroundColor(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 7)

                // btn-row-primary
                HStack(spacing: 4) {
                    if dialogue?.allowReject ?? true {
                        Button(action: { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }) {
                            Text(lang?.btnDisagreeTitle ?? "Decline")
                                .font(.system(size: fs, weight: .semibold))
                                .foregroundColor(declineText)
                                .frame(maxWidth: .infinity).padding(.vertical, 4)
                                .background(declineColor).cornerRadius(btnRadius)
                        }
                    }
                    Button(action: { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }) {
                        Text(lang?.btnAgreeTitle ?? "Accept All")
                            .font(.system(size: fs, weight: .semibold))
                            .foregroundColor(agreeText)
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                            .background(agreeColor).cornerRadius(btnRadius)
                    }
                }
                .padding(.bottom, 4)

                outlineBtn(lang?.btnPreferenceTitle ?? "Manage Preferences") { withAnimation { showPreferences = true } }

                if dialogue?.poweredBy ?? true {
                    Text("Powered by Seers")
                        .font(.system(size: fs * 0.7)).foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(bgColor)
            .cornerRadius(14, corners: position == "top" ? [.bottomLeft, .bottomRight] : [.topLeft, .topRight])
        }
    }

    // ── Dialog — centered modal ──
    private var dialogBanner: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lang?.title ?? "We use cookies")
                .font(.system(size: titleFs, weight: .bold))
                .foregroundColor(Color(hex: banner?.titleTextColor ?? "#1a1a1a"))
            Text(lang?.body ?? "We use cookies to improve your experience.")
                .font(.system(size: fs)).foregroundColor(bodyColor)
                .fixedSize(horizontal: false, vertical: true)
            outlineBtn(lang?.btnPreferenceTitle ?? "Cookie settings") { withAnimation { showPreferences = true } }
            if dialogue?.allowReject ?? true {
                darkBtn(lang?.btnDisagreeTitle ?? "Disable All") { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }
            }
            primaryBtn(lang?.btnAgreeTitle ?? "Allow All") { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }
        }
        .padding(12)
        .background(bgColor)
        .cornerRadius(dialogRadius)
        .shadow(color: .black.opacity(0.22), radius: 24)
        .frame(width: UIScreen.main.bounds.width * 0.88)
    }

    // ── Shared button builders ──
    private func outlineBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: fs, weight: .semibold)).foregroundColor(prefText)
                .frame(maxWidth: .infinity).padding(.vertical, 5)
                .overlay(RoundedRectangle(cornerRadius: btnRadius).stroke(prefText, lineWidth: 1.5))
        }
    }

    private func darkBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: fs, weight: .semibold)).foregroundColor(declineText)
                .frame(maxWidth: .infinity).padding(.vertical, 5)
                .background(declineColor).cornerRadius(btnRadius)
        }
    }

    private func primaryBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: fs, weight: .semibold))
                .foregroundColor(isStroke ? agreeColor : agreeText)
                .frame(maxWidth: .infinity).padding(.vertical, 5)
                .background(isStroke ? Color.clear : agreeColor).cornerRadius(btnRadius)
                .overlay(isStroke ? RoundedRectangle(cornerRadius: btnRadius).stroke(agreeColor, lineWidth: 1) : nil)
        }
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
        SeersCMP.saveConsent(value: value, preferences: pref, statistics: stat, marketing: mkt)
        withAnimation { isPresented = false }
    }
}

// MARK: - Preferences View

struct SeersPreferencesView: View {

    let payload: SeersBannerPayload
    @Binding var isPresented: Bool

    @State private var prefOn  = true
    @State private var statOn  = false
    @State private var mktOn   = false
    @State private var expanded: Set<String> = []

    private var lang:   SeersCMPLanguage? { payload.language }
    private var banner: SeersCMPBanner?   { payload.banner }
    private var accentColor: Color { Color(hex: banner?.agreeBtnColor ?? "#3b6ef8") }
    private var bgColor:     Color { Color(hex: banner?.bannerBgColor ?? "#ffffff") }
    private var textColor:   Color { Color(hex: banner?.bodyTextColor ?? "#1a1a1a") }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(lang?.aboutCookies ?? "About Our Cookies")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textColor)
                Spacer()
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark")
                        .foregroundColor(textColor)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    // Body
                    Text(lang?.body ?? "We use cookies to personalize content and ads.")
                        .font(.system(size: 12))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    // Allow All
                    Button(action: { saveConsent(value: "agree", pref: true, stat: true, mkt: true) }) {
                        Text(lang?.btnAgreeTitle ?? "Allow All")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: banner?.agreeTextColor ?? "#ffffff"))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(accentColor).cornerRadius(6)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 6)

                    // Disable All
                    Button(action: { saveConsent(value: "disagree", pref: false, stat: false, mkt: false) }) {
                        Text(lang?.btnDisagreeTitle ?? "Disable All")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(Color(hex: "#1a1a2e")).cornerRadius(6)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)

                    Divider().padding(.horizontal, 16)

                    // Category rows
                    categoryRow(key: "necessary",   label: lang?.necessoryTitle  ?? "Necessary",   isAlwaysActive: true,  isOn: .constant(true))
                    categoryRow(key: "preferences", label: lang?.preferenceTitle ?? "Preferences", isAlwaysActive: false, isOn: $prefOn)
                    categoryRow(key: "statistics",  label: lang?.statisticsTitle ?? "Statistics",  isAlwaysActive: false, isOn: $statOn)
                    categoryRow(key: "marketing",   label: lang?.marketingTitle  ?? "Marketing",   isAlwaysActive: false, isOn: $mktOn)
                }
                .padding(.bottom, 80) // space for sticky footer
            }
        }
        .background(bgColor)
        .overlay(
            // Sticky Save my choices footer
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Divider()
                    Button(action: { saveConsent(value: "custom", pref: prefOn, stat: statOn, mkt: mktOn) }) {
                        Text(lang?.btnSaveMyChoices ?? "Save my choices")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: banner?.agreeTextColor ?? "#ffffff"))
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(accentColor).cornerRadius(6)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(bgColor)
                }
            }
        )
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
    }

    @ViewBuilder
    private func categoryRow(key: String, label: String, isAlwaysActive: Bool, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { withAnimation { if expanded.contains(key) { expanded.remove(key) } else { expanded.insert(key) } } }) {
                    HStack(spacing: 8) {
                        Image(systemName: expanded.contains(key) ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .foregroundColor(accentColor).font(.system(size: 16))
                        Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(textColor)
                    }
                }
                Spacer()
                if isAlwaysActive {
                    Text("Always Active").font(.system(size: 11, weight: .semibold)).foregroundColor(accentColor)
                } else {
                    Toggle("", isOn: isOn).labelsHidden().tint(accentColor)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)
            .padding(.horizontal, 12).padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1).padding(.horizontal, 12).padding(.vertical, 3))

            if expanded.contains(key) {
                Text(descriptionFor(key: key))
                    .font(.system(size: 11)).foregroundColor(textColor.opacity(0.7))
                    .padding(.horizontal, 28).padding(.bottom, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
        SeersCMP.saveConsent(value: value, preferences: pref, statistics: stat, marketing: mkt)
        withAnimation { isPresented = false }
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