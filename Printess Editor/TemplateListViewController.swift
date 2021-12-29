//
//  CatalogListViewController.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 07.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import UIKit

class TemplateListViewController: UIViewController {

  var templates: [Template] = []
  var images: [UIImage?] = []
  var tokenStore: TokenStore
  var templateDataSource: TemplateDataSource

  required init?(coder: NSCoder) {
    tokenStore = TokenStore.init()
    templateDataSource = TemplateDataSource.init()
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

  override func viewDidLoad() {

    super.viewDidLoad()

    loadTemplateData()
  }

  func loadTemplateData() {
    self.loadingView?.isHidden = false

    templateDataSource.loadTemplatesList { result in
      switch result {
      case .success(let loadedTemplates):
        self.templates = loadedTemplates
        self.loadingView?.isHidden = true
        self.errorView?.isHidden = true
        self.images = [UIImage?](repeating: nil, count: loadedTemplates.count)
        self.tableView?.reloadData()
        
      case .failure(let error):
        self.loadingView?.isHidden = true
        self.errorView?.isHidden = false
        self.showError(title: error.title, details: error.details)
        print("Error loading templates \(error)")
      }
    }
  }

  func showError(title: String, details: String) {
    errorTitle?.text = title
    errorDetail?.text = details

    errorView?.isHidden = false
  }

  @IBAction func tryAgainButtonTap() {
    errorView?.isHidden = true
    loadTemplateData()
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
      editor.bearerToken = templateDataSource.bearerToken
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
