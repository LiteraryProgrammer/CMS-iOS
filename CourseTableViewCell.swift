//
//  CourseTableViewCell.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 10/10/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class CourseTableViewCell: UITableViewCell {

    @IBOutlet weak var courseName: UILabel!
    @IBOutlet weak var courseProgress: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func didSelectOptionButton(_ sender: UIButton) {
    }
}
