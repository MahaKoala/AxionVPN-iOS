//
//  MasterViewController.swift
//  AxionVPN
//
//  Copyright © 2015 Axion. All rights reserved.
//

import UIKit

class RegionsViewController: UITableViewController, UIDocumentInteractionControllerDelegate {

    var objects = [[String: String]]()
    var documentInteractionController: UIDocumentInteractionController!
    var configurationPath: String!
    var sendingToApplication = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !AxionAPI.isAuthenticated() {
            // TODO: Switch to SettingsViewController to allow the user to login
        }

        getVPNs()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let object = objects[indexPath.row]
        cell.textLabel!.text = object["geo_area"]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = objects[indexPath.row]
        let id = Int(object["id"]!)!
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            AxionAPI.getConfigurationForRegion(id, completionHandler: { (configuration) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.configurationPath = self.saveConfiguration(configuration)
                    if self.configurationPath != nil {
                        self.sendConfigurationToOpenVPNConnect(self.configurationPath)
                    }
                    
                })
            }, errorHandler: { (result) -> Void in
                print("Result: \(result)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.showError("Unable to fetch configuration.")
                })
            })
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func showError(message: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let ac = UIAlertController(title: "Loading error", message: message, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    func getVPNs() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            AxionAPI.getVPNs(completionHandler: { (result) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.objects = result
                    self.tableView.reloadData()
                })
            }, errorHandler: { () -> Void in
                self.showError("There was a problem loading the list of available regions. Please check your connection and try again.")
            })
        }
    }
    
    func saveConfiguration(configuration: String) -> String? {
        var configurationName = NSUUID().UUIDString
        configurationName = configurationName.stringByAppendingString(".ovpn")
        let configurationPath = self.getDocumentsDirectory().stringByAppendingPathComponent(configurationName)
        print(configurationPath)

        do {
            try configuration.writeToFile(configurationPath, atomically: true, encoding: NSUTF8StringEncoding)
            return configurationPath
        } catch let error as NSError {
            self.showError("There was a problem writing the configuration file to disk: \(error.localizedDescription).")
            return nil
        }
    }
    
    func sendConfigurationToOpenVPNConnect(configurationPath: String) {
        let url = NSURL(fileURLWithPath: configurationPath)
        
        if documentInteractionController == nil {
            documentInteractionController = UIDocumentInteractionController(URL: url)
        }
        documentInteractionController.UTI = "net.openvpn.formats.ovpn"
        documentInteractionController.delegate = self
        documentInteractionController.presentOptionsMenuFromRect(self.view.frame, inView: self.view, animated: true)
    }
    
    func deleteConfiguration(configurationPath: String) {
        if self.configurationPath != nil {
            print("Deleting \(self.configurationPath)")
            if NSFileManager.defaultManager().fileExistsAtPath(self.configurationPath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(self.configurationPath)
                    self.configurationPath = nil
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let message = "Unable to delete temporary configuration file: \(error.localizedDescription)."
                        self.showError(message)
                    })
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: UIDocumentInteractionControllerDelegate
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    func documentInteractionControllerRectForPreview(controller: UIDocumentInteractionController) -> CGRect {
        return self.view.frame
    }
    
    func documentInteractionController(controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        // This boolean prevents documentInteractionControllerDidDismissOptionsMenu from deleting the file before
        sendingToApplication = true
    }

    func documentInteractionController(controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        // Delete the configuration file from disk now that we've passed it off to OpenVPN Connect
        sendingToApplication = false
        deleteConfiguration(self.configurationPath)
    }
    
    func documentInteractionControllerDidDismissOptionsMenu(controller: UIDocumentInteractionController) {
        // This gets called whether the user tapped cancel or selected OpenVPN, so we need to be careful not
        // to delete the configuration if we're still passing it through.
        if !sendingToApplication {
            deleteConfiguration(self.configurationPath)
        }
    }
}

