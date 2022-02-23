//
//  ResponseModel.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/21.
//

import Foundation

struct ResponseModel: Codable {
    
    // example format, change to your API response type
    let message: String
    let statusCode: Int?
    let data: Data
    
    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case statusCode = "StatusCode"
        case message = "Message"
    }
    
    enum DataParseError: Error {
        case parseError
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)

        message = try container.decode(String.self, forKey: .message)
        statusCode = try? container.decodeIfPresent(Int.self, forKey: .statusCode)
        data = try container.decode(Data.self, forKey: .data)
    }
    
}
