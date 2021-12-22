//
//  ViewController.swift
//  Printess Editor
//
//  Created by Bastian Kröger on 30.04.21.
//  Copyright © 2021 Bastian Kröger. All rights reserved.
//

import UIKit
import WebKit

class EditorViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {

  var templateName: String = ""
  var templateToken: String?
  var bearerToken: String = ""

  var exitCallback: ((_ token: String) -> ())?
  var addToBasketCallback: ((_ token: String, _ thumbnail: String) -> ())?

  @IBOutlet
  var webView: WKWebView?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let webView = webView else { return }

    let myURL = URL(string: "https://printess-editor.s3.eu-central-1.amazonaws.com/v/nightly/printess-editor/buyer-test-ios.html")
    let myRequest = URLRequest(url: myURL!)

    let contentController = webView.configuration.userContentController
    contentController.add(self, name: "backButtonCallback")
    contentController.add(self, name: "addToBasketCallback")

    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.load(myRequest)
  }

  // startPrintess(token, templateName, templateVersion, basketId, shopUserId, backCallback, addToBasketCallback)
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    var usedTemplateName = templateName.replacingOccurrences(of: "'", with: "\\\'")
    if let token = templateToken {
      usedTemplateName = token
    }
    let js = "startPrintess('\(bearerToken)', '\(usedTemplateName)', 'published', 'someBasketId', 'someShopUserId', 'backButtonCallback', 'addToBasketCallback')"

    webView.evaluateJavaScript(js, completionHandler: { (_, error) in
      if let evaluationError = error {
        print("Error : \(evaluationError)")
      }
    })
  }

  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {

    let alertController = UIAlertController(title: message, message: nil,
                                          preferredStyle: UIAlertController.Style.alert)

    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) {
      _ in completionHandler()}
    )
    alertController.addAction(UIAlertAction(title: "Back to list", style: UIAlertAction.Style.default) {
        _ in completionHandler()
        self.dismiss(animated: true, completion: nil)
      }
    )

    self.present(alertController, animated: true, completion: {})
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "backButtonCallback" {
      guard let saveToken = message.body as? String else { return }
      if let callback = self.exitCallback {
        callback(saveToken)
      }
    } else if message.name == "addToBasketCallback" {
      guard let dict = message.body as? [String: String] else { return }
      guard let saveToken = (dict["token"]) else { return }
      guard let imageUrl = (dict["imageUrl"]) else { return }
      if let callback = self.addToBasketCallback {
        callback(saveToken, imageUrl)
      }
    }
  }
}
