//
//  PhotoCollectionViewCell.swift
//  Photorama
//
//  Created by STEVE DURAN on 11/9/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//

import Foundation
import UIKit

//we added UICollectionViewDelagate to get pictures when scrholling down 
class PhotoCollectionViewCell: UICollectionViewCell{
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    //function implementing spinning or not for spinner idicator
    func update(with image: UIImage?) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
    
    //this is called when the first cell is created
    override func awakeFromNib() {
        super.awakeFromNib()
        update(with: nil)
    }
    //spin will update if the cell is being reused
    override func prepareForReuse() {
        super.prepareForReuse()
        update(with: nil)
    }
    
    
}
