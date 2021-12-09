//
//  TemplateTableViewCell.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 08.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import UIKit

class TemplateTableViewCell: UITableViewCell {

  @IBOutlet
  var titleLabel: UILabel?
  @IBOutlet
  var thumbnailView: UIImageView?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
}
