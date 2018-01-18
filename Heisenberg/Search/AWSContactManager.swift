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
                let filteredContacts = contacts.filter({ (contact) -> Bool in
                    let firstPhone = contact.phoneNumbers.first
                    let contactString = firstPhone == nil ? "Unknown" : firstPhone!.value.stringValue
                    let number = formatNumber(contactString)
                    let name = formatName(givenName: contact.givenName, familyName: contact.familyName)
                    if number == "Unknown" || name == "Unknown" {
                        return false
                    }
                    return true
                })
                var count = 0
                let limit = 100
                filteredContacts.forEach({ (userContact) in
                    if count < limit {
                        let contact = Contact()
                        contact?._userId = self.uid
                        contact?._number = userContact.phoneNumbers.first!.value.stringValue
                        contact?._name = formatName(givenName: userContact.givenName, familyName: userContact.familyName)
                        print("Contact:\n  userId -> \(contact!._userId!)\n  number -> \(contact!._number!)\n  name -> \(contact!._name!)")
                        dynamoDBObjectMapper.save(contact!, completionHandler: {(error: Error?) -> Void in
                            if let error = error {
                                print("The request dynamoDB failed. Error: \(error)")
                                return
                            }
                            print("DynamoDB saved.")
                        })
                    }
                    count += 1
                })
            })
        } catch let error {
            print("🎈 error fetching contacts", error.localizedDescription)
        }
    }
    
    func formatName(givenName: String, familyName: String) -> String {
        var res = "Unknown"
        if !givenName.isEmpty && !familyName.isEmpty {
            res = "\(givenName) \(familyName)"
        } else if !givenName.isEmpty {
            res = givenName
        } else if !familyName.isEmpty {
            res = familyName
        }
        return res
    }
    
    func formatNumber(_ number: String) -> String {
        let contactNumber = formatKey(number)
        guard !contactNumber.isEmpty else {
            return "Unknown"
        }
        return contactNumber
    }
    
    func formatKey(_ string: String) -> String {
        /* Replace with better implementation */
        return string.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
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
