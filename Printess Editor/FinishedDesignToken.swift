//
//  FinishedDesignToken.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 21.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import Foundation

struct FinishedDesignToken: Codable {
  let id: Int
  let name: String
  let token: String
  let thumbnailURL: String
  let backgroundColor: String
  let storeId: UUID
}

extension FinishedDesignToken {
  init(id: Int, name: String, token: String, thumbnailURL: String, backgroundColor: String) {
    self.init(id: id,
              name: name,
              token: token,
              thumbnailURL: thumbnailURL,
              backgroundColor: backgroundColor,
              storeId: UUID())
  }
  
  func copy(id: Int? = nil, name: String? = nil, token: String? = nil,
            thumbnailURL: String? = nil, backgroundColor: String? = nil) -> FinishedDesignToken {
    FinishedDesignToken(
      id: id ?? self.id,
      name: name ?? self.name,
      token: token ?? self.token,
      thumbnailURL: thumbnailURL ?? self.thumbnailURL,
      backgroundColor: backgroundColor ?? self.backgroundColor,
      storeId: self.storeId
    )
  }
}
