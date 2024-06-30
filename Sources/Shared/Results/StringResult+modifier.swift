//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 28.04.24.
//

import Foundation

public extension Result where Failure == CCCLIError {
    @inlinable
    func modify<NewValue>(_ callback: @escaping (Success) -> (NewValue)) -> Result<NewValue,Failure> {
        switch self {
            case .success(let success):
                let newValue = callback(success)
                return .success(newValue)
            case .failure(let failure):
                return .failure(failure)
        }
    }
}
