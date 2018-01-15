//
//  SearchResultCell.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 14/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchResultCell: UITableViewCell {
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        title.textColor = UIColor.lightGray
    }
    
    func bind(query: String?, result: String) {
        let range = NSString(string: result).range(of: query ?? "")
        let formatted = NSMutableAttributedString(string: result)
        formatted.addAttributes([NSAttributedStringKey.foregroundColor : UIColor.black], range: range)
        self.title.attributedText = formatted
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
