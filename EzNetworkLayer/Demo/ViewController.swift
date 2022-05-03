//
// Created on 2022/5/3.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        api.get()
    }
    
    private let api = EzDemoAPI()
    private let disposeBag = DisposeBag()
}

private extension ViewController {
    func bind() {
       api
            .result
            .debug()
            .withUnretained(self)
            .subscribe(onNext: { owner, model in
                print(model)
            })
            .disposed(by: disposeBag)
    }
}
