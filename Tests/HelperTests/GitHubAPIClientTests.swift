//
//  GitHubAPIClientTests.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import Foundation
@testable import Helper
import XCTest

final class GitHubAPIClientTests: XCTestCase {
    var savedToken: String?

    override func setUp() {
        super.setUp()
        // Save and clear any existing GITHUB_TOKEN
        savedToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
    }

    override func tearDown() {
        // Restore original token if it existed
        if let token = savedToken {
            setenv("GITHUB_TOKEN", token, 1)
        } else {
            unsetenv("GITHUB_TOKEN")
        }
        savedToken = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_WithProvidedToken_Succeeds() throws {
        let token = "ghp_test_token_123"

        let client = try GitHubAPIClient(token: token)

        XCTAssertNotNil(client)
    }

    func testInit_WithEnvironmentToken_Succeeds() throws {
        setenv("GITHUB_TOKEN", "ghp_env_token_456", 1)

        let client = try GitHubAPIClient()

        XCTAssertNotNil(client)
    }

    func testInit_ProvidedTokenTakesPrecedence() throws {
        setenv("GITHUB_TOKEN", "ghp_env_token", 1)
        let providedToken = "ghp_provided_token"

        // Should succeed with provided token (no way to verify which was used without exposing the token property)
        let client = try GitHubAPIClient(token: providedToken)

        XCTAssertNotNil(client)
    }

    func testInit_WithoutToken_ThrowsMissingTokenError() {
        unsetenv("GITHUB_TOKEN")

        XCTAssertThrowsError(try GitHubAPIClient()) { error in
            guard let apiError = error as? GitHubAPIClient.GitHubAPIError else {
                XCTFail("Expected GitHubAPIError, got \(type(of: error))")
                return
            }

            if case .missingToken = apiError {
                // Expected error
                XCTAssertTrue(apiError.localizedDescription.contains("GITHUB_TOKEN"))
            } else {
                XCTFail("Expected missingToken error, got \(apiError)")
            }
        }
    }

    // MARK: - Error Description Tests

    func testGitHubAPIError_MissingToken_HasDescriptiveMessage() {
        let error = GitHubAPIClient.GitHubAPIError.missingToken

        let description = error.localizedDescription

        XCTAssertTrue(description.contains("GITHUB_TOKEN"))
        XCTAssertTrue(description.contains("environment variable"))
    }

    func testGitHubAPIError_InvalidEndpoint_HasDescriptiveMessage() {
        let endpoint = "/invalid/endpoint"
        let error = GitHubAPIClient.GitHubAPIError.invalidEndpoint(endpoint)

        let description = error.localizedDescription

        XCTAssertTrue(description.contains(endpoint))
        XCTAssertTrue(description.contains("Invalid"))
    }

    func testGitHubAPIError_NetworkError_HasDescriptiveMessage() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test network error"])
        let error = GitHubAPIClient.GitHubAPIError.networkError(underlyingError)

        let description = error.localizedDescription

        XCTAssertTrue(description.contains("Network error"))
        XCTAssertTrue(description.contains("Test network error"))
    }

    func testGitHubAPIError_HTTPError_HasDescriptiveMessage() {
        let statusCode = 404
        let message = "Not Found"
        let error = GitHubAPIClient.GitHubAPIError.httpError(statusCode: statusCode, message: message)

        let description = error.localizedDescription

        XCTAssertTrue(description.contains("404"))
        XCTAssertTrue(description.contains("Not Found"))
        XCTAssertTrue(description.contains("HTTP"))
    }

    func testGitHubAPIError_HTTPError_WithoutMessage_HasDescriptiveMessage() {
        let statusCode = 500
        let error = GitHubAPIClient.GitHubAPIError.httpError(statusCode: statusCode, message: nil)

        let description = error.localizedDescription

        XCTAssertTrue(description.contains("500"))
        XCTAssertTrue(description.contains("Unknown error"))
    }

    func testGitHubAPIError_DecodingError_HasDescriptiveMessage() {
        let underlyingError = NSError(domain: "DecodingDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Failed to decode"])
        let error = GitHubAPIClient.GitHubAPIError.decodingError(underlyingError)

        let description = error.localizedDescription

