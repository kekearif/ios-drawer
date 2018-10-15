//
//  ViewController.swift
//  ios-drawer
//
//  Created by Keke Arif on 12/10/2018.
//  Copyright © 2018 Keke Arif. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // We are in the base controller (whatever the background is)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The overlay container contains the overlay vc which is the table
        // Animation will happen in the container e.g animating the view via delegates
        let vc: OverlayContainerVC = OverlayContainerVC()
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: false, completion: nil)
    }

}

