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
    var documentDetail: [String:IdDetail]?
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
        //navigationItem.hidesBackButton = true;
        
        // Set flag in cas to return
        self.delegate?.respond(accept:false)
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        var aspectR: CGFloat = 0.0
        
        let image : UIImage = documentDetail!["front"]!.areaImage()
        
        aspectR = image.size.width/image.size.height
        previewImage.image = image
        let nw = CGFloat(previewImage.frame.height*aspectR)
        let containerView = UIView(frame: CGRect(x:(screenWidth - nw)/2,y:0, width: nw, height:CGFloat(previewImage.frame.height) ) )

        /*if containerView.frame.width < containerView.frame.height {
            let newHeight = containerView.frame.width / aspectR
            previewImage.frame.size = CGSize(width: containerView.frame.width, height: newHeight)
        }else{
            let newWidth = containerView.frame.height * aspectR
            previewImage.frame.size = CGSize(width: newWidth, height: containerView.frame.height)
        }*/
        previewImage.frame = CGRect(x:(screenWidth - nw)/2,y:100, width: nw, height:CGFloat(previewImage.frame.height) )
        //previewImage.bounds = CGRect(x:(screenWidth - nw)/2,y:50, width: nw, height:CGFloat(previewImage.frame.height) )
        //previewImage.contentMode = .center
        
        
        //previewImage.translatesAutoresizingMaskIntoConstraints = true
        //previewImage.contentMode = .scaleAspectFit
        

        previewImage.layer.borderWidth = 2
        if traitCollection.userInterfaceStyle == .light {
            previewImage.layer.borderColor = UIColor.darkGray.cgColor
        } else {
            previewImage.layer.borderColor = UIColor.white.cgColor
        }
        
        previewImage.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        
        //previewImage.stroke
        // Do any additional setup after loading the view.
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

