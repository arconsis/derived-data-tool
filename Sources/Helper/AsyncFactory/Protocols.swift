//
//  File.swift
//
//
//  Created by Moritz Ellerbrock on 30.11.23.
//

import Foundation

public protocol AsyncProducable {
    func setup() async throws
}

public protocol Producable {
    func setup() throws
}

public enum AsyncFactory {
    public static func setup(_ product: Producable) throws -> Producable {
        try product.setup()
        return product
    }

    public static func setupAsync(_ product: AsyncProducable) async throws -> AsyncProducable {
        try await product.setup()
        return product
    }
}
