import ProjectDescription

enum BaseSettings {

    static let appName = "ExampleApp"

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

enum TestAppSettings {

    static let settingsDictionary = SettingsDictionary()
        .merging(BaseSettings.settingsDictionary)

    static let settingsConfigurations: [Configuration] = [.debug(name: "Debug", settings: settingsDictionary),
                                                          .release(name: "Release", settings: settingsDictionary)]

    static let settings = Settings.settings(configurations: settingsConfigurations)
}

let project = Project(
    name: "Primer.io Example App",
    organizationName: "Primer API Ltd",
    targets: [
        Target(
            name: BaseSettings.appName,
            platform: .iOS,
            product: .app,
            bundleId: "com.primerapi.PrimerSDKExample",
            infoPlist: "Info.plist",
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "ExampleApp.entitlements",
            settings: AppSettings.settings
        ),
        Target(
            name: "ExampleAppTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.primerapi.PrimerSDKExampleTests",
            infoPlist: .default,
            sources: ["Tests/Unit Tests/**"],
            dependencies: [
                .target(name: "ExampleApp")
            ],
            settings: TestAppSettings.settings
        ),
        Target(
            name: "ExampleAppUITests",
            platform: .iOS,
            product: .uiTests,
            bundleId: "com.primer.PrimerSDKExample-UITests",
            infoPlist: .default,
            sources: ["Tests/UI Tests/**"],
            dependencies: [
                .target(name: "ExampleApp")
            ],
            settings: TestAppSettings.settings
        )
    ],
    schemes: [
        Scheme(name: BaseSettings.appName,
               shared: true,
               buildAction: .buildAction(targets: [TargetReference(stringLiteral: BaseSettings.appName)]),
               testAction: .targets([TestableTarget(stringLiteral: BaseSettings.appName)]),
               runAction: .runAction(executable: TargetReference(stringLiteral: BaseSettings.appName),
                                     arguments:
                                        Arguments(launchArguments: [
                                            LaunchArgument(name: "-PrimerDebugEnabled", isEnabled: true),
                                            LaunchArgument(name: "-PrimerAnalyticsDebugEnabled", isEnabled: true)
                                        ]
                                                 )
                                    )
              )
    ]
)
