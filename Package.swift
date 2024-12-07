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
    static let migrate = TargetDefinition(name: "Migrate", path: "Sources/Command/Migrate")
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
        AppDependencies.argumentParser.package,
        AppDependencies.asyncAlgorithms.package,
        AppDependencies.duckDB.package,
        AppDependencies.globPattern.package,
        AppDependencies.swiftHTML.package,
        AppDependencies.yams.package,
    ],
    targets: [
        .executableTarget(
            name: MyPackage.app.name,
            dependencies: [
                AppDependencies.argumentParser.target,
                .archive(),
                .build(),
                .compare(),
                .config(),
                .coverage(),
                .dependencyInjection(),
                .migrate(),
                .prototype(),
                .report(),
            ],
            path: MyPackage.app.path
        ),

        // MARK: SubCommands

        MyPackage.coverage.toTarget(
            dependencies: [
                AppDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ],
            resources: [
                .process("Resources/input.json"),
            ]
        ),
        MyPackage.migrate.toTarget(
            dependencies: [
                AppDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.compare.toTarget(
            dependencies: [
                AppDependencies.argumentParser.target,
                .dependencyInjection(),
                .shared(),
                .helper(),
            ]
        ),
        MyPackage.build.toTarget(
            dependencies: [
                AppDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.config.toTarget(dependencies: [
            AppDependencies.argumentParser.target,
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]
        ),
        MyPackage.report.toTarget(dependencies: [
            AppDependencies.argumentParser.target,
            .dependencyInjection(),
            .helper(),
            .shared(),
        ]),
        MyPackage.prototype.toTarget(
            dependencies: [
                AppDependencies.argumentParser.target,
                .dependencyInjection(),
                .helper(),
            ]
        ),
        MyPackage.archive.toTarget(dependencies: [
            AppDependencies.argumentParser.target,
            .helper(),
        ]),

        // MARK: HELPER
        MyPackage.helper.toTarget(
            dependencies: [
                AppDependencies.asyncAlgorithms.target,
                AppDependencies.duckDB.target,
                AppDependencies.globPattern.target,
                AppDependencies.swiftHTML.target,
                AppDependencies.yams.target,
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
                .migrate(),
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

    /// SubCommand: `migrate`: command to generate migrate from old json storage to new database approach
    static func migrate() -> Target.Dependency {
        Target.Dependency.target(name: "Migrate")
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

enum AppDependencies {
    typealias PPD = PackageDescription.Package.Dependency

    struct Reference {
        let package: Package.Dependency
        let target: PackageDescription.Target.Dependency
    }

    static var argumentParser: Reference {
        .init(
            package: PPD.package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0"),
            target: Target.Dependency.product(name: "ArgumentParser", package: "swift-argument-parser")
        )
    }

    static var swiftHTML: Reference {
        .init(
            package: PPD.package(url: "https://github.com/binarybirds/swift-html", from: "1.6.0"),
            target: Target.Dependency.product(name: "SwiftHtml", package: "swift-html")
        )
    }

    /// ext. Dependency: Yams Package (use as package.dependency)
    static var yams: Reference {
        .init(
            package: PPD.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
            target: Target.Dependency.product(name: "Yams", package: "yams")
        )
    }

    /// ext. Dependency: GlobPattern Package (use as package.dependency)
    static var globPattern: Reference {
        .init(
            package: PPD.package(url: "https://github.com/ChimeHQ/GlobPattern", from: "0.1.1"),
            target: Target.Dependency.product(name: "GlobPattern", package: "GlobPattern")
        )
    }

    /// ext. Dependency: AsyncAlgorithms Package (use as package.dependency)
    static var asyncAlgorithms: Reference {
        .init(
            package: PPD.package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
            target: Target.Dependency.product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
        )
    }

    static var duckDB: Reference {
        .init(
            package: Package.Dependency.package(url: "https://github.com/duckdb/duckdb-swift.git", from: "1.1.3"),
            target: PackageDescription.Target.Dependency.product(name: "DuckDB", package: "duckdb-swift")
        )
    }
}
