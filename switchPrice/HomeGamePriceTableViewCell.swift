//
//  HomeGamePriceTableViewCell.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/3.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class HomeGamePriceTableViewCell: UITableViewCell {

    @IBOutlet weak var discount: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var country: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
