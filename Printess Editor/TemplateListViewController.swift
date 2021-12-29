//
//  CatalogListViewController.swift
//  Printess Editor
//
//  Created by Tobias Klonk on 07.12.21.
//  Copyright © 2021 Printess GmbH & Co. KG. All rights reserved.
//

import UIKit

enum ListSections: Int {
  case templates = 0
  case basket = 1
}

class TemplateListViewController: UIViewController {

  var templates: [Template] = []
  var images: [URL: UIImage] = [:]
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

    switch ListSections(rawValue: indexPath.section) {
    case ListSections.templates?:
      let text = templates[indexPath.row].name
      let url = templates[indexPath.row].thumbnailURL
      return configureTemplateCell(tableCell: templateCell, title: text, url: url, indexPath: indexPath)
    case ListSections.basket?:
      let text = tokenStore.finishedDesignTokens[indexPath.row].name
      let url = tokenStore.finishedDesignTokens[indexPath.row].thumbnailURL
      return configureTemplateCell(tableCell: templateCell, title: text, url: url, indexPath: indexPath)
    default:
      return cell
    }
  }

  func configureTemplateCell(tableCell: TemplateTableViewCell,
                             title: String?,
                             url: String?,
                             indexPath: IndexPath) -> UITableViewCell {
    tableCell.titleLabel!.text = title
    if let url = URL(string: url ?? "") {
      if images[url] != nil {
        tableCell.thumbnailView?.image = images[url]
      } else {
        tableCell.thumbnailView?.image = nil
        URLSession.shared.dataTask(with: url) { (data, _, _) in
          DispatchQueue.main.async {
            guard let data = data else { return }
            self.images[url] = UIImage(data: data)
            self.tableView?.reloadRows(at: [indexPath], with: .fade)
          }
        }.resume()
      }
    }

    return tableCell
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch ListSections(rawValue: section) {
    case ListSections.templates?:
      return templates.count
    case ListSections.basket?:
      return tokenStore.finishedDesignTokens.count
    default:
      return 0
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch ListSections(rawValue: section) {
    case ListSections.templates?:
      return "Templates"
    case ListSections.basket?:
      return "Basket"
    default:
      return ""
    }
  }

  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if let view = view as? UITableViewHeaderFooterView {
      view.contentView.backgroundColor = UIColor.blue
      view.textLabel?.textColor = UIColor.white
    }
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
      guard let indexPath = tableView?.indexPathForSelectedRow else { return }

      let index = indexPath.row
      switch ListSections(rawValue: indexPath.section) {
      case ListSections.templates?:
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
          if (strongSelf.tableView?.numberOfSections ?? 0 > ListSections.basket.rawValue)  {
            strongSelf.tableView?.reloadSections(IndexSet([ListSections.basket.rawValue]), with: .none)
          } else {
            strongSelf.tableView?.reloadData()
          }
          strongSelf.dismiss(animated: true, completion: nil)
        }
      case ListSections.basket?:
        guard index < templates.count else { return }
        let token = tokenStore.finishedDesignTokens[index]
        editor.templateName = token.token
        editor.bearerToken = templateDataSource.bearerToken
        editor.exitCallback = { [weak self] token  in
          guard let strongSelf = self else { return }

          strongSelf.dismiss(animated: true, completion: nil)
        }

        editor.addToBasketCallback = { [weak self] newToken, newThumbnail  in
          guard let strongSelf = self else { return }
          strongSelf.tokenStore.setFinishedDesignToken(
            newToken: token.copy(token: newToken, thumbnailURL: newThumbnail)
          )
          if (strongSelf.tableView?.numberOfSections ?? 0 > ListSections.basket.rawValue)  {
            strongSelf.tableView?.reloadSections(IndexSet([ListSections.basket.rawValue]), with: .none)
          } else {
            strongSelf.tableView?.reloadData()
          }
          strongSelf.dismiss(animated: true, completion: nil)
        }
      default:
        return
      }

    default:
      return
    }
  }
}
