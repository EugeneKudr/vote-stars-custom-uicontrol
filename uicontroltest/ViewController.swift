//
//  ViewController.swift
//  uicontroltest
//
//  Created by Евгений Испольнов on 20.08.2020.
//  Copyright © 2020 Евгений Испольнов. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var myCustomControl: MyCustomControl!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
           
        myCustomControl.starHeight = 50
        myCustomControl.starWidth = 51.5
        myCustomControl.maximumValue = 5
        myCustomControl.contentHorizontalAlignment = .right
        
        myCustomControl.addTarget(self, action: #selector(ViewController.handleValueChanged(_:)), for: .valueChanged)
        updateLabel()
    }
    
    @IBAction func handleValueChanged(_ sender: Any) {
        updateLabel()
    }
    
    private func updateLabel() {
        valueLabel.text = String(myCustomControl.value)
    }
    
}

