# SeersCMP iOS SDK

Seers Consent Management Platform SDK for iOS.

## Installation

### Swift Package Manager (Xcode)
1. In Xcode → **File → Add Packages**
2. Enter URL: `https://github.com/NickSpencer511/seers-cmp-ios`
3. Select version `1.0.0`

### CocoaPods
```ruby
pod 'SeersCMP', '~> 1.0'
```

## Usage

```swift
import SeersCMP

@main
struct MyApp: App {
    init() {
        SeersCMP.initialize(settingsId: "YOUR_SETTINGS_ID")
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

Get your **Settings ID** from [seers.ai](https://seers.ai) dashboard → Mobile Apps → Get Code.

## What it does automatically
- ✅ Shows consent banner based on your dashboard settings
- ✅ Detects user region (GDPR / CPRA / none)
- ✅ Blocks trackers until consent is given
- ✅ Saves consent to device
- ✅ Logs consent to your Seers dashboard
