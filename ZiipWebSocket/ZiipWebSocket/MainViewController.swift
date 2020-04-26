//
//  MainViewController.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    
    // MARK: - Injected Dependencies

    public var connectionManager: ConnectionManager?
    public var preferencesService: PreferencesService?
    
    //MARK: - Outlets
    
    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var roomCodeTextField: UITextField!
    @IBOutlet private weak var hubIdTextField: UITextField!
    
    @IBOutlet private weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func connectButtonDidTap(_ sender: Any) {
        
    }
    
}

