//
//  JTKAPIClientOperation.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// This is a base `NSOpertaion` class. All "Network Opertions" should inherit from this class.
open class JTKAPIClientOperation: Operation, URLSessionDataDelegate {
    
    var receivedData = NSMutableData()
    var error: NSError?
    
    let endpointURL: URL
    var dataProvider: JTKAPIClientOperatonDataProvider?
    
    fileprivate var swiftKVOFinished = false
    
    var urlSession: Foundation.URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        
        if let provider = self.dataProvider {
            // https://www.base64encode.org/
            let userPasswordString = "\(provider.clientUsername()):\(provider.clientPassword())"
            let userPasswordData = userPasswordString.data(using: String.Encoding.ascii)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue:0))
            let authString = "Basic \(base64EncodedCredential)"
            configuration.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        return Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    open override var isAsynchronous: Bool {
        return false
    }
    
    open override var isFinished: Bool {
        get {
            return swiftKVOFinished
        }
        set {
            self.willChangeValue(forKey: "isFinished")
            swiftKVOFinished = newValue
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    //    init(url: NSURL, result: NetworkResult) {
    //        self.endpointURL = url
    //        self.operationResult = result
    //        super.init()
    //    }
    
    public init(url: URL) {
        self.endpointURL = url
        //self.operationResult = result
        super.init()
    }
    
    func handleResponse() {
        fatalError("Subclasses should Override this")
    }
    
    // MARK: NSURLSessionDataDelegate
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if isCancelled {
            isFinished = true
            dataTask.cancel()
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("Did not receive NSHTTPURLResponse")
        }
        
        if isSuccessfulHTTPStatusCode(httpResponse.statusCode) {
            completionHandler(.allow)
        } else {
            self.error = JTKAPIClientNetworkError.createError(JTKAPIClientNetworkError.Code.httpError.rawValue, statusCode: httpResponse.statusCode, failureReason: "HTTP Status Invalid")
            completionHandler(.cancel)
        }
    }
    
    fileprivate func isSuccessfulHTTPStatusCode(_ code: Int) -> Bool {
        return (code >= 200 && code < 300)
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isCancelled {
            isFinished = true
            dataTask.cancel()
            return
        }
        
        receivedData.append(data)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if isCancelled {
            self.receivedData = NSMutableData()
            isFinished = true
            task.cancel()
            return
        }
        
        if let httpError = self.error , httpError.domain == JTKAPIClientNetworkError.ErrorDomain
                && httpError.code == JTKAPIClientNetworkError.Code.httpError.rawValue {
            self.receivedData = NSMutableData()
            isFinished = true
            task.cancel()
            return
        }
        
        if error != nil {
            self.error = error as NSError?
            isFinished = true
            return
        }
        
        handleResponse()
        
        isFinished = true
    }
}

