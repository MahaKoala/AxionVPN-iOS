//
//  AxionAPI.swift
//  AxionVPN
//
//  Copyright © 2015 Axion. All rights reserved.
//

import UIKit

class AxionAPI: NSObject {
    class func isAuthenticated() -> Bool {
        let username = KeychainWrapper.stringForKey("axion_username")
        let password = KeychainWrapper.stringForKey("axion_password")
        
        // We assume that the values wouldn't be set unless they were valid. This must be enforced elsewhere.
        return username != nil && password != nil
    }
    
    class func checkCredentials(username: String, password: String, completionHandler: (validCredentials: Bool) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://axionvpn.com/api/get-info")!)
        let session = NSURLSession.sharedSession()
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"

        let params = "username=\(username)&password=\(password)"
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            let json = JSON(data: data!)
            
            let result = json["result"].intValue
            
            if result == 1 {
                // Invalid password
                completionHandler(validCredentials: false)
            } else if result == 2 {
                // Invalid username. We intentionally don't distinguish this in the UI to avoid making user enumeration trivial.
                completionHandler(validCredentials: false)
            } else if result == 3 {
                completionHandler(validCredentials: true)
            }
            
        }
        
        task.resume()
    }
    
    class func getConfigurationForRegion(regionId: Int, completionHandler: (configuration: String) -> Void, errorHandler: (result: Int) -> Void) {
        let username = KeychainWrapper.stringForKey("axion_username")!
        let password = KeychainWrapper.stringForKey("axion_password")!
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://axionvpn.com/api/get-config")!)
        let session = NSURLSession.sharedSession()
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        
        let params = "id=\(regionId)&username=\(username)&password=\(password)"
        print("params: \(params)")
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            let json = JSON(data: data!)
            
            let result = json["result"].intValue
            
            if result == 0 {
                let configuration = json["conf"].stringValue
                completionHandler(configuration: configuration)
            } else if result == 1 {
                // Invalid password
                errorHandler(result: result)
            } else if result == 2 {
                // Invalid username
                errorHandler(result: result)
            }
            
            // Other possible cases:
            // When response body is blank: Missing "id" field
            // When response body is "No vpn found": "id" field is set to an invalid ID
        }
        
        task.resume()

    }
    
    class func getVPNs(completionHandler completionHandler: (result: [[String:String]]) -> Void, errorHandler: () -> Void) {
        let urlString = "https://axionvpn.com/api/get-vpns"
        var objects = [[String: String]]()
            
        if let url = NSURL(string: urlString) {
            if let data = try? NSData(contentsOfURL: url, options: []) {
                let json = JSON(data: data)
                    
                for result in json["vpns"].arrayValue {
                    let id = result["id"].stringValue
                    let geo_area = result["geo_area"].stringValue
                    
                    let obj = ["id": id, "geo_area": geo_area]
                    objects.append(obj)
                    completionHandler(result: objects)
                }
            } else {
                errorHandler()
            }
        } else {
            errorHandler()
        }
    }
    
    class func isOpenVPNConnectInstalled() -> Bool {
        return UIApplication.sharedApplication().canOpenURL(NSURL(string: "openvpn://")!)
    }
    
}
