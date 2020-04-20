//
//  RemoteViewController.swift
//  SVGWebRenderer_Example
//
//  Created by LU JIAMENG on 19/4/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SVGWebRenderer

class RemoteViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.setImage(URL(string: "https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg"), placeholder: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
