//
//  PhotoStore.swift
//  Photorama
//
//  Created by STEVE DURAN on 11/9/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//

//import Foundation
import UIKit
import CoreData

//deals with the UI image dailing
enum ImageResult {
    case success(UIImage)
    case failure(Error)
}


enum PhotoError: Error {
    case imageCreationError
}


// the enumerations for if it failed or not
enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

//
enum TagsResult {
    case success([Tag])
    case failure(Error)
}

class PhotoStore {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    let imageStore = ImageStore()
    
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()
    //method that will process the JSON data that is returned from the web service request.
    private func processPhotosRequest(data: Data?, error: Error?,completion: @escaping (PhotosResult) -> Void){
        guard let jsonData = data else {
            completion(.failure(error!))
            return
        }
        persistentContainer.performBackgroundTask{
            (context) in
            let result = FlickrAPI.photos(fromJSON: jsonData, into: context)
            do {
                try context.save()
            } catch {
                print("Error saving to Core Data: \(error).")
                completion(.failure(error))
                return
            }
            
            switch result {
            case let .success(photos):
                let photoIDs = photos.map { return $0.objectID } //map transform on array into another one
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoIDs.map { return viewContext.object(with: $0) } as! [Photo]
                completion(.success(viewContextPhotos))
            case .failure:
                completion(result)
            }
        }
    }
    
    
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                
                // Couldn't create an image
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
    
    //this is how we will be connecting to Flickr API
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        
        guard let photoKey = photo.photoId else {
            preconditionFailure("Photo Expected to have Photo ID")
        }
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        guard let photoURL = photo.remoteURL else {
            preconditionFailure("Photo expected to have URL")
        }
        let request = URLRequest(url: photoURL as URL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            // we will be processing the data
            let result = self.processImageRequest(data: data, error: error)
            
            
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    
    //implement the fetchInterestingPhotos() method to create a URLRequest that connects to api.flickr.com and asks for the list of interesting photos. Then, use the URLSession to create a URLSessionDataTask that transfers this request to the server.
    //MUST HAVE COMPLETION INCLUDED TO END SERVICES FROM THE WEB
    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void) {
        
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            
            self.processPhotosRequest(data: data, error: error) {
                (result) in
                
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
        }
        task.resume()
    }
    
    
    //implements a method to get all photos
    func fetchAllPhotos(completion: @escaping (PhotosResult) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken),
                                               ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch {
                
                completion(.failure(error))
            }
        }
    }
    
    //gets all tags 
    func fetchAllTags(completion: @escaping (TagsResult) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}
