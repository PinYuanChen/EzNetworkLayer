//
//  EzTargetType.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/19.
//

import Foundation
import Moya

var APIBaseHeader: [String: String] {
    // Fill in required info for request
    return ["" : ""]
}

protocol EzTargetType: TargetType {
    associatedtype ResponseType: Decodable
}

extension EzTargetType {
    
    var baseURL: URL {
        // Fill in your url
        URL(string: "")!
    }
    
    var headers: [String : String]? {
        APIBaseHeader
    }
    
}
