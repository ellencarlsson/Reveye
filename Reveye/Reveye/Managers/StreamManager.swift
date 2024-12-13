//
//  NetworkManager.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-12-13.
//

import Foundation
import WebKit
import SwiftUI

class StreamManager {
    func checkVideoURL(urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
            let webView = WKWebView()
            webView.scrollView.isScrollEnabled = false
            webView.isOpaque = false
            webView.backgroundColor = UIColor(darkGray)
            webView.scrollView.backgroundColor = UIColor.black
            webView.layer.cornerRadius = 15
            webView.layer.masksToBounds = true
            return webView
        }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    

       
}




