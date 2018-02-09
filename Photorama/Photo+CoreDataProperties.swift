//
//  Photo+CoreDataProperties.swift
//  Photorama
//
//  Created by STEVE DURAN on 12/1/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var dateTaken: NSDate?
    @NSManaged public var photoId: String?
    @NSManaged public var remoteURL: NSURL?
    @NSManaged public var title: String?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for tags
extension Photo {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag) //Tag

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag) //Tag

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}
