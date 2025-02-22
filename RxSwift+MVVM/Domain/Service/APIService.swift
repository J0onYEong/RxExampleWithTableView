//
//  APIService.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 07/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

let MenuUrl = "https://firebasestorage.googleapis.com/v0/b/rxswiftin4hours.appspot.com/o/fried_menus.json?alt=media&token=42d5cb7e-8ec4-48f9-bf39-3049e796c936"

class APIService {
    
    // Legacy code!!!
    static func fetchAllMenus(onComplete: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: URL(string: MenuUrl)!) { data, res, err in
            if let err = err {
                onComplete(.failure(err))
                return
            }
            guard let data = data else {
                let httpResponse = res as! HTTPURLResponse
                onComplete(.failure(NSError(domain: "no data",
                                            code: httpResponse.statusCode,
                                            userInfo: nil)))
                return
            }
            onComplete(.success(data))
        }.resume()
    }
    
    static func fetchAllMenusWithRx() -> Observable<Data> {
        
        Observable.create { emitter in
            
            fetchAllMenus { result in
                
                switch result {
                case .success(let data):
                    
                    emitter.onNext(data)
                    emitter.onCompleted()
                    
                case .failure(let failure):
                    emitter.onError(failure)
                }
            }
            
            return Disposables.create()
        }
    }
}
