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

struct RetryDecision: Decision {
    let leftCount: Int
    func shouldApply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?) -> Bool {
            let isStatusCodeValid = (200..<300).contains(response.statusCode)
            return !isStatusCodeValid && leftCount > 0
        }
    
    func apply<T: EzTargetType>(
        request: T,
        response: Moya.Response,
        resultModelData: ResponseModel?,
        done closure: @escaping (DecisionAction<T>) -> Void
    ) {
        let retryDecision = RetryDecision(leftCount: leftCount - 1)
        print(leftCount)
        let newDecisions = request.decisions.replacing(self, with: retryDecision)
        closure(.restartWith(decisions: newDecisions))
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

struct ParseResultDecisionForDemo: Decision {
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
        do {
            let responseData = try decoder.decode(T.ResponseType.self, from: response.data)
            closure(.done(value: responseData))
        } catch {
            closure(.errored(error: EZResponseError.dataIsNil))
        }
    }
}

extension Array where Element == Decision {
    func replacing(_ item: Decision, with: Decision?) -> Array {
        print("Not implemented yet.")
        return self
    }
}
