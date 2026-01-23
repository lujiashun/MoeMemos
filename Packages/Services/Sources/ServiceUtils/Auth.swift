//
//  File.swift
//  
//
//  Created by Mudkip on 2024/6/9.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

public struct AccessTokenAuthenticationMiddleware: ClientMiddleware {
    var accessToken: String?
    
    public init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let accessToken = accessToken {
            request.headerFields[.authorization] = "Bearer \(accessToken)"
        }
        return try await next(request, body, baseURL)
    }
}

public func rawAccessTokenMiddlware(hostURL: URL, accessToken: String?) -> @Sendable (URLRequest) async throws -> URLRequest {
    return { request in
        var request = request
        if let accessToken = accessToken, !accessToken.isEmpty && request.url?.host == hostURL.host {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

public struct UsernamePasswordAuthenticationMiddleware: ClientMiddleware {
    var username: String?
    var password: String?

    public init(username: String? = nil, password: String? = nil) {
        self.username = username
        self.password = password
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let username = username, let password = password {
            let credential = "\(username):\(password)"
            if let data = credential.data(using: .utf8) {
                let encoded = data.base64EncodedString()
                request.headerFields[.authorization] = "Basic \(encoded)"
            }
        }
        return try await next(request, body, baseURL)
    }
}

public func rawBasicAuthMiddlware(hostURL: URL, username: String?, password: String?) -> @Sendable (URLRequest) async throws -> URLRequest {
    return { request in
        var request = request
        if let username = username, let password = password, !username.isEmpty && request.url?.host == hostURL.host {
            let credential = "\(username):\(password)"
            if let data = credential.data(using: .utf8) {
                let encoded = data.base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
            }
        }
        return request
    }
}
