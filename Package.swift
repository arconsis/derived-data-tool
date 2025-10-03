// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension PackageDescription.Target {
    static let app = TargetDefinition(name: "App", path: nil)
    static let archive = TargetDefinition(name: "Archive", path: "Sources/Command/Archive")
    static let build = TargetDefinition(name: "Build", path: "Sources/Command/Build")
    static let config = TargetDefinition(name: "Config", path: "Sources/Command/Config")
    static let compare = TargetDefinition(name: "Compare", path: "Sources/Command/Compare")
    static let coverage = TargetDefinition(name: "Coverage", path: "Sources/Command/Coverage")
    static let dependencyInjection = TargetDefinition(name: "DependencyInjection", path: "Sources/DependencyInjection")
    static let helper = TargetDefinition(name: "Helper", path: "Sources/Helper")
    static let migrate = TargetDefinition(name: "Migrate", path: "Sources/Command/Migrate")
    static let prototype = TargetDefinition(name: "Prototype", path: "Sources/Command/Prototype")
    static let report = TargetDefinition(name: "Report", path: "Sources/Command/Report")
}

enum ExternalDependencies {
    static let argumentParser = Dependency(package: .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
                                           target: .product(name: "ArgumentParser", package: "swift-argument-parser"))

    static let swiftHTMLParser = Dependency(package: .package(url: "https://github.com/binarybirds/swift-html.git", from: "1.6.0"),
                                            target: .product(name: "SwiftHtml", package: "swift-html"))

    static let yams = Dependency(package: .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
                                 target: .product(name: "Yams", package: "yams"))

    static let globPattern = Dependency(package: .package(url: "https://github.com/ChimeHQ/GlobPattern.git", from: "0.1.1"),
                                        target: .product(name: "GlobPattern", package: "GlobPattern"))

