//
//  IAPTableViewCell.swift
//  IAPDemoFrank
//
//  Created by Frank.Chen on 2017/5/5.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit

class IAPTableViewCell: UITableViewCell {

    @IBOutlet weak var productLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
