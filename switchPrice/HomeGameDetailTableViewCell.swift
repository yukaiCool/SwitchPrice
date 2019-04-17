//
//  HomeGameDetailTableViewCell.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/2.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class HomeGameDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var gameTitle: UILabel!
    @IBOutlet weak var gameReleaseDate: UILabel!
    @IBOutlet weak var gameLanguage: UILabel!
    @IBOutlet weak var gameCategory: UILabel!
    @IBOutlet weak var gamePeople: UILabel!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameExcerpt: UILabel!
    @IBOutlet weak var saleDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
