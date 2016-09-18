//
//  JTKAPIClientTransitionIssue.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to Transition a Jira Issue to a different status. Can post optional comment.
open class JTKAPIClientTransitionIssue: JTKAPIClientOperation {

    fileprivate var issue: JTKIssue?
    fileprivate var transition: JTKTransition?
    fileprivate var commentBody: String?
   
    fileprivate typealias JTKAPIClientTransitionIssueComment = [ String : AnyObject]
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issue: JTKIssue, transition: JTKTransition, commentBody: String?) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issue = issue
        self.transition = transition
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
            let transitionToChangeTo = self.transition,
            let requestURL = URL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/transitions?expand=transitions.fields") else {
            
            self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
            self.cancel()
            
            return
        }
        
        let urlRequest = NSMutableURLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var uploadDictionary = Dictionary<String, AnyObject>()
        var updates = Dictionary<String, AnyObject>()
        var comments:[JTKAPIClientTransitionIssueComment] = []
        let fields = Dictionary<String, AnyObject>()
        
        if let body = self.commentBody {
            let comment:JTKAPIClientTransitionIssueComment = [ "body" : body as AnyObject ]
            let add:[ String: AnyObject] = [ "add" : comment as AnyObject ]
            comments.append(add)
        }
        
        if comments.count > 0 {
            updates["comment"] = comments as AnyObject?
        }
        
        if updates.keys.count > 0 {
            uploadDictionary["update"] = updates as AnyObject?
        }
        
        //fields["resolution"] = [ "name" : "Ready For QA"]
        //fields["assignee"] = [ "name" : "" ]
        
        if fields.keys.count > 0 {
            uploadDictionary["fields"] = fields as AnyObject?
        }
        
        let transitionDict:[String : AnyObject] = [ "id" : transitionToChangeTo.transitionId as AnyObject ]
        uploadDictionary["transition"] = transitionDict as AnyObject?
        // po print(uploadDictionary)
        
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


