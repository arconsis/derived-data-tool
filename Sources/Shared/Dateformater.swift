//
//  Dateformater.swift
//
//
//  Created by Moritz Ellerbrock on 01.06.23.
//

import Foundation

public enum DateFormat: CaseIterable {
    case yearMontDay
    case YearMonthDayHoursMinutesSeconds
    case YearMonthDayHoursMinutesSecondsAndTimeZone
    case dayMonthYear
    case dayAbbreviatedMonthYear
    case fullMonthDayYear
    case fullWeekdayFullMonthNameDayYear
    case hoursMinutesWithAmPmIndicator
    case hoursMinutesSecondsIn24hFormat
    case iso8601Format
    case abbreviatedMonthDayYearTimeInAmPmFormat
    case abbreviatedMonthDayYearTimeIn24hFormat

    private var format: String {
        switch self {
        case .yearMontDay:
            return "yyyy-MM-dd"
        case .YearMonthDayHoursMinutesSeconds:
            return "yyyy-MM-dd HH:mm:ss"
        case .YearMonthDayHoursMinutesSecondsAndTimeZone:
            return "yyyy.MM.dd_HH-mm-ss-ZZZZ"
        case .dayMonthYear:
            return "dd/MM/yyyy"
        case .dayAbbreviatedMonthYear:
            return "dd MMM yyyy"
        case .fullMonthDayYear:
            return "MMMM dd, yyyy"
        case .fullWeekdayFullMonthNameDayYear:
            return "EEEE, MMMM dd, yyyy"
        case .hoursMinutesWithAmPmIndicator:
            return "h:mm a"
        case .hoursMinutesSecondsIn24hFormat:
            return "HH:mm:ss"
        case .iso8601Format:
            return "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case .abbreviatedMonthDayYearTimeInAmPmFormat:
            return "MMM dd, yyyy 'at' h:mm a"
        case .abbreviatedMonthDayYearTimeIn24hFormat:
            return "MMM dd, yyyy 'at' h:mm:ss"
        }
    }

    private var dateFormatter: DateFormatter {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = format
        return dateformatter
    }

    public static func date(from string: String) -> Date? {
        for format in allCases {
            let formatter = format.dateFormatter
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    public func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    public func date(from string: String) -> Date? {
        let formatter = dateFormatter
        if let date = formatter.date(from: string) {
            return date
        }
        return nil
    }
}
