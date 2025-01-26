//
//  File.swift
//
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import FluentKit

enum ModelDefinition {
    enum Report {
        static var schema: String { "reports" }
        enum FieldKeys {
            static var date: FieldKey { "date" }
            static var type: FieldKey { "type" }
            static var url: FieldKey { "url" }
            static var application: FieldKey { "application" }
        }
    }

    enum Coverage {
        static var schema: String { "coverages" }
        enum FieldKeys {
            static var report: FieldKey { "report_id" }
        }
    }

    enum Target {
        static var schema: String { "targets" }
        enum FieldKeys {
            static var name: FieldKey { "name" }
            static var coverage: FieldKey { "coverage_id" }
            static var executableLines: FieldKey { "executableLines" }
            static var coveredLines: FieldKey { "coveredLines" }
        }
    }
}
