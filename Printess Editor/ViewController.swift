//
//  ViewController.swift
//  Printess Editor
//
//  Created by Bastian Kröger on 30.04.21.
//  Copyright © 2021 Bastian Kröger. All rights reserved.
//

import UIKit
import WebKit


class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
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
        
        let myURL = URL(string:"https://printess-editor.s3.eu-central-1.amazonaws.com/v/nightly/printess-editor/buyer-test-ios.html")
        let myRequest = URLRequest(url: myURL!)
        webView.navigationDelegate = self
        webView.load(myRequest)
    }
    
    // startPrintess(token, templateName, templateVersion, basketId, shopUserId, backCallback, addToBasketCallback)
    func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!) {
        print("loaded")
        self.webView.evaluateJavaScript("startPrintess('eyJhbGciOiJSUzI1NiIsImtpZCI6InByaW50ZXNzLXNhYXMtYWxwaGEiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiJSV0g5NzdoYjFqUzdiR3M4aXNPdHNvQnZySnUyIiwianRpIjoiMzJwTm9nTzUwQkxBRXh4OXVYRzlsRzhjcXJ3ajJQT0ciLCJyb2xlIjoic2hvcCIsIm5iZiI6MTYxODk4NjE4MCwiZXhwIjoxOTM0MzQ2MTgwLCJpYXQiOjE2MTg5ODYxODAsImlzcyI6IlByaW50ZXNzIEdtYkggJiBDby5LRyIsImF1ZCI6InByaW50ZXNzLXNhYXMifQ.XjVlVPzLwIYFwNNrxfWhIgCprjUHAJXsD7nz_qI9WSWhIu-DY9fwSKVQNB_QKiuRNkIzCxzgfiZSe3d3k8Rd88_ixPjw7e3N0O1gyciLzwQQ0nWoJiwXditT1CZp9LhwxR7SGUe6hJK_gLBh_boeeN0jVlwV45EFIHSU7AzeeKC7_1WJAcb0-qpMU6TWAsamj1MvzDTAbNePMPJ6sqULneIUpjME42V3cfCu_x0FD8QMZIkVWpnjZqatVPstmfzsoaTpFCYqPcnFLEEmbfL0KFdir0ieodC69Tl4T4183cqzAa8qrF6kYeRK31OjBUh8rLdgDg4mrw7Yyl1_ndRqe366Qrfym_xM0C9Lj2tKB7bduIftlfkpdRk30M2TqmDHaM1Dq8He8X2PHvd5uy9rGj-1rWugWbEhaXiyyoQJWzv1apOXVNz2yecc4QHYQyNnEVuAadLWkX5YaNZhBU7CSpWffSwzPeEfLEHh57j74J11J_BT89KzKtjo90uhPk4_MAE0qj6QbYUL_16vmajiAQZJicPifTI4ByoMdEdJ7pvHHvfUdBYQtHHfjZd7d60k7HaZFbRP5RWs7H3ZfQF5sazrrHesEWngi_WjgrXqNRdfVxhbs3tcSLfAfm_loJJHxKILGL5JiV9WJCsksKkMatLoCmvCdHHS3cn2NYIx3UQ', 'Card', 'draft', 'someBasketId', 'someShopUserId', 'backButtonCallback', 'addToBasketCallback')" , completionHandler: { (any, error) in
            
            if let evaluationError = error {
                print("Error : \(evaluationError)")
            }
        })
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name == "backButtonCallback") {
            let saveToken = message.body
            print("Save Token: \(saveToken)")
        } else if (message.name == "addToBasketCallback") {
            let dict = message.body as? Dictionary<String, String>
            let saveToken = (dict?["token"])!
            let imageUrl = (dict?["imageUrl"])!
            print("Save Token: \(saveToken), thumbnail url: \(imageUrl)")
        }
    }
    
}