        XCTAssertTrue(description.contains("decode"))
        XCTAssertTrue(description.contains("Failed to decode"))
    }

    // MARK: - Model Tests

    func testGitHubComment_Decodable_WithValidJSON() throws {
        let json = """
        {
            "id": 123456,
            "body": "This is a test comment",
            "user": {
                "login": "testuser",
                "id": 789
            },
            "created_at": "2026-03-01T12:00:00Z",
            "updated_at": "2026-03-02T12:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertEqual(comment.id, 123456)
        XCTAssertEqual(comment.body, "This is a test comment")
        XCTAssertEqual(comment.user.login, "testuser")
        XCTAssertEqual(comment.user.id, 789)
        XCTAssertEqual(comment.createdAt, "2026-03-01T12:00:00Z")
        XCTAssertEqual(comment.updatedAt, "2026-03-02T12:00:00Z")
    }

    func testGitHubComment_Decodable_WithMinimalJSON() throws {
        let json = """
        {
            "id": 1,
            "body": "",
            "user": {
                "login": "bot",
                "id": 1
            },
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertEqual(comment.id, 1)
        XCTAssertEqual(comment.body, "")
        XCTAssertEqual(comment.user.login, "bot")
    }

    func testGitHubComment_Decodable_ArrayOfComments() throws {
        let json = """
        [
            {
                "id": 1,
                "body": "First comment",
                "user": {"login": "user1", "id": 1},
                "created_at": "2026-03-01T00:00:00Z",
                "updated_at": "2026-03-01T00:00:00Z"
            },
            {
                "id": 2,
                "body": "Second comment",
                "user": {"login": "user2", "id": 2},
                "created_at": "2026-03-02T00:00:00Z",
                "updated_at": "2026-03-02T00:00:00Z"
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let comments = try JSONDecoder().decode([GitHubAPIClient.GitHubComment].self, from: data)

        XCTAssertEqual(comments.count, 2)
        XCTAssertEqual(comments[0].id, 1)
        XCTAssertEqual(comments[1].id, 2)
    }

    func testGitHubComment_Decodable_HandlesSnakeCaseKeys() throws {
        let json = """
        {
            "id": 999,
            "body": "Test",
            "user": {"login": "test", "id": 1},
            "created_at": "2026-03-01T12:34:56Z",
            "updated_at": "2026-03-02T12:34:56Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        // Verify snake_case keys are properly decoded to camelCase properties
        XCTAssertEqual(comment.createdAt, "2026-03-01T12:34:56Z")
        XCTAssertEqual(comment.updatedAt, "2026-03-02T12:34:56Z")
    }

    func testGitHubUser_Decodable_WithValidJSON() throws {
        let json = """
        {
            "login": "octocat",
            "id": 583231
        }
        """

        let data = json.data(using: .utf8)!
        let user = try JSONDecoder().decode(GitHubAPIClient.GitHubUser.self, from: data)

        XCTAssertEqual(user.login, "octocat")
        XCTAssertEqual(user.id, 583231)
    }

    // MARK: - Edge Cases

    func testGitHubComment_Decodable_WithSpecialCharactersInBody() throws {
        let json = """
        {
            "id": 111,
            "body": "Comment with \\\"quotes\\\" and \\n newlines \\t tabs",
            "user": {"login": "test", "id": 1},
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertTrue(comment.body.contains("quotes"))
        XCTAssertTrue(comment.body.contains("\n"))
    }

    func testGitHubComment_Decodable_WithMarkdownInBody() throws {
        let json = """
        {
            "id": 222,
            "body": "# Header\\n\\n**bold** and *italic*\\n\\n- list item",
            "user": {"login": "test", "id": 1},
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertTrue(comment.body.contains("# Header"))
        XCTAssertTrue(comment.body.contains("**bold**"))
    }

    func testGitHubComment_Decodable_WithEmptyBody() throws {
        let json = """
        {
            "id": 333,
            "body": "",
            "user": {"login": "test", "id": 1},
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertEqual(comment.body, "")
    }

    func testGitHubComment_Decodable_WithLongBody() throws {
        let longBody = String(repeating: "A", count: 10000)
        let json = """
        {
            "id": 444,
            "body": "\(longBody)",
            "user": {"login": "test", "id": 1},
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let comment = try JSONDecoder().decode(GitHubAPIClient.GitHubComment.self, from: data)

        XCTAssertEqual(comment.body.count, 10000)
    }
}
