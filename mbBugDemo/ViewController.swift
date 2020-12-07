//
//  ViewController.swift
//  mbBugDemo
//
//  Created by Goran Gajduk on 12/3/20.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func loadBuggedMap() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "mapViewController") as? MapViewController {
            vc.loadBuggyVersion = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    @IBAction func loadWorkingMap() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "mapViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

