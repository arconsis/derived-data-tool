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
    static let prototype = TargetDefinition(name: "Prototype", path: "Sources/Command/Prototype")
    static let report = TargetDefinition(name: "Report", path: "Sources/Command/Report")
}

typealias MyPackage = PackageDescription.Target

let package = Package(
    name: "DerivedDataTool",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .argumentParserPackage(),
        .asyncAlgorithmsPackage(),
//        .fluent(),
//        .postgresDriver(),
        .duckDB(),
//        .sqlDriver(),
        .globPatternPackage(),
        .swiftHTMLPackage(),
//        .swiftSlashPackage(),
        .yamsPackage(),
//        .swiftTUI(),
//        .swifql(),
    ],
    targets: [
        .executableTarget(
            name: MyPackage.app.name,
            dependencies: [
                .argumentParser(),
//                .swiftTUI(),
                .archive(),
                .coverage(),
                .compare(),
                .dependencyInjection(),
                .prototype(),
                .build(),
                .config(),
                .report(),
            ],
            path: MyPackage.app.path
        ),

        // MARK: SubCommands

        MyPackage.coverage.toTarget(
            dependencies: [
                .argumentParser(),
                .dependencyInjection(),
                .helper(),
            ],
            resources: [
                .process("Resources/input.json"),
            ]
        ),
        MyPackage.compare.toTarget(
            dependencies: [
                .argumentParser(),
                .dependencyInjection(),
                .shared(),
                .helper(),
            ]
        ),
        MyPackage.build.toTarget(
            dependencies: [
                .argumentParser(),
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.config.toTarget(dependencies: [
            .argumentParser(),
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]
        ),
        MyPackage.report.toTarget(dependencies: [
            .argumentParser(),
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]),
        MyPackage.prototype.toTarget(
            dependencies: [
                .argumentParser(),
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.archive.toTarget(dependencies: [
            .argumentParser(),
            .helper(),
        ]),

        // MARK: HELPER
        MyPackage.helper.toTarget(
            dependencies: [
                .asyncAlgorithms(),
                .dependencyInjection(),
//                .fluent(),
//                .postgresDriver(),
//                .sqlDriver(),
                .duckDB(),
                .globPattern(),
                .shared(),
                .swiftHTML(),
//                .swiftSlash(),
                .yams(),
//                .swifql(),
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
                .process("Resources/TestData-tiny.json"),
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

extension PackageDescription.Package.Dependency {
    typealias PPD = PackageDescription.Package.Dependency
    /// ext. Dependency: ArgumentParser Package (use as package.dependency)
    static func argumentParserPackage() -> Package.Dependency {
        PPD.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
    }

    /// ext. Dependency: SwiftHtml Package (use as package.dependency)
    static func swiftHTMLPackage() -> Package.Dependency {
        PPD.package(url: "https://github.com/binarybirds/swift-html", from: "1.6.0")
    }

    /// ext. Dependency: Yams Package (use as package.dependency)
    static func yamsPackage() -> Package.Dependency {
        PPD.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5")
    }

    /// ext. Dependency: GlobPattern Package (use as package.dependency)
    static func globPatternPackage() -> Package.Dependency {
        PPD.package(url: "https://github.com/ChimeHQ/GlobPattern", from: "0.1.1")
    }

    /// ext. Dependency: AsyncAlgorithms Package (use as package.dependency)
    static func asyncAlgorithmsPackage() -> Package.Dependency {
        PPD.package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    }

//    static func swiftSlashPackage() -> Package.Dependency {
//        PPD.package(url: "https://github.com/tannerdsilva/SwiftSlash", from: "3.4.0")
//    }

//    static func fluent() -> Package.Dependency {
//        Package.Dependency.package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0-beta.1")
//    }

//    static func postgresDriver() -> Package.Dependency {
//        PPD.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0")
//    }
    
//    static func sqlDriver() -> Package.Dependency {
//        Package.Dependency.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0")
//    }

//    static func swiftTUI() -> Package.Dependency {
//        Package.Dependency.package(url: "https://github.com/rensbreur/SwiftTUI.git", branch: "main")
//    }

    static func duckDB() -> Package.Dependency {
        Package.Dependency.package(url: "https://github.com/duckdb/duckdb-swift.git", from: "1.1.3")
    }

//    static func swifql() -> Package.Dependency {
//        .package(url: "https://github.com/MihaelIsaev/SwifQL.git", from: "2.0.0-beta.3.21.0")
//    }
}

extension PackageDescription.Target.Dependency {
    // MARK: ThirdPArty Dependencies

    /// ThirdParty: ArgumentParser Package (use as target.dependency)
    static func argumentParser() -> Target.Dependency {
        Target.Dependency.product(name: "ArgumentParser", package: "swift-argument-parser")
    }

    /// ThirdParty: SwiftHtml Package (use as target.dependency)
    static func swiftHTML() -> Target.Dependency {
        Target.Dependency.product(name: "SwiftHtml", package: "swift-html")
    }

    /// ThirdParty: Yams Package (use as target.dependency)
    static func yams() -> Target.Dependency {
        Target.Dependency.product(name: "Yams", package: "yams")
    }

    /// ThirdParty: GlobPattern Package (use as target.dependency)
    static func globPattern() -> Target.Dependency {
        Target.Dependency.product(name: "GlobPattern", package: "GlobPattern")
    }

    /// ThirdParty: AsyncAlgorithms Package (use as target.dependency)
    static func asyncAlgorithms() -> Target.Dependency {
        Target.Dependency.product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
    }

    /// ThirdParty: SwiftSlash Package (use as target.dependency)
//    static func swiftSlash() -> Target.Dependency {
//        Target.Dependency.product(name: "SwiftSlash", package: "SwiftSlash")
//    }

//    static func postgresKit() -> Target.Dependency {
//        Target.Dependency.product(name: "PostgresKit", package: "postgres-kit")
//    }
//    static func fluent() -> Self {
//        PackageDescription.Target.Dependency.product(name: "HummingbirdFluent", package: "hummingbird-fluent")
//    }

//    static func postgresDriver() -> Target.Dependency {
//        Target.Dependency.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
//    }

//    static func sqlDriver() -> Self {
//        PackageDescription.Target.Dependency.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
//    }

//    static func swiftTUI() -> Self {
//        PackageDescription.Target.Dependency.product(name: "SwiftTUI", package: "SwiftTUI")
//    }

    static func duckDB() -> Self {
        PackageDescription.Target.Dependency.product(name: "DuckDB", package: "duckdb-swift")
    }

//    static func swifql() -> Self {
//        PackageDescription.Target.Dependency.product(name: "SwifQL", package: "SwifQL")
//    }
}

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
                swiftSettings: swiftSettings,
                linkerSettings: linkerSettings,
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
