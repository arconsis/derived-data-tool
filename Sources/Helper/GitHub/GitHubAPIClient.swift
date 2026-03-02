//
//  GitHubAPIClient.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import DependencyInjection
import Foundation
import Shared

/// Client for interacting with the GitHub API v3
/// Handles authentication and common API operations for PR comments
///
/// Authentication uses GITHUB_TOKEN environment variable (standard in GitHub Actions)
/// Documentation: https://docs.github.com/en/rest
public class GitHubAPIClient {
    @Injected(\.logger) private var logger: Loggerable

    private let token: String
    private let baseURL = "https://api.github.com"

    /// Initialize GitHub API client with authentication token
    /// - Parameter token: GitHub personal access token or GITHUB_TOKEN from CI environment
    /// - Throws: GitHubAPIError.missingToken if token is not provided
    public init(token: String? = nil) throws {
        // Try provided token first, then fall back to environment variable
        guard let authToken = token ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"] else {
            throw GitHubAPIError.missingToken
        }
        self.token = authToken
    }

    // MARK: - Request Building

    /// Creates an authenticated URLRequest for the GitHub API
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/repos/owner/repo/issues/1/comments")
    ///   - method: HTTP method (GET, POST, PATCH, DELETE)
    ///   - body: Optional request body (will be JSON encoded)
    /// - Returns: Configured URLRequest with authentication headers
    /// - Throws: GitHubAPIError.invalidEndpoint if URL cannot be constructed
    private func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: Codable? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw GitHubAPIError.invalidEndpoint(endpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 30

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try SingleEncoder.shared.encode(body)
        }

        return request
    }

    // MARK: - Errors

    public enum GitHubAPIError: LocalizedError {
        case missingToken
        case invalidEndpoint(String)
        case networkError(Error)
        case httpError(statusCode: Int, message: String?)
        case decodingError(Error)

        public var errorDescription: String? {
            switch self {
            case .missingToken:
                return "GITHUB_TOKEN environment variable is not set. Set it in your CI environment or pass token to initializer."
            case .invalidEndpoint(let endpoint):
                return "Invalid GitHub API endpoint: \(endpoint)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .httpError(let statusCode, let message):
                let msg = message ?? "Unknown error"
                return "GitHub API returned HTTP \(statusCode): \(msg)"
            case .decodingError(let error):
                return "Failed to decode GitHub API response: \(error.localizedDescription)"
            }
        }
    }
}
