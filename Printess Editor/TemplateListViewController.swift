//
//  CatalogListViewController.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 07.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import UIKit

struct TemplateResponse: Codable {
  var uid: String
  var email: String
  var templates: [Template]

  enum CodingKeys: String, CodingKey {
    case uid
    case email = "e"
    case templates = "ts"
  }
}

struct Template: Codable {
  var id: Int
  var name: String
  var thumbnailURL: String
  var backgroundColor: String
  var w: Bool
  var p: Bool
  var d: Bool
  var hpv: Bool
  var hdv: Bool
  var ls: String
  var lp: String

  enum CodingKeys: String, CodingKey {
    case id
    case name = "n"
    case thumbnailURL = "turl"
    case backgroundColor = "bg"
    case w
    case p
    case d
    case hpv
    case hdv
    case ls
    case lp
  }
}

class TemplateListViewController: UIViewController {

  var templates: [Template] = []
  var images: [UIImage?] = []

  @IBOutlet
  var tableView: UITableView?

  @IBOutlet
  var errorView: UIView?

  @IBOutlet
  var errorTitle: UILabel?

  @IBOutlet
  var errorDetail: UILabel?

  @IBOutlet
  var loadingView: UIView?

  override func viewDidLoad() {

    super.viewDidLoad()

    loadTemplatesList()
  }

  func loadTemplatesList() {
    guard let url = URL.init(string: "https://api.printess.com/templates/global/load") else { return }

    let bearerToken = """
    eyJhbGciOiJSUzI1NiIsImtpZCI6InByaW50ZXNzLXNhYXMtYWxwaGEiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJSV0g5NzdoYjFqUzdi\
    R3M4aXNPdHNvQnZySnUyIiwianRpIjoiMzJwTm9nTzUwQkxBRXh4OXVYRzlsRzhjcXJ3ajJQT0ciLCJyb2xlIjoic2hvcCIsIm5iZiI\
    6MTYxODk4NjE4MCwiZXhwIjoxOTM0MzQ2MTgwLCJpYXQiOjE2MTg5ODYxODAsImlzcyI6IlByaW50ZXNzIEdtYkggJiBDby5LRyIsIm\
    F1ZCI6InByaW50ZXNzLXNhYXMifQ.XjVlVPzLwIYFwNNrxfWhIgCprjUHAJXsD7nz_qI9WSWhIu-DY9fwSKVQNB_QKiuRNkIzCxzgfi\
    ZSe3d3k8Rd88_ixPjw7e3N0O1gyciLzwQQ0nWoJiwXditT1CZp9LhwxR7SGUe6hJK_gLBh_boeeN0jVlwV45EFIHSU7AzeeKC7_1WJA\
    cb0-qpMU6TWAsamj1MvzDTAbNePMPJ6sqULneIUpjME42V3cfCu_x0FD8QMZIkVWpnjZqatVPstmfzsoaTpFCYqPcnFLEEmbfL0KFdi\
    r0ieodC69Tl4T4183cqzAa8qrF6kYeRK31OjBUh8rLdgDg4mrw7Yyl1_ndRqe366Qrfym_xM0C9Lj2tKB7bduIftlfkpdRk30M2TqmD\
    HaM1Dq8He8X2PHvd5uy9rGj-1rWugWbEhaXiyyoQJWzv1apOXVNz2yecc4QHYQyNnEVuAadLWkX5YaNZhBU7CSpWffSwzPeEfLEHh57\
    j74J11J_BT89KzKtjo90uhPk4_MAE0qj6QbYUL_16vmajiAQZJicPifTI4ByoMdEdJ7pvHHvfUdBYQtHHfjZd7d60k7HaZFbRP5RWs7\
    H3ZfQF5sazrrHesEWngi_WjgrXqNRdfVxhbs3tcSLfAfm_loJJHxKILGL5JiV9WJCsksKkMatLoCmvCdHHS3cn2NYIx3UQ
    """

    var request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
    request.httpMethod = "POST"
    request.setValue("*/*", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in

      guard error == nil else {
        print("Error loading catalog: \(error!.localizedDescription)")
        DispatchQueue.main.async {
          self.showError(title: "Network Error", details: error!.localizedDescription)
          self.loadingView?.isHidden = true
        }
        return
      }

      if let response = response as? HTTPURLResponse {
        if response.statusCode >= 200 && response.statusCode < 300 {
          print("Loaded catalog with status: \(response.statusCode)")
        } else {
          DispatchQueue.main.async {
            self.showError(title: "HTTP Error \(response.statusCode)", details: HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
            self.loadingView?.isHidden = true
          }
          print("Error loading catalog: \(response.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
          return
        }
      }

      guard let responseData = data else {
        DispatchQueue.main.async {
          self.showError(title: "internal Error", details: "No data received")
          self.loadingView?.isHidden = true
        }
        return
      }

      let decoder = JSONDecoder()
      do {
        let response = try decoder.decode(TemplateResponse.self, from: responseData)

        self.templates = response.templates
        self.images = [UIImage?](repeating: nil, count: response.templates.count)

        DispatchQueue.main.async {
          self.loadingView?.isHidden = true
          self.tableView?.reloadData()
        }

      } catch {
        DispatchQueue.main.async {
          self.showError(title: "parsing Error", details: error.localizedDescription)
          self.loadingView?.isHidden = true
        }

        print("error trying to convert data to JSON")
        print(error)
      }
    }

    loadingView?.isHidden = false
    dataTask.resume()
  }

  func showError(title: String, details: String) {
    errorTitle?.text = title
    errorDetail?.text = details

    errorView?.isHidden = false
  }

  @IBAction func tryAgainButtonTap() {
    errorView?.isHidden = true
    loadTemplatesList()
  }
}

// MARK: - Table View DataSource
extension TemplateListViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath as IndexPath)

    guard let templateCell = cell as? TemplateTableViewCell else { return cell }

    templateCell.titleLabel!.text = templates[indexPath.row].name
    if images[indexPath.row] != nil {
      templateCell.thumbnailView?.image = images[indexPath.row]
    } else {
      URLSession.shared.dataTask(with: URL(string: templates[indexPath.row].thumbnailURL)!) { (data, _, _) in
        DispatchQueue.main.async {
          guard let data = data else { return }
          self.images[indexPath.row] = UIImage(data: data)
          self.tableView?.reloadRows(at: [indexPath], with: .fade)
        }
      }.resume()
    }
    return cell
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return templates.count
  }
}

// MARK: - Table View Delegate
extension TemplateListViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    guard indexPath.row < templates.count else { return }

    let template = templates[indexPath.row]
    print("selected template \(template.id) : \(template.name)")
  }
}
