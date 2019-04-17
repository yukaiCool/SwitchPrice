//
//  SettingTableViewCell.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/16.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class SettingTableViewCell: UITableViewCell {

    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingDescriptionLabel: UILabel!
    @IBOutlet weak var settingImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
