//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared

public struct DBKey {
    public let value: String
    public let application: String
    init (date: Foundation.Date, application: String) {
        value = DateFormat.yearMontDay.string(from: date)
        self.application = application
    }
}
