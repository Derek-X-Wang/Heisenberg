//
//  FirebaseContactManager.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import FirebaseDatabase
import Contacts
import RxSwift

class FirebaseContactManager {
    lazy var uid: String = {
        /* Create a dummy uid */
        if let currentUid = UserDefaults.standard.value(forKey: "uid") as? String {
            return currentUid
        } else {
            let newUid = String.random(length: 5)
            UserDefaults.standard.set(newUid, forKey: "uid")
            UserDefaults.standard.synchronize()
            return newUid
        }
    }()
    
    lazy var reference: DatabaseReference = {
        return Database.database().reference().child("contacts").child(self.uid)
    }()
    
    func fetchContacts() {
        let store = CNContactStore()
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .notDetermined {
            store.requestAccess(for: .contacts, completionHandler: { (authorized, error) in
                if authorized { self.uploadContacts() }
            })
        } else if authStatus == .authorized {
            uploadContacts()
        }
    }
    
    func uploadContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        
        var updateData: [String : Any] = [String : Any]()
        do {
            let containers = try store.containers(matching: nil)
            try containers.forEach({
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: $0.identifier)
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                print("🎈", $0.identifier, contacts.count)
                contacts.forEach {
                    if let contactString = $0.phoneNumbers.first?.value.stringValue {
                        /* Trim whitespaces, take last 5 digits of Contact */
                        let obscuredContact = String(formatKey(contactString).suffix(5))
                        if !obscuredContact.isEmpty {
                            updateData[obscuredContact] = [
                                "name" : $0.givenName + " " + $0.familyName,
                                "contact" : obscuredContact
                            ]
                        }
                    }
                }
            })
            reference.updateChildValues(updateData)
        } catch let error {
            print("🎈 error fetching contacts", error.localizedDescription)
        }
    }
    
    func formatKey(_ string: String) -> String {
        /* Replace with better implementation */
        return string.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
    
    func search(query: String) -> Observable<[String]> {
        return Observable<[String]>.create { [unowned self] (observer) -> Disposable in
            self.reference
                .queryOrdered(byChild: "name")
                .queryStarting(atValue: query)
                .queryLimited(toFirst: 10)
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    var results = [String]()
                    if let keys = value?.allKeys {
                        results = keys.flatMap({ (key) -> String? in
                            let data = value?[key] as? NSDictionary
                            if let name = data?["name"] as? String, name.hasPrefix(query) {
                                return name
                            }
                            return nil
                        })    
                    }
                    results.sort()
                    observer.onNext(results)
                    observer.onCompleted()
                }) { (error) in
                    observer.onError(error)
            }
            return Disposables.create()
        }
        
    }
}
