//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 28.04.24.
//

import Foundation

public typealias StringResult = Result<String, CCCLIError>

public typealias StringArrayResult = Result<[String], CCCLIError>

public typealias URLResult = Result<URL, CCCLIError>

public typealias URLArrayResult = Result<[URL], CCCLIError>


public extension Result where Success == String, Failure == CCCLIError {
    func convertToSingleUrl() -> Result<URL, Failure> {
        switch self {
            case .success(let success):
                return .success(URL(with: success))
            case .failure(let failure):
                return .failure(failure)
        }
    }
}


public extension Result where Success == [String], Failure == CCCLIError {
    func convertToUrl() -> Result<[URL], Failure> {
        switch self {
            case .success(let success):
                return .success(success.map { URL(with: $0) } )
            case .failure(let failure):
                return .failure(failure)
        }
    }
}


public extension Result where Failure == CCCLIError {
    var error: Failure? {
        switch self {
            case .success:
                return nil
            case .failure(let error):
                return error
        }
    }
}
