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

    // MARK: - Comment Operations

    /// Lists all comments on a pull request
    /// - Parameters:
    ///   - owner: Repository owner (user or organization)
    ///   - repo: Repository name
    ///   - prNumber: Pull request number
    /// - Returns: Array of comments on the PR
    /// - Throws: GitHubAPIError on failure
    public func listPRComments(owner: String, repo: String, prNumber: Int) async throws -> [GitHubComment] {
        let endpoint = "/repos/\(owner)/\(repo)/issues/\(prNumber)/comments"
        let request = try makeRequest(endpoint: endpoint)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubAPIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitHubAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let comments = try SingleDecoder.shared.decode([GitHubComment].self, from: data)
            logger.debug("Retrieved \(comments.count) comments from PR #\(prNumber)")
            return comments

        } catch let error as GitHubAPIError {
            throw error
        } catch let error as DecodingError {
            throw GitHubAPIError.decodingError(error)
        } catch {
            throw GitHubAPIError.networkError(error)
        }
    }

    /// Finds an existing PR comment containing a specific marker string
    /// Useful for finding bot-generated comments to update instead of creating duplicates
    /// - Parameters:
    ///   - owner: Repository owner (user or organization)
    ///   - repo: Repository name
    ///   - prNumber: Pull request number
    ///   - marker: Unique identifier string to search for in comment bodies
    /// - Returns: The comment if found, nil otherwise
    /// - Throws: GitHubAPIError on failure
    public func findExistingComment(
        owner: String,
        repo: String,
        prNumber: Int,
        marker: String
    ) async throws -> GitHubComment? {
        let comments = try await listPRComments(owner: owner, repo: repo, prNumber: prNumber)
        let existingComment = comments.first { $0.body.contains(marker) }

        if let comment = existingComment {
            logger.debug("Found existing comment with marker '\(marker)' (ID: \(comment.id))")
        } else {
            logger.debug("No existing comment found with marker '\(marker)'")
        }

        return existingComment
    }

    /// Creates a new comment on a pull request
    /// - Parameters:
    ///   - owner: Repository owner (user or organization)
    ///   - repo: Repository name
    ///   - prNumber: Pull request number
    ///   - body: Comment body text (supports markdown)
    /// - Returns: The created comment
    /// - Throws: GitHubAPIError on failure
    public func createComment(
        owner: String,
        repo: String,
        prNumber: Int,
        body: String
    ) async throws -> GitHubComment {
        let endpoint = "/repos/\(owner)/\(repo)/issues/\(prNumber)/comments"
        let requestBody = CommentBody(body: body)
        let request = try makeRequest(endpoint: endpoint, method: "POST", body: requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubAPIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            guard httpResponse.statusCode == 201 else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitHubAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let comment = try SingleDecoder.shared.decode(GitHubComment.self, from: data)
            logger.debug("Created comment on PR #\(prNumber) (ID: \(comment.id))")
            return comment

        } catch let error as GitHubAPIError {
            throw error
        } catch let error as DecodingError {
            throw GitHubAPIError.decodingError(error)
        } catch {
            throw GitHubAPIError.networkError(error)
        }
    }

    /// Updates an existing comment on a pull request
    /// - Parameters:
    ///   - owner: Repository owner (user or organization)
    ///   - repo: Repository name
    ///   - commentId: The ID of the comment to update
    ///   - body: New comment body text (supports markdown)
    /// - Returns: The updated comment
    /// - Throws: GitHubAPIError on failure
    public func updateComment(
        owner: String,
        repo: String,
        commentId: Int,
        body: String
    ) async throws -> GitHubComment {
        let endpoint = "/repos/\(owner)/\(repo)/issues/comments/\(commentId)"
        let requestBody = CommentBody(body: body)
        let request = try makeRequest(endpoint: endpoint, method: "PATCH", body: requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubAPIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitHubAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let comment = try SingleDecoder.shared.decode(GitHubComment.self, from: data)
            logger.debug("Updated comment ID \(commentId)")
            return comment

        } catch let error as GitHubAPIError {
            throw error
        } catch let error as DecodingError {
            throw GitHubAPIError.decodingError(error)
        } catch {
            throw GitHubAPIError.networkError(error)
        }
    }

    // MARK: - Models

    /// Request body for creating/updating comments
    private struct CommentBody: Codable {
        let body: String
    }

    /// GitHub PR comment response model
    public struct GitHubComment: Codable {
        public let id: Int
        public let body: String
        public let user: GitHubUser
        public let createdAt: String
        public let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case body
            case user
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// GitHub user model
    public struct GitHubUser: Codable {
        public let login: String
        public let id: Int
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
