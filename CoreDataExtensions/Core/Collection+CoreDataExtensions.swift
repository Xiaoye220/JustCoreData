//
//  Collection+CoreDataExtensions.swift
//
//  Created by YZF on 20/2/17.
//  Copyright © 2017年 YZF. All rights reserved.
//

import CoreData


// MARK: - Turn all daults to objects, reduce the cost
extension Collection where Iterator.Element: NSManagedObject {
    public func fetchObjectsThatAreFaults() {
        guard !self.isEmpty else { return }
        guard let context = self.first?.managedObjectContext else { fatalError("Managed object must have context") }
        let faults = self.filter { $0.isFault }
        guard let mo = faults.first else { return }
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = mo.entity
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "self in %@", faults)
        try! context.fetch(request)
    }
}
