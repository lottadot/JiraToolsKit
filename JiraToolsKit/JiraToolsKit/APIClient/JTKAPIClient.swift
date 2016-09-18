//
//  JTKAPIClient.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The structure returned as of the result of an `JTKAPIClient` request
public struct JTKAPIClientResult {
    public var success = false
    public var error: NSError? = nil
    public var data: AnyObject? = nil
}

/// The Protocol used to provider `JTKAPIClientOperation`'s with required data.
public protocol JTKAPIClientOperatonDataProvider {
    func clientUsername() -> String
    func clientPassword() -> String
    func clientEndPoint() -> URL
}

/// The Jira Tools API Client
open class JTKAPIClient {
    
    fileprivate var endpointURL: URL!
    fileprivate var queue: OperationQueue!
    fileprivate var username: String!
    fileprivate var password: String!
    
    public init(endpointUrl: String, username: String, password: String) {

        guard let url = URL.init(string: endpointUrl) else {
            fatalError()
        }
        
        self.endpointURL = url
        self.username = username
        self.password = password
        
        self.queue = OperationQueue.init()
        self.queue.maxConcurrentOperationCount = 1
    }
    
    /// Get a Jira Issue.
    open func getIssue(_ issueIdOrKey: String, completion: @escaping (_ result: JTKAPIClientResult) -> ()) {
        // /rest/api/2/issue/{issueIdOrKey}

        // http://localhost:2990/jira/rest/api/2/issue/TP1-1
        
        let op = JTKAPIClientFetchIssueOperation.init(dataProvider: self, issueIdOrKey: issueIdOrKey)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.isCancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult(success: nil != strongOp.issue, error: strongOp.error, data: strongOp.issue)
            completion(apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Get a Jira Issue's Transitions
    open func getIssueTransitions(_ issue: JTKIssue, completion: @escaping (_ result: JTKAPIClientResult) -> ()) {
        // /rest/api/2/issue/{issueIdOrKey}/transitions

        // http://localhost:2990/jira/rest/api/2/issue/TP1-1/transitions
        
        let op = JTKAPIClientFetchIssueTransitions(dataProvider: self, issueIdOrKey: issue.key)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.isCancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult(success: (nil == strongOp.error), error: strongOp.error, data: strongOp.transitions as AnyObject?)
            completion(apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Update a Jira Issue by applying a `JTKTransition` Transition. Can post an optional comment.
    open func transitionIssue(_ issue: JTKIssue, transition: JTKTransition, comment: String?, completion: @escaping (_ result: JTKAPIClientResult) -> ()) {
        
        let op = JTKAPIClientTransitionIssue(dataProvider: self, issue: issue, transition: transition, commentBody: comment)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.isCancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult(success: nil == strongOp.error, error: strongOp.error, data: nil)
            completion(apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Update a Jira Issue by posting a comment.
    open func commentOnIssue(_ issue: JTKIssue, comment: String?, completion: @escaping (_ result: JTKAPIClientResult) -> ()) {
        
        let op = JTKClientIssueComment(dataProvider: self, issue: issue, commentBody: comment)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.isCancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult(success: nil == strongOp.error, error: strongOp.error, data: nil)
            completion(apiResult)
        }
        
        queue.addOperation(op)
    }
}

// MARK: - JTKAPIClientOperatonDataProvider

extension JTKAPIClient: JTKAPIClientOperatonDataProvider {
    
    public func clientUsername() -> String {
        return self.username
    }
    
    public func clientPassword() -> String {
        return self.password
    }
    
    public func clientEndPoint() -> URL {
        return self.endpointURL
    }
}
