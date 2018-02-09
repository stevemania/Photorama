//
//  FlickrAPI.swift
//  Photorama
//
//  Created by STEVE DURAN on 11/9/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//


import Foundation
import CoreData

//we use enumeration to specify which endpoint on the Flickr server to hit.
enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
}

enum FlickrError: Error {
    case invalidJSONData
}

//responsible for knowing and handling flickr information
struct FlickrAPI {
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88" // deals with the key
    
    
    //You will need an instance of DateFormatter to convert the datetaken string into an instance of Date.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    static var interestingPhotosURL: URL {
        return flickrURL(method: .interestingPhotos,parameters: ["extras": "url_h,date_taken"])
    }
    
    private static func flickrURL(method: Method,
                                  parameters: [String:String]?) -> URL {
        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            "method": method.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }

        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item) }
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    
    
    //implement a method that takes in an instance of Data and uses the JSONSerialization class to convert the data into the basic foundation objects.
    static func photos(fromJSON data: Data, into context: NSManagedObjectContext) -> PhotosResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            //dig down through the JSON data to get to the array of dictionaries representing the individual photos.
            //Big Ranch has image showing json array of dictionaries representing the photo in the book
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let photos = jsonDictionary["photos"] as? [String:Any],
                let photosArray = photos["photo"] as? [[String:Any]] else {
                    
                    // The JSON structure doesn't match our expectations
                    return .failure(FlickrError.invalidJSONData)
            }
            
            
            var finalPhotos = [Photo]()
            
            //parse the dictionaries into Photo instances and then return these as part of the success enumerator. Also handle the possibility that the JSON format has changed, so no photos were able to be found.
            for photoJSON in photosArray {
                if let photo = photo(fromJSON: photoJSON, into: context) {
                    finalPhotos.append(photo)
                }
            }
            
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                // We weren't able to parse any of the photos
                // Maybe the JSON format for photos has changed
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        }catch let error {
            return .failure(error)
        }
    }
    
    private static func photo(fromJSON json: [String : Any], into context: NSManagedObjectContext)->Photo?{
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = FlickrAPI.dateFormatter.date(from: dateString) else {
                
                //did not have enough information to construct photo
                return nil
        }
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoId)) == \(photoID)")
        fetchRequest.predicate = predicate
        
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        if let existingPhoto = fetchedPhotos?.first{
            return existingPhoto
        }
        
        var photo: Photo!
        context.performAndWait {
            photo = Photo(context: context)
            photo.title = title
            photo.photoId = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as NSDate
        }
        return photo
    }
}
