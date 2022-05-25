//
//  EzTargetType.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/19.
//

import Foundation
import Moya

var APIBaseHeader: [String: String]? {
    // Fill in required info for request
    nil
}

protocol EzTargetType: TargetType {
    associatedtype ResponseType: Decodable
    var decisions: [Decision] { get }
}

extension EzTargetType {
    
    var baseURL: URL {
        // Change to your url
        .init(string: "")!
    }
    
    var headers: [String : String]? {
        APIBaseHeader
    }
    
    var decisions: [Decision] {
        [
            ServiceResponseStatusCodeDecision(),
            InitialParseResultDecision(),
            ResponseStatusCodeDecision(),
            ParseResultDecision()
        ]
    }
}
