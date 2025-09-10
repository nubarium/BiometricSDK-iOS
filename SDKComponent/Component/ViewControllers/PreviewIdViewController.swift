//
//  PreviewIdViewController.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 16/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import UIKit

class PreviewIdViewController: UIViewController {

    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // Public property
    var delegate : PreviewFaceViewControllerDelegate?

    @IBOutlet weak var previewImage: UIImageView!
    
    
    @IBAction func actionConfirm(_ sender: Any) {
        acceptImage()
    }
    
    @IBAction func actionDismiss(_ sender: Any) {
        dismissImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    func acceptImage(){
        self.delegate?.respond(accept:true)
        self.navigationController?.popViewController(animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
    func dismissImage(){
        self.delegate?.respond(accept:false)
        self.navigationController?.popViewController(animated: false)
        self.dismiss(animated: false, completion: nil)
    }
    
}

protocol PreviewIdViewControllerDelegate {
    func respond(accept : Bool)
}

