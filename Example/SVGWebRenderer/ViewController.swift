//
//  ViewController.swift
//  SVGWebRenderer
//
//  Created by Jonathan Lu on 04/19/2020.
//  Copyright (c) 2020 Jonathan Lu. All rights reserved.
//

import UIKit
import SVGWebRenderer

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            SVGRenderer.shared().clearImageCache()
        }
    }

}

