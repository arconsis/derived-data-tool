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
//            static var fileInfo: FieldKey { "fileInfo_id" }
            static var type: FieldKey { "type" }
            static var url: FieldKey { "url" }
            static var application: FieldKey { "application" }





            static var coverage: FieldKey { "coverage_id" }
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
        }
    }

    enum File {
        static var schema: String { "files" }
        enum FieldKeys {
            static var name: FieldKey { "name" }
            static var path: FieldKey { "path" }
            static var target: FieldKey { "target_id" }
        }
    }

    enum Function {
        static var schema: String { "functions" }
        enum FieldKeys {
            static var name: FieldKey { "name" }
            static var lineNumber: FieldKey { "lineNumber" }
            static var executableLines: FieldKey { "executableLines" }
            static var executionCount: FieldKey { "executionCount" }
            static var coveredLines: FieldKey { "coveredLines" }
            static var file: FieldKey { "file_id" }
        }
    }
}
