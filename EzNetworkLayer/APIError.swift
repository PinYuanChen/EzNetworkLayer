//
//  APIError.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/23.
//

import Foundation

enum APIError: Int {
    case error500 = 500
}

extension APIError {
    
    var message: String? {
        switch self {
        case .error500:
            return "Internal Server Error"
        }
    }
    
}
