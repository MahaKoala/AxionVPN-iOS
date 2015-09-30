//
//  SettingsViewController.swift
//  AxionVPN
//
//  Copyright © 2015 Axion. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let username = KeychainWrapper.stringForKey("axion_username") {
            usernameField.text = username
        }
        
        if let password = KeychainWrapper.stringForKey("axion_password") {
            passwordField.text = password
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveSettings() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.resignFirstResponder()
            KeychainWrapper.setString(self.usernameField.text!, forKey: "axion_username")
            KeychainWrapper.setString(self.passwordField.text!, forKey: "axion_password")
        
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func showError() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            let ac = UIAlertController(title: "Invalid Credentials", message: "Please check your credentials and try again.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }

    @IBAction func saveTapped(sender: AnyObject) {
        // TODO: Do some rudimentary checking before submitting, such as that username is a valid email address, password is long enough, etc.
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            AxionAPI.checkCredentials(self.usernameField.text!, password: self.passwordField.text!) { (validCredentials) -> Void in
                if validCredentials {
                    self.saveSettings()
                } else {
                    self.showError()
                }
            }
        }
    }
    
    @IBAction func cancelTapped(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
