//
//  Collection+CoreDataExtensions.swift
//
//  Created by YZF on 20/2/17.
//  Copyright © 2017年 YZF. All rights reserved.
//

import CoreData


// MARK: - 将惰值都实例化，避免多次实例化惰值造成大的开销
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
