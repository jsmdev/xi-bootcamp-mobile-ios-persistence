//
//  PhotographMO+CoreDataClass.swift
//  Notebooks
//
//  Created by Daniel Torres on 2/1/21.
//
//

import Foundation
import CoreData

@objc(PhotographMO)
public class PhotographMO: NSManagedObject {

    static func createPhoto(imageData: Data,
                            createdAt: Date,
                            managedObjectContext: NSManagedObjectContext) -> PhotographMO? {
        let photograph = NSEntityDescription.insertNewObject(forEntityName: "Photograph",
                                                             into: managedObjectContext) as? PhotographMO
        
        photograph?.imageData = imageData
        photograph?.createdAt = createdAt
        
        return photograph
    }
}
