//
//  EZAPIBase.swift
//  EzNetworkLayer
//
//  Created by Patrick Chen on 2022/5/1.
//

import Foundation
import Moya

extension MoyaProvider where Target: EzTargetType {
    
    func send<T: EzTargetType>(
        request: T,
        decisions: [Decision]? = nil,
        handler: @escaping (Result<T.ResponseType, Error>) -> Void
    ) {
        self.request(request as! Target) { [weak self] in
            switch $0 {
            case .success(let response):
       
                 // Insert fake data
                /*
                if request.path.contains("") {
                    let data = """
                 {
                 "Message" : "",
                 "StatusCode" : 200,
                 "Data" : {
                    "fact": "A cats field of vision is about 185 degrees.",
                    "length": 44
                 }
                 }
                 """.data(using: .utf8)!

                    self?.handleDecision(
                        request,
                        response: .init(
                            statusCode: 200,
                            data: data,
                            request: response.request,
                            response: response.response
                        ),
                        decisions: decisions ?? request.decisions,
                        handler: handler
                    )

                    return
                }
                */
                 
                self?.handleDecision(
                    request,
                    response: response,
                    decisions: decisions ?? request.decisions,
                    handler: handler
                )
                
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
    
    func handleDecision<T: EzTargetType>(
        _ request: T,
        response: Moya.Response,
        resultModelData: ResponseModel? = nil,
        decisions: [Decision],
        handler: @escaping (Result<T.ResponseType, Error>) -> Void
    ) {
        guard !decisions.isEmpty else {
            fatalError("No decision left but did not reach a stop.")
        }
        
        var decisions = decisions
        let current = decisions.removeFirst()
        
        guard current.shouldApply(
            request: request,
            response: response,
            resultModelData: resultModelData
        ) else {
            handleDecision(
                request,
                response: response,
                resultModelData: resultModelData,
                decisions: decisions,
                handler: handler
            )
            return
        }
        
        current
            .apply(
                request: request,
                response: response,
                resultModelData: resultModelData
            ) { [weak self] action in
                
                guard let self = self else { return }
                
                switch action {
                case .continueWith(
                    response: let response,
                    resultModelData: let resultModelData
                ):
                    self.handleDecision(
                        request,
                        response: response,
                        resultModelData: resultModelData,
                        decisions: decisions,
                        handler: handler
                    )
                case .restartWith(decisions: let decisions):
                    self.send(
                        request: request,
                        decisions: decisions,
                        handler: handler
                    )
                    break
                case .errored(error: let error):
                    handler(.failure(error))
                case .done(value: let value):
                    handler(.success(value))
                }
            }
    }
}
