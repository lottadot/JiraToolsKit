//: Playground - noun: a place where people can play

import Cocoa
import JiraToolsKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let endPoint = "http://localhost:2990/jira"
let username = "admin"
let password = "admin"
let issueId = "TES-1"

var issue:JTKIssue? = nil

let api = JTKAPIClient.init(endpointUrl: endPoint, username: username, password: password)

print("getting issue")
api.getIssue(issueId) { (result) in
    print("got issue or something")
    if let error = result.error {
        print("Failure: \(error.localizedDescription)")
    } else {
        print("Success: \(result.data)")
        if let responseData = result.data, let foundIssue:JTKIssue = responseData as? JTKIssue {
            
            issue = foundIssue
            
            print("issue: \(foundIssue.description)")
            
            api.getIssueTransitions(foundIssue, completion: { (result) in
                
                if result.success {
                    
                    
                    if let responseData = result.data, let transitions:[JTKTransition] = responseData as? [JTKTransition] {
                        print("transitions: \(transitions)")
                    }
                } else {
                    print("transitions failed")
                    
                }
                PlaygroundPage.current.finishExecution()
                
            })
        } else {
            PlaygroundPage.current.finishExecution()
        }
    }
}
