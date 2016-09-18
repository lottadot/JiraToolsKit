//
//  JTKAPIClientFetchIssueTransitions.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to Get a JIRA Issue's Transitions (from Workflows)
open class JTKAPIClientFetchIssueTransitions: JTKAPIClientOperation {
    
    open var transitions: [JTKTransition] = []
    fileprivate var issueIdOrKey: String?
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issueIdOrKey: String) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issueIdOrKey = issueIdOrKey
    }
    
    open override func start() {
        queuePriority = .normal
        
        if isCancelled {
            isFinished = true
            return
        }
        
        // /rest/api/2/issue/{issueIdOrKey}/transitions
        guard let issueId = issueIdOrKey, let requestURL = URL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/transitions") else {
            
            self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
            self.cancel()
            
            return
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "GET"

        let task = urlSession.dataTask(with: urlRequest)
        task.resume()
    }
    
    override func handleResponse() {
        do {
            
            if isCancelled {
                return
            }
            
            guard let json:[String : AnyObject] = try JSONSerialization.jsonObject(with: receivedData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : AnyObject] else {
                    
                    self.error = JTKAPIClientNetworkError.createError(1002, statusCode: 1002, failureReason: "Could not convert JSON")
                    self.cancel()
                    
                    return
            }
            
            guard let serviceTransitions = json["transitions"] as? [[String: AnyObject]] else {
                self.error = JTKAPIClientNetworkError.createError(1003, statusCode: 1003, failureReason: "Could not convert Issue JSON")
                self.cancel()
                isFinished = true

                return
            }
            
            for serviceTransition in serviceTransitions {                
                if let transition = JTKTransition.withDictionary(serviceTransition) {
                    transitions.append(transition)
                }
            }
            
            isFinished = true
            return
        }
        catch (_) {
            self.error = JTKAPIClientNetworkError.createError(1002, statusCode: 1002, failureReason: "Error Converting JSON")
            self.cancel()
            return
        }
    }
    
}
