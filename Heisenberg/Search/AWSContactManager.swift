//
//  AWSContactManager.swift
//  Heisenberg
//
//  Created by Xinzhe Wang on 1/17/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import Foundation
import AWSCore
import AWSAuthCore
import AWSDynamoDB
import Contacts
import RxSwift

class AWSContactManager {
    
    var uid: String //= UIDevice.current.identifierForVendor!.uuidString
    
    init(_ id: String) {
        uid = id
    }
    
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
        
        do {
            let containers = try store.containers(matching: nil)
            try containers.forEach({
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: $0.identifier)
                let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                print("🎈", $0.identifier, contacts.count)
                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
                contacts.forEach {
                    if let contactString = $0.phoneNumbers.first?.value.stringValue {
                        let contactNumber = formatKey(contactString)
                        if !contactNumber.isEmpty {
                            let contact = Contact()
                            contact?._userId = self.uid
                            contact?._number = formatKey(contactString)
                            contact?._name = $0.givenName + " " + $0.familyName
                            dynamoDBObjectMapper.save(contact!, completionHandler: {(error: Error?) -> Void in
                                if let error = error {
                                    print("The request dynamoDB failed. Error: \(error)")
                                    return
                                }
                                print("DynamoDB saved.")
                            })
                        }
                    }
                }
            })
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
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            let queryExpression = AWSDynamoDBQueryExpression()
            queryExpression.keyConditionExpression = "userId = :userId"
            queryExpression.filterExpression = "begins_with(#name, :input)"
            queryExpression.expressionAttributeNames = ["#name": "name",]
            queryExpression.expressionAttributeValues = [":userId" : self.uid, ":input" : query,]
            dynamoDBObjectMapper.query(Contact.self, expression: queryExpression).continueWith(block: { (task) -> Any? in
                if let error = task.error as NSError? {
                    print("The request failed. Error: \(error)")
                    observer.onError(error)
                } else {
                    let contacts = task.result?.items as! [Contact]
                    let res = contacts.map({ (contact) -> String in
                        return contact._name!
                    })
                    // print(res)
                    observer.onNext(res)
                    observer.onCompleted()
                }
                return nil
            })
            return Disposables.create()
        }
        
    }
}
