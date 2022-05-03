//
//  Decision.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/2/21.
//

import Foundation
import Moya
import RxSwift
import RxCocoa

enum EZResponseError: Error {
    case dataIsNil
    case nonHTTPResponse
    case tokenError
    case resultModelDataIsNil
    case unknownStatusCode
    case apiError(error: APIError, resultModel: ResponseModel?)
    case unknownError(error: Error, response: Moya.Response? = nil)
}

enum DecisionAction<T: EzTargetType> {
    case continueWith(response: Moya.Response,
                      resultModelData: ResponseModel?)
    case restartWith(decisions: [Decision])
    case errored(error: Error)
    case done(value: T.ResponseType)
}

protocol Decision {
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?
    ) -> Bool
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?,
        done closure: @escaping (DecisionAction<T>) -> Void
    )
}

fileprivate let decoder = JSONDecoder()

struct ServiceResponseStatusCodeDecision: Decision {
    
    enum ServiceError: Error {
        case error(code: Int)
    }
    
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel? = nil
    ) -> Bool {
        return !(200 ..< 300).contains(response.statusCode)
    }
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel? = nil,
        done closure: @escaping (DecisionAction<T>) -> Void
    ) {
        closure(.errored(error: ServiceError.error(code: response.statusCode)))
    }
}

struct InitialParseResultDecision: Decision {
    
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel? = nil
    ) -> Bool { true }
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel? = nil,
        done closure: @escaping (DecisionAction<T>) -> Void
    ) {
        do {
            let value = try decoder.decode(ResponseModel.self, from: response.data)
            let action = DecisionAction<T>.continueWith(
                response: response,
                resultModelData: value
            )
            closure(action)
        } catch {
            closure(.errored(error: EZResponseError.unknownError(error: error, response: response)))
        }
    }
}

struct ResponseStatusCodeDecision: Decision {
    
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?
    ) -> Bool {
        !(resultModelData?.statusCode == 200)
    }
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?,
        done closure: @escaping (DecisionAction<T>) -> Void
    ) {
        if let modelData = resultModelData {
            if let error = APIError(rawValue: modelData.statusCode ?? 0) {
                closure(.errored(error: EZResponseError.apiError(error: error, resultModel: modelData)))
            } else {
                closure(.errored(error: EZResponseError.unknownStatusCode))
            }
        } else {
            closure(.errored(error: EZResponseError.resultModelDataIsNil))
        }
    }
}

struct ParseResultDecision: Decision {
    
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?
    ) -> Bool { true }
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?,
        done closure: @escaping (DecisionAction<T>) -> Void
    ) {
        
        if let data = resultModelData?.data {
            do {
                let value = try decoder.decode(T.ResponseType.self, from: data)
                closure(.done(value: value))
            } catch {
                closure(.errored(error: EZResponseError.unknownError(error: error, response: response)))
            }
        } else {
            closure(.errored(error: EZResponseError.dataIsNil))
        }
    }
}

