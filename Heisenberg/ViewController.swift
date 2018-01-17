//
//  ViewController.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 14/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Foundation

class ViewController: UIViewController {
    var disposeBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    
    /* Summy Results */
    let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    let searchController = UISearchController(searchResultsController: nil)
    let contactManager = AWSContactManager()
    var results = [String]()
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWasShown), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWasShown), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .black
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        navigationItem.titleView = searchController.searchBar
        
        navigationItem.hidesSearchBarWhenScrolling = false
        
        let searchResultNib = UINib(nibName: "SearchResultCell", bundle: nil)
        tableView.register(searchResultNib, forCellReuseIdentifier: "search-result")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        
        searchController.searchBar.autocapitalizationType = .words
        searchController.searchBar.rx.text
            .debounce(0.5, scheduler: MainScheduler.instance)
            .map({
                /* Remove nil */
                $0 ?? ""
            })
            .do(onNext: { [weak self] query in
                /* Clear Results on Invalid Call */
                if query.isEmpty {
                    self?.results.removeAll()
                    self?.tableView.reloadData()
                } 
            })
            .observeOn(backgroundScheduler)
            .filter({
                /* Query only if length more than 3 */
                !$0.isEmpty
            })
            .distinctUntilChanged({
                /* Prevent duplicate API calls */
                return $0 == $1
            })
            .flatMap({
                return self.contactManager.search(query: $0)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (results) in
                self.results.removeAll()
                self.results.append(contentsOf: results)
                self.tableView.reloadData()
            })
        .disposed(by: disposeBag)
        
        self.contactManager.fetchContacts()
    }
    
    /* Keyboard Util */
    @objc func keyboardWasShown (notification: NSNotification) {
        let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let isPortrait = UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)
        let inset: CGFloat = isPortrait ? keyboardSize.height : keyboardSize.width
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, inset, 0.0);
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
}

/* TableView DataSource */
extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
}

/* TableView DataSource */
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "search-result") as! SearchResultCell
        cell.bind(query: searchController.searchBar.text, result: results[indexPath.row])
        return cell
    }
}
