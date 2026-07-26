//
//  APIErrors.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

/// Errors surfaced by the networking layer.
enum APIErrors: Error, Equatable {
    case invalidUrl
    case invalidResponse
    case decodingFailed
}

extension APIErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "The request address was invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .decodingFailed:
            return "The response couldn't be read."
        }
    }
}
