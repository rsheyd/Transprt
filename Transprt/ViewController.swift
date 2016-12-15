//
//  ViewController.swift
//  Transprt
//
//  Created by Roman Sheydvasser on 12/15/16.
//  Copyright © 2016 RLabs. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let testObj = PFObject(className: "testObj")
        testObj["foo"] = "bar"
        testObj.saveInBackground()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

