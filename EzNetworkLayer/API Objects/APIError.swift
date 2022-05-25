//
//  APIError.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/23.
//

import Foundation

enum APIError: Int {
    case forbidden = 403
    case notFound = 404
    case serverError = 500
}

extension APIError {
    
    var message: String? {
        switch self {
        case .forbidden:
            return "You don't have permission to access this server."
        case .notFound:
            return "Not found"
        case .serverError:
            return "Internal Server Error"
        }
    }
    
}
