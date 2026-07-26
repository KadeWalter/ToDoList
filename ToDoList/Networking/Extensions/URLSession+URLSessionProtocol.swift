//
//  URLSession+URLSessionProtocol.swift
//  ToDoList
//
//  Created by Kade Walter on 7/23/26.
//

import Foundation

protocol URLSessionProtocol: Sendable {
    func data(from url: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse)
}

extension URLSession : URLSessionProtocol { }
