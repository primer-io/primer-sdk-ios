import ProjectDescription

enum BaseSettings {

    static let settingsDictionary: [String: SettingValue] = [
        "DEVELOPMENT_TEAM": .string("N8UN9TR5DY")
    ]
}

enum AppSettings {

    static let settingsDictionary = SettingsDictionary()
        .merging(BaseSettings.settingsDictionary)
        .merging(["CODE_SIGN_IDENTITY": .string("Apple Development: DX Primer (8B5K7AGMS8)")])
        .manualCodeSigning(provisioningProfileSpecifier: "match Development com.primerapi.PrimerSDKExample")

    static let settingsConfigurations: [Configuration] = [.debug(name: "Debug", settings: settingsDictionary),
                                                          .release(name: "Release", settings: settingsDictionary)]

    static let settings = Settings.settings(configurations: settingsConfigurations)
}

let project = Project(
    name: "Primer.io Example App",
    organizationName: "Primer API Ltd",
    targets: [
        Target(
            name: "ExampleApp",
            platform: .iOS,
            product: .app,
            bundleId: "com.primerapi.PrimerSDKExample",
            infoPlist: "Info.plist",
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "ExampleApp.entitlements",
            settings: AppSettings.settings
        )
    ]
)
