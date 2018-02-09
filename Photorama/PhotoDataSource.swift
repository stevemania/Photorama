//
//  PhotoDataSource.swift
//  Photorama
//
//  Created by STEVE DURAN on 11/15/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//

import Foundation
import UIKit

class PhotoDataSource: NSObject, UICollectionViewDataSource {
    var photos = [Photo]()
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = "PhotoCollectionViewCell"
        let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: identifier,
                                               for: indexPath) as! PhotoCollectionViewCell
        return cell
    }
}
