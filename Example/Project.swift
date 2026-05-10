import ProjectDescription

let targetName = "LookInsidePrivateDiscriminatorExample"
let configurations: [Configuration] = [
    .debug(name: "Debug", xcconfig: "Configuration/Development.xcconfig"),
    .release(name: "Release", xcconfig: "Configuration/Release.xcconfig"),
]
let xcconfigManagedSettings: Set<String> = [
    "CODE_SIGN_IDENTITY",
    "CODE_SIGN_STYLE",
    "CODE_SIGNING_ALLOWED",
    "CODE_SIGNING_REQUIRED",
    "CODE_SIGNING_SUPPORTED",
    "DEBUG_INFORMATION_FORMAT",
    "DEVELOPMENT_TEAM",
    "ENABLE_NS_ASSERTIONS",
    "ENABLE_TESTABILITY",
    "ENABLE_USER_SCRIPT_SANDBOXING",
    "IPHONEOS_DEPLOYMENT_TARGET",
    "ONLY_ACTIVE_ARCH",
    "PROVISIONING_PROFILE_SPECIFIER",
    "SDKROOT",
    "SUPPORTS_MACCATALYST",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
    "SWIFT_COMPILATION_MODE",
    "SWIFT_OPTIMIZATION_LEVEL",
    "SWIFT_VERSION",
    "TARGETED_DEVICE_FAMILY",
]

let project = Project(
    name: targetName,
    organizationName: "LookInside",
    packages: [
        .remote(
            url: "https://github.com/LookInsideApp/LookInside-Release.git",
            requirement: .exact("0.2.2")
        ),
    ],
    settings: .settings(
        configurations: configurations,
        defaultSettings: .recommended(excluding: xcconfigManagedSettings),
        defaultConfiguration: "Debug"
    ),
    targets: [
        .target(
            name: targetName,
            destinations: [.iPhone, .iPad],
            product: .app,
            productName: targetName,
            bundleId: "$(LOOKINSIDE_PRIVATE_DISCRIMINATOR_EXAMPLE_BUNDLE_ID)",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Configuration/Info.plist"),
            buildableFolders: [
                "LookInsidePrivateDiscriminatorExample/Sources",
                "LookInsidePrivateDiscriminatorExample/Resources",
            ],
            dependencies: [
                .package(product: "LookInsideServer"),
            ],
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
    ],
    schemes: [
        .scheme(
            name: targetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(targetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(targetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ],
    additionalFiles: [
        "Configuration/Base.xcconfig",
    ]
)
