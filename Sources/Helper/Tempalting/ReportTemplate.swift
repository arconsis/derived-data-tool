//
//  ReportTemplate.swift
//
//
//  Created by Moritz Ellerbrock on 03.07.23.
//

import Foundation
import Shared
import Yams

struct Template {
    let values: [String: ValueRepresentation]
}

extension Template {
    static func decode(json: String) throws -> Self {
        guard let data: Data = json.data(using: .utf8) else {
            throw TemplateError.jsonStringToDataConversionFailed
        }
        return try decode(json: data)
    }

    static func decode(json: Data) throws -> Self {
        let dict = try SingleDecoder.shared.decode([String: String].self, from: json)
        return decode(dict: dict)
    }

    static func decode(yaml: String) throws -> Self {
        guard let data: Data = yaml.data(using: .utf8) else {
            throw TemplateError.jsonStringToDataConversionFailed
        }
        return try decode(yaml: data)
    }

    static func decode(yaml: Data) throws -> Self {
        let decoder = YAMLDecoder()
        let dict = try decoder.decode([String: String].self, from: yaml)
        let values = dict.compactMapValues { string -> ValueRepresentation? in
            try? ValueRepresentation.decode(string)
        }

        return .init(values: values)
    }

    static func decode(dict: [String: String]) -> Self {
        let values = dict.compactMapValues { string -> ValueRepresentation? in
            try? ValueRepresentation.decode(string)
        }

        return .init(values: values)
    }
}

extension Template {
    enum TemplateError: Error {
        case jsonStringToDataConversionFailed
    }
}

extension Template.ValueRepresentation {
    enum List: String {
        case date
        case top
        case last
        case uncovered
        case detail
        case compare
    }

    enum DataValue: String {
        case name
        case coverage
        case coveredLines
        case executableLines
    }
}

extension Template {
    struct ValueRepresentation {
        let list: List
        let index: Int?
        let value: DataValue?

        public func value(in report: CoverageMetaReport, previous: CoverageMetaReport?) throws -> String {
            switch list {
            case .date:
                return DateFormat.yearMontDay.string(from: report.fileInfo.date)
            case .top, .last, .uncovered, .detail:
                let targets = try list(in: report.coverage, previous: previous?.coverage)

                guard let index else {
                    throw ValueRepresentationError.indexCanNotBeParsed
                }

                return try dataValue(in: targets[index])
            case .compare:
                let targets = ComparingTargets.combine(report.coverage.targets, previous?.coverage.targets)

                guard let index else {
                    throw ValueRepresentationError.indexCanNotBeParsed
                }

                return try dataValue(in: targets[index])
            }
        }

        private func list(in report: FullCoverageReport, previous _: FullCoverageReport?) throws -> [Target] {
            switch list {
            case .date,
                 .compare:
                throw ValueRepresentationError.templateCombinationNoPossible
            case .top:
                return report.targets
                    .filter { $0.coverage > 0.01 }
                    .sorted(by: { $0.coverage > $1.coverage })
                    .map { $0 }
            case .last:
                return report.targets
                    .filter { $0.coverage > 0.01 }
                    .sorted(by: { $0.coverage < $1.coverage })
                    .map { $0 }
            case .uncovered:
                return report.targets
                    .filter { $0.coverage <= 0.01 }
                    .map { $0 }
            case .detail:
                return report.targets
                    .sorted(by: { $0.coverage > $1.coverage })
            }
        }

        private func dataValue(in target: Target) throws -> String {
            guard let property = value else {
                throw ValueRepresentationError.valueCanNotBeParsed
            }

            switch property {
            case .name:
                return target.name
            case .coverage:
                return "\(target.printableCoverage)%"
            case .coveredLines:
                return "\(target.coveredLines)"
            case .executableLines:
                return "\(target.executableLines)"
            }
        }

        private func compare(in _: FullCoverageReport, previous _: FullCoverageReport?) -> [ComparingTargets] {
            return []
        }

        private func dataValue(in comparingTarget: ComparingTargets) throws -> String {
            guard let property = value else {
                throw ValueRepresentationError.valueCanNotBeParsed
            }

            switch property {
            case .name:
                return comparingTarget.name
            case .coverage:
                return "\(comparingTarget.differenceCoverage)%"
            case .coveredLines:
                return "\(comparingTarget.differenceCoveredLines)"
            case .executableLines:
                return "\(comparingTarget.differenceExecutableLines)"
            }
        }

        static func decode(_ rawStringValue: String) throws -> Template.ValueRepresentation {
            let template = trimCurlyBraces(rawStringValue)
            let parts = template.split(separator: ".").map(String.init)
            if parts.count == 1, let dateString = parts.first, let date = List(rawValue: dateString), date == .date {
                return .init(list: .date, index: nil, value: nil)
            }
            guard parts.count < 3 else {
                throw ValueRepresentationError.notEnoughArguments
            }

            guard parts.count > 3 else {
                throw ValueRepresentationError.tooManyArguments
            }

            guard let list = List(rawValue: parts[0]) else {
                throw ValueRepresentationError.listCanNotBeParsed
            }

            guard let dataIndex = Int(parts[1]) else {
                throw ValueRepresentationError.indexCanNotBeParsed
            }

            guard let value = DataValue(rawValue: parts[2]) else {
                throw ValueRepresentationError.valueCanNotBeParsed
            }

            return Template.ValueRepresentation(list: list, index: dataIndex, value: value)
        }

        static func encode(_ rep: Template.ValueRepresentation) throws -> String {
            guard rep.list != List.date else {
                return "{\(rep.list.rawValue)}"
            }

            var result = "{"
            switch rep.list {
            case .date:
                throw ValueRepresentationError.listCanNotBeParsed
            case .top, .last, .uncovered, .detail, .compare:
                result.append(rep.list.rawValue)
            }

            guard let index = rep.index, let value = rep.value else {
                throw ValueRepresentationError.notEnoughArguments
            }

            result.append(".\(index).\(value.rawValue)}")
            return result
        }

        private static func trimCurlyBraces(_ text: String) -> String {
            var result = text
            if text.starts(with: "{") {
                result = String(result.dropFirst())
            }

            if let lastCharacter = text.last, lastCharacter == "}" {
                result = String(result.dropLast())
            }

            return result
        }
    }

    enum ValueRepresentationError: Errorable {
        case notEnoughArguments
        case tooManyArguments
        case listCanNotBeParsed
        case indexCanNotBeParsed
        case valueCanNotBeParsed
        case templateCombinationNoPossible

        var printsHelp: Bool { false }
        var errorDescription: String? { localizedDescription }
    }
}

final class ReportTemplate {}
