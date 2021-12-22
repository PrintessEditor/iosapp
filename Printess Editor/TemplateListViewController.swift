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
  var tokenStore: TokenStore

  required init?(coder: NSCoder) {
    tokenStore = TokenStore.init()
    super .init(coder: coder)
  }

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

  let bearerToken = """
  eyJhbGciOiJSUzI1NiIsImtpZCI6InByaW50ZXNzLXNhYXMtYWxwaGEiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJneTh6NDRFbUxpWjB2clV\
  LclhsV3RpWlkxNUQyIiwianRpIjoibnl4NGJFZlZ5SVVvM1NkR2dYVnEtempzS3hlb0FYZUYiLCJyb2xlIjoic2hvcCIsIm5iZiI6MTYxO\
  Dg2ODUxMSwiZXhwIjoxOTM0MjI4NTExLCJpYXQiOjE2MTg4Njg1MTEsImlzcyI6IlByaW50ZXNzIEdtYkggJiBDby5LRyIsImF1ZCI6InB\
  yaW50ZXNzLXNhYXMifQ.CuI6zdCzBm2y3t2GBD4pYdyztFzSeSEfdGIDBeiZIYvzQckB9oEB1Z4hDkBCGZGBtTMRyuHCbkwZgO6uxD-Zya\
  hifiqrIqfqSqtFEGwgZUF87TvV_KlrYWBzDNTaUIQjr-yUoxLkdnEMzh-3D5qV8UKWIDfqwnYd0KhJiB2K9CSg82_etnz5Lk-altMDAT8b\
  1AnzxcjRAJ9_b6-CAJFXG6AAnfdl7c_PS3sD-RPOkJ75Ta2glfikIiGZzfh09bn5Ptk7rucRdxUsLCLR6m5nUFpZbV77d2eqRw8pT4Kl-5\
  by5gvMr1wUBGbEx751CNXtcCO3qk4uNnptfZ3yCpK0Z2FOo2CYLZBzmDiYCrdFV5U-_SZuVOEl8vk0uR3tj_PQci_R7MlQOjpB4NjlKckQ\
  2zGvBSKNeupuiC71UZ2AT5BFlbqMsuYu0necIztyKiWsBmbniVlLe-v7_paP1N4nS2haD2n4s4N_CenJqijtPggWsITfoLm2twCOe7yNB5\
  IH7bcEFv1-MbANuaFmJVLOcTfc89Zi-mkidaHV-n_9qXypzyB-ih_27YBNluRGwcHgTEkbJecSssMfvHSt1MUuqX-8gbl7bhFGryqHA2gM\
  oSZNDW0LkSYig2K3poOUumD67vtYdNSPLhOmDK4ck9wLAKLOvk6dtywg2qfV-58_VbI
  """

  override func viewDidLoad() {

    super.viewDidLoad()

    loadTemplatesList()
  }

  func loadTemplatesList() {
    guard let url = URL.init(string: "https://api.printess.com/templates/global/load") else { return }

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

// MARK: - prepare Segues
extension TemplateListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case "Editor":
      guard let editor = segue.destination as? EditorViewController else { return }
      guard let index = tableView?.indexPathForSelectedRow?.row else { return }
      guard index < templates.count else { return }
      let template = templates[index]
      editor.templateName = template.name
      editor.bearerToken = bearerToken
      if let continuationToken = tokenStore.continuationToken(for: template.name) {
        editor.templateToken = continuationToken.token
      }

      editor.exitCallback = { [weak self] token  in
        guard let strongSelf = self else { return }
        strongSelf.tokenStore.setContinuationToken(
          newToken: ContinuationToken.init(id: template.id, name: template.name, token: token)
        )
        strongSelf.dismiss(animated: true, completion: nil)
      }

      editor.addToBasketCallback = { [weak self] token, thumbnail  in
        guard let strongSelf = self else { return }
        strongSelf.tokenStore.setFinishedDesignToken(
          newToken: FinishedDesignToken.init(id: template.id, name: template.name,
                                             token: token, thumbnailURL: thumbnail,
                                             backgroundColor: template.backgroundColor)
        )
        strongSelf.dismiss(animated: true, completion: nil)
      }
    default:
      return
    }
  }
}
