//
//  SVGWebRenderer.swift
//  SVGWebRenderer
//
//  Created by LU JIAMENG on 19/4/2020.
//

import UIKit
import WebKit
import Alamofire
import Kingfisher
import CryptoSwift

extension UIView {
    func takeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let image = image {
            return image
        }
        return UIImage()
    }
}

extension UIImageView {
    public func setSVGImage(_ svgString: String, completion: ((UIImage?) -> Void)? = nil) {
        let size = self.frame.size
        SVGRenderer.shared().renderSVG(svgString: svgString, size: size) { [weak self] (image) in
            self?.image = image
            if let completion = completion {
                completion(image)
            }
        }
    }

    public func setImage(_ url: URL?, placeholder: UIImage?, completion: ((UIImage?) -> Void)? = nil) {
        let size = self.frame.size
        if SVGRenderer.shared().isCachedSVG(url) {
            SVGRenderer.shared().renderSVG(withUrl: url, size: size) { [weak self] (image) in
                self?.image = image
                if let completion = completion {
                    completion(image)
                }
            }
        } else {
            self.kf.setImage(with: url, placeholder: placeholder) { [weak self] (image, _, _, _) in
                if image == nil {
                    SVGRenderer.shared().renderSVG(withUrl: url, size: size) { (image) in
                        self?.image = image
                        if let completion = completion {
                            completion(image)
                        }
                    }
                } else {
                    if let completion = completion {
                        completion(image)
                    }
                }
            }
        }
    }
}

class SVGRenderRequest {
    var key: String
    var svgString: String
    var size: CGSize
    var handler: (UIImage?) -> Void

    init(svgString: String, size: CGSize, handler: @escaping (UIImage?) -> Void) {
        self.svgString = svgString
        self.size = size
        self.handler = handler
        self.key = svgString.sha3(.sha256)
    }
}

public class SVGRenderer: NSObject {
    private static var renderer: SVGRenderer = {
        let renderer = SVGRenderer()
        return renderer
    }()

    let cacher: SVGCacher
    let fileCacher: SVGFileCacher
    let webview: WKWebView
    var renderRequests: [String: SVGRenderRequest] = [:]
    var currentRequestKey: String?
    var requestQueue = [String]() {
        didSet {
            processRequestQueue()
        }
    }

    private override init() {
        self.cacher = SVGCacher()
        self.fileCacher = SVGFileCacher()
        self.webview = WKWebView()
        webview.scrollView.contentInsetAdjustmentBehavior = .never
        super.init()
        UIApplication.shared.keyWindow?.addSubview(webview)
        UIApplication.shared.keyWindow?.sendSubviewToBack(webview)
        webview.navigationDelegate = self
    }

    public class func shared() -> SVGRenderer {
        return renderer
    }

    public func isCachedSVG(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return fileCacher.getFileForUrl(url.absoluteString) != nil
    }

    public func renderSVG(svgString: String, size: CGSize = CGSize(width: 100, height: 100), handler: @escaping (UIImage?) -> Void) {
        let request = SVGRenderRequest(svgString: svgString, size: size, handler: handler)
        renderRequests[request.key] = request
        requestQueue.append(request.key)
    }

    public func renderSVG(withUrl url: URL?, size: CGSize = CGSize(width: 100, height: 100), handler: @escaping (UIImage?) -> Void) {
        guard let url = url else {
            return
        }
        if let svgString = fileCacher.getFileForUrl(url.absoluteString) {
            renderSVG(svgString: svgString, size: size, handler: handler)
            return
        } else {
            AF.download(url, method: .get).responseString { [weak self] (response) in
                switch response.result {
                case let .success(string):
                    self?.fileCacher.saveFile(string, forUrl: url.absoluteString)
                    self?.renderSVG(svgString: string, size: size, handler: handler)
                case .failure:
                    handler(nil)
                }
            }
        }
    }

    private func processRequestQueue() {
        guard requestQueue.count > 0,
            let currentRequestKey = requestQueue.first else {
            return
        }
        guard let request = renderRequests[currentRequestKey] else {
            requestQueue.removeFirst()
            return
        }
        processRequest(request: request)
    }

    private func processRequest(request: SVGRenderRequest) {
        if currentRequestKey != nil {
            return
        }
        if let image = cacher.getImageForKey(request.key) {
            request.handler(image)
            removeRequest(request.key)
            return
        }
        guard let range = request.svgString.range(of: "<svg") else {
            removeRequest(request.key)
            return
        }
        currentRequestKey = request.key
        webview.frame = CGRect(origin: CGPoint.zero, size: request.size)
        let htmlStart = """
                        <HTML><STYLE>body { margin: 0 !important; padding: 0 !important; }</STYLE>
                        <HEAD><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\"></HEAD><BODY>
                        """
        let htmlEnd = "</BODY></HTML>"
        let string = htmlStart + request.svgString[..<range.upperBound] + " width=\"100%\" height=\"100%\" " + request.svgString[range.upperBound...] + htmlEnd
        webview.loadHTMLString(String(string), baseURL: nil)
    }

    private func removeRequest(_ key: String) {
        renderRequests.removeValue(forKey: key)
        self.currentRequestKey = nil
        requestQueue.removeFirst()
    }
}

extension SVGRenderer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let currentRequestKey = self?.currentRequestKey,
                let request = self?.renderRequests[currentRequestKey],
                let image = self?.webview.takeScreenshot() else {
                return
            }
            self?.cacher.saveImage(image, forKey: request.key)
            request.handler(image)
            self?.removeRequest(request.key)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
}

class SVGCacher {
    let directoryPath: String
    var images = NSCache<NSString, UIImage>()

    init() {
        let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/svgs/"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryPath) {
            try? fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        self.directoryPath = directoryPath
    }

    func saveImage(_ image: UIImage, forKey key: String) {
        images.setObject(image, forKey: NSString(string: key))
        let filePath = directoryPath + key
        let url = URL(fileURLWithPath: filePath)
        try? image.pngData()?.write(to: url)
    }

    func getImageForKey(_ key: String) -> UIImage? {
        if let image = images.object(forKey: NSString(string: key)) {
            return image
        }
        let filePath = directoryPath + key
        let url = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: url),
            let image = UIImage(data: data) {
            images.setObject(image, forKey: NSString(string: key))
            return image
        }
        return nil
    }
}

class SVGFileCacher {
    let directoryPath: String
    var files = [String: String]()

    init() {
        let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "./svgs/files/"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryPath) {
            try? fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        self.directoryPath = directoryPath
    }

    func saveFile(_ file: String, forUrl url: String) {
        guard let fileData = file.data(using: .utf8) else {
            return
        }
        let key = url.sha3(.sha256)
        files[key] = file
        let filePath = directoryPath + key
        let fileUrl = URL(fileURLWithPath: filePath)
        try? fileData.write(to: fileUrl)
    }

    func getFileForUrl(_ url: String) -> String? {
        let key = url.sha3(.sha256)
        if let file = files[key] {
            return file
        }
        let filePath = directoryPath + key
        let fileUrl = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: fileUrl),
            let file = String(data: data, encoding: .utf8) {
            return file
        }
        return nil
    }
}

