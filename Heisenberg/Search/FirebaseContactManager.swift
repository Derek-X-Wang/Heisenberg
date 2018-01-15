//
//  FirebaseContactManager.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import FirebaseDatabase
import RxSwift

class FirebaseContactManager {
    lazy var reference: DatabaseReference = {
        return Database.database().reference().child("contacts")
    }()
    
    func search(query: String) -> Observable<[String]> {
        return Observable<[String]>.create { [unowned self] (observer) -> Disposable in
            self.reference
                .queryOrdered(byChild: "name")
                .queryStarting(atValue: query)
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    var results = [String]()
                    if let keys = value?.allKeys {
                        results = keys.flatMap({ (key) -> String? in
                            let data = value?[key] as? NSDictionary
                            let name = data?["name"] as? String
                            return name
                        })    
                    }
                    observer.onNext(results)
                    observer.onCompleted()
                }) { (error) in
                    observer.onError(error)
            }
            return Disposables.create()
        }
        
    }
}
