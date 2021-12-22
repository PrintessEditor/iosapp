//
//  FinishedDesignToken.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 21.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import Foundation

struct FinishedDesignToken: Codable {
  var id: Int
  var name: String
  var token: String
  var thumbnailURL: String
  var backgroundColor: String
}
