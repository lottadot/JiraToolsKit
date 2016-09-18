//
//  JTKClientIssueComment.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/14/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to post a comment to a JIRA Issue.
open class JTKClientIssueComment: JTKAPIClientOperation {
    
    /// The Issue to Post to.
    fileprivate var issue: JTKIssue?
    
    /// The Comment Text to Post.
    fileprivate var commentBody: String!
    
    fileprivate typealias JTKAPIClientTransitionIssueComment = [ String : AnyObject]
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issue: JTKIssue, commentBody: String?) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issue = issue
        self.commentBody = commentBody
    }
    
    open override func start() {
        queuePriority = .normal
        
        if isCancelled {
            isFinished = true
            return
        }
        
        // /rest/api/2/issue/{issueIdOrKey}/transitions
        guard let issueId = issue?.issueId,
            let requestURL = URL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/comment") else {
                
                self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
                self.cancel()
                
                return
        }
        
        let urlRequest = NSMutableURLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var uploadDictionary = Dictionary<String, AnyObject>()
        uploadDictionary["body"] = self.commentBody as AnyObject?

        var uploadData: Data
        
        do {
            uploadData = try JSONSerialization.data(withJSONObject: uploadDictionary, options: [])
        } catch let error as NSError {
            self.error = error
            isFinished = true
            return
        }
        
        let task = urlSession.uploadTask(with: urlRequest as URLRequest, from: uploadData)
        task.resume()
    }
    
    override func handleResponse() {
        if isCancelled {
            return
        }
        
        isFinished = true
        return
    }
}
