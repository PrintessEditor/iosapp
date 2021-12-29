//
//  TokenStore.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 21.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import Foundation
import UIKit

class TokenStoreFormat: Codable {
  init() {}
  var continuationTokens: [ContinuationToken] = []
  var finishedDesignTokens: [FinishedDesignToken] = []
}

class TokenStore {
  var tokenStore: TokenStoreFormat? = nil;
  var continuationTokens: [ContinuationToken] {
    get {
      return tokenStore?.continuationTokens ?? []
    }
    set(continuationTokens) {
      tokenStore?.continuationTokens = continuationTokens
    }
  }
  var finishedDesignTokens: [FinishedDesignToken] {
    get {
      return tokenStore?.finishedDesignTokens ?? []
    }
    set(finishedDesignTokens) {
      tokenStore?.finishedDesignTokens = finishedDesignTokens
    }
  }

  init() {
    NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
      guard let strongSelf = self else { return }
      guard let store = strongSelf.tokenStore else { return }
      TokenStore.save(tokens: store) { (result) in
        switch result {
        case .success(_):
          print("Sucessfully persisted tokens")
        case .failure(let error):
          print("Error saving tokens \(error)")
        }
      }
    }
    load()
  }

  func load() {
    TokenStore.load { [weak self] (result) -> ()  in
      guard let strongSelf = self else { return }
      switch result {
      case .success(let store):
        strongSelf.tokenStore = store
      case .failure(let error):
        print("Error loading tokens \(error)")
      }
    }
  }

  func save() {
    guard let store = tokenStore else { return }
    TokenStore.save(tokens: store) { result in
      switch result {
      case .success(_):
        print("Persisted tokens!")
      case .failure(let error):
        print("Error loading tokens \(error)")
      }
    }
  }

  func continuationToken(for template: String) -> ContinuationToken? {
    return continuationTokens.first(where: { tokenCandidate in
      tokenCandidate.name == template
    })
  }

  func setContinuationToken(newToken: ContinuationToken) {
    continuationTokens = continuationTokens.filter { token in
      token.name != newToken.name
    }
    continuationTokens.append(newToken)
  }

  func setFinishedDesignToken(newToken: FinishedDesignToken) {
    finishedDesignTokens = finishedDesignTokens.filter { token in
      token.storeId != newToken.storeId
    }
    finishedDesignTokens.append(newToken)
  }


  private static func fileURL() throws -> URL {
    try FileManager.default.url(for: .documentDirectory,
                                   in: .userDomainMask,
                                   appropriateFor: nil,
                                   create: false)
      .appendingPathComponent("tokens.json")
  }

  static func load(completion: @escaping (Result<TokenStoreFormat, Error>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      do {
        let fileURL = try fileURL()
        guard let file = try? FileHandle(forReadingFrom: fileURL) else {
          DispatchQueue.main.async {
            completion(.success(TokenStoreFormat.init()))
          }
          return
        }
        let tokens = try JSONDecoder().decode(TokenStoreFormat.self, from: file.availableData)
        DispatchQueue.main.async {
          completion(.success(tokens))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  static func save(tokens: TokenStoreFormat, completion: @escaping (Result<Bool, Error>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      do {
        let data = try JSONEncoder().encode(tokens)
        let outfile = try fileURL()
        try data.write(to: outfile)
        DispatchQueue.main.async {
          completion(.success(true))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }
}
