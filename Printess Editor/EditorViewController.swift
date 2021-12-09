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
  var bearerToken: String = ""

  var webView: WKWebView!

  override func loadView() {
    let contentController = WKUserContentController()
    contentController.add(self, name: "backButtonCallback")
    contentController.add(self, name: "addToBasketCallback")

    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = contentController
    webView = WKWebView(frame: .zero, configuration: webConfiguration)
    webView.uiDelegate = self
    //self.view.addSubview(webView)
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let myURL = URL(string: "https://printess-editor.s3.eu-central-1.amazonaws.com/v/nightly/printess-editor/buyer-test-ios.html")
    let myRequest = URLRequest(url: myURL!)
    webView.navigationDelegate = self
    webView.load(myRequest)
  }

  // startPrintess(token, templateName, templateVersion, basketId, shopUserId, backCallback, addToBasketCallback)
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let sanitizedTemplateName = templateName.replacingOccurrences(of: "'", with: "\\\'")
    let js = "startPrintess('\(bearerToken)', '\(sanitizedTemplateName)', 'published', 'someBasketId', 'someShopUserId', 'backButtonCallback', 'addToBasketCallback')";

    self.webView.evaluateJavaScript(js, completionHandler: { (_, error) in
      if let evaluationError = error {
        print("Error : \(evaluationError)")
      }
    })
  }

  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {

    let alertController = UIAlertController(title: message, message: nil,
                                          preferredStyle: UIAlertController.Style.alert);

    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) {
      _ in completionHandler()}
    );
    alertController.addAction(UIAlertAction(title: "Back to list", style: UIAlertAction.Style.default) {
        _ in completionHandler()
        self.dismiss(animated: true, completion: nil)
      }
    );

    self.present(alertController, animated: true, completion: {});
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "backButtonCallback" {
      let saveToken = message.body
      print("Save Token: \(saveToken)")
      dismiss(animated: true, completion: nil)
    } else if message.name == "addToBasketCallback" {
      let dict = message.body as? [String: String]
      let saveToken = (dict?["token"])!
      let imageUrl = (dict?["imageUrl"])!
      print("Save Token: \(saveToken), thumbnail url: \(imageUrl)")
    }
  }
}
