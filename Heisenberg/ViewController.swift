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
import FirebaseDatabase

class ViewController: UIViewController {
    var disposeBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    
    /* Summy Results */
    let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    let searchController = UISearchController(searchResultsController: nil)
    let firebaseContactManager = FirebaseContactManager()
    var results = [String]()
    
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
        
        searchController.searchBar.rx.text
            .debounce(0.5, scheduler: MainScheduler.instance)
            .map({
                /* Remove nil */
                $0 ?? ""
            })
            .do(onNext: { [weak self] query in
                /* Clear Results on Invalid Call */
                if query.count  < 3 {
                    self?.results.removeAll()
                    self?.tableView.reloadData()
                } 
            })
            .subscribeOn(backgroundScheduler)
            .filter({
                /* Query only if length more than 3 */
                $0.count >= 3
            })
            .distinctUntilChanged({
                /* Prevent duplicate API calls */
                return $0 == $1
            })
            .flatMap({
                return self.firebaseContactManager.search(query: $0)
            })
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { (results) in
                self.results.removeAll()
                self.results.append(contentsOf: results)
                self.tableView.reloadData()
            })
        .disposed(by: disposeBag)
        
        
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