    static let asyncAlgorithms = Dependency(package: .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
                                            target: .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"))

    static let swiftSlash = Dependency(package: .package(url: "https://github.com/tannerdsilva/SwiftSlash", from: "3.4.0"),
                                       target: .product(name: "SwiftSlash", package: "SwiftSlash"))

    static let fluent = Dependency(package: .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0"),
                                   target: .product(name: "HummingbirdFluent", package: "hummingbird-fluent"))

    static let sqlDriver = Dependency(package: .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
                                      target: .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"))
}

typealias MyPackage = PackageDescription.Target

let package = Package(
    name: "CodeCoverage",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "derived-data-tool", targets: [MyPackage.app.name])
    ],
    dependencies: [
        ExternalDependencies.argumentParser.package,
        ExternalDependencies.asyncAlgorithms.package,
        ExternalDependencies.fluent.package,
        ExternalDependencies.sqlDriver.package,
        ExternalDependencies.globPattern.package,
        ExternalDependencies.swiftHTMLParser.package,
        ExternalDependencies.swiftSlash.package,
        ExternalDependencies.yams.package,
    ],
    targets: [
        .executableTarget(
            name: MyPackage.app.name,
            dependencies: [
                ExternalDependencies.argumentParser.target,
                .archive(),
                .coverage(),
                .compare(),
                .dependencyInjection(),
                .prototype(),
                .migrate(),
                .build(),
                .config(),
                .report(),
            ],
            path: MyPackage.app.path
        ),

        // MARK: SubCommands

        MyPackage.coverage.toTarget(
            dependencies: [
                ExternalDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ],
            resources: [
                .process("Resources/input.json"),
            ]
        ),
        MyPackage.compare.toTarget(
            dependencies: [
                ExternalDependencies.argumentParser.target,
                .dependencyInjection(),
                .shared(),
                .helper(),
            ]
        ),
        MyPackage.build.toTarget(
            dependencies: [
                ExternalDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.config.toTarget(dependencies: [
            ExternalDependencies.argumentParser.target,
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]
        ),
        MyPackage.report.toTarget(dependencies: [
            ExternalDependencies.argumentParser.target,
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]),
        MyPackage.prototype.toTarget(
            dependencies: [
                ExternalDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.archive.toTarget(dependencies: [
            ExternalDependencies.argumentParser.target,
            .helper(),
        ]),

        MyPackage.migrate.toTarget(dependencies: [
            ExternalDependencies.argumentParser.target,
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]),

        // MARK: HELPER
        MyPackage.helper.toTarget(
            dependencies: [
                ExternalDependencies.asyncAlgorithms.target,
                ExternalDependencies.fluent.target,
                ExternalDependencies.sqlDriver.target,
                ExternalDependencies.globPattern.target,
                ExternalDependencies.swiftHTMLParser.target,
                ExternalDependencies.swiftSlash.target,
                ExternalDependencies.yams.target,
                .dependencyInjection(),
                .shared(),
            ],
            resources: [
                .process("Resources/ccConfig.yml"),
            ]
        ),
        MyPackage.dependencyInjection.toTarget(),

        // MARK: Shared

        .target(name: "Shared"),

        // MARK: TESTS

        MyPackage.app.toTestTarget(
            dependencies: [
                "App",
            ]
        ),
        .testTarget(
            name: "SubCommandTests",
            dependencies: [
                .coverage(),
                .compare(),
                .build(),
                .config(),
            ],
            path: "Tests/SubCommandTests"
        ),
        .testTarget(
            name: "HelperTests",
            dependencies: [
                .helper(),
            ],
            path: "Tests/HelperTests",
            resources: [
                .process("Resources/TestData.json"),
            ]
        ),

        // MARK: MOCKS

        .target(name: "AppMocks", path: "Mocks/AppMocks"),
        .target(name: "GenerateMocks", path: "Mocks/GenerateMocks"),
        .target(
            name: "CompareMocks",
            dependencies: [
                .compare(),
                .shared(),
            ],
            path: "Mocks/CompareMocks"
        ),
    ]
)

extension PackageDescription.Target.Dependency {
    // MARK: Internal packages

    /// Helper-classes: includes all helpers
    static func helper() -> Target.Dependency {
        Target.Dependency.target(name: "Helper")
    }

    /// DependencyInjection logic
    static func dependencyInjection() -> Target.Dependency {
        Target.Dependency.target(name: "DependencyInjection")
    }

    /// Shared-DTOs: includes all `objects` that are needed in different packages
    static func shared() -> Target.Dependency {
        Target.Dependency.target(name: "Shared")
    }

    // MARK: Executable Commands

    /// SubCommand: `coverage`: command to generate coverage report
    static func coverage() -> Target.Dependency {
        Target.Dependency.target(name: "Coverage")
    }

    /// SubCommand: `compare`: command to compare coverage reports
    static func compare() -> Target.Dependency {
        Target.Dependency.target(name: "Compare")
    }

    /// SubCommand: `build`: command to compare coverage reports
    static func build() -> Target.Dependency {
        Target.Dependency.target(name: "Build")
    }

    /// SubCommand: `config`: command to compare coverage reports
    static func config() -> Target.Dependency {
        Target.Dependency.target(name: "Config")
    }

    /// SubCommand: `prototype`: command to test new stuff easily
    static func prototype() -> Target.Dependency {
        Target.Dependency.target(name: "Prototype")
    }

    /// SubCommand: `report`: command to test new stuff easily
    static func report() -> Target.Dependency {
        Target.Dependency.target(name: "Report")
    }

    /// SubCommand: `archiveTester`: command to test new stuff easily
    static func archive() -> Target.Dependency {
        Target.Dependency.target(name: "Archive")
    }

    static func migrate() -> Target.Dependency {
        Target.Dependency.target(name: "Migrate")
    }
}

struct TargetDefinition {
    let name: String
    var path: String?

    func toTarget(
        dependencies: [Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [Resource]? = nil,
        publicHeadersPath: String? = nil,
        cSettings: [CSetting]? = nil,
        cxxSettings: [CXXSetting]? = nil,
        swiftSettings: [SwiftSetting]? = nil,
        linkerSettings: [LinkerSetting]? = nil,
        plugins: [Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        .target(name: name,
                dependencies: dependencies,
                path: path,
                exclude: exclude,
                sources: sources,
                resources: resources,
                publicHeadersPath: publicHeadersPath,
                cSettings: cSettings,
                cxxSettings: cxxSettings,
                swiftSettings: [
                    .unsafeFlags(["-Osize", "-cross-module-optimization"], .when(configuration: .release))
                  ],
                linkerSettings: [],
                plugins: plugins)
    }

    func toTestTarget(
        dependencies: [Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [Resource]? = nil,
        publicHeadersPath: String? = nil,
        cSettings: [CSetting]? = nil,
        cxxSettings: [CXXSetting]? = nil,
        swiftSettings: [SwiftSetting]? = nil,
        linkerSettings: [LinkerSetting]? = nil,
        plugins: [Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        .target(name: "\(name)Tests",
                dependencies: dependencies,
                path: path ?? "Tests/\(name)Tests",
                exclude: exclude,
                sources: sources,
                resources: resources,
                publicHeadersPath: publicHeadersPath,
                cSettings: cSettings,
                cxxSettings: cxxSettings,
                swiftSettings: swiftSettings,
                linkerSettings: linkerSettings,
                plugins: plugins)
    }
}

struct Dependency {
    let package: Package.Dependency
    let target: PackageDescription.Target.Dependency
}
