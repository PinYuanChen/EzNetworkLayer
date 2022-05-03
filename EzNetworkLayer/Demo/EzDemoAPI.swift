//
// Created on 2022/5/3.
//

import Foundation
import Moya
import RxSwift
import RxCocoa

private struct RequestTargetType: EzTargetType {
    typealias ResponseType = EzDemoModel
    
    var path: String {
        "fact"
    }
    
    var method: Moya.Method {
        .get
    }
    
    var task: Task {
        .requestPlain
    }
}

protocol EzDemoAPIPrototype {
    var result: Observable<EzDemoModel> { get }
    
    func get()
}

struct EzDemoAPI: EzDemoAPIPrototype {
    var result: Observable<EzDemoModel> {
        privateResult.asObservable()
    }
    
    func get() {
        MoyaProvider<RequestTargetType>()
            .send(request: RequestTargetType()) {
                switch $0 {
                case .success(let model):
                    privateResult.accept(model)
                case .failure(let error):
                    print("🛠 \(#fileID) API Error: ", error)
                }
            }
    }
    
    private let privateResult = PublishRelay<EzDemoModel>()
}

