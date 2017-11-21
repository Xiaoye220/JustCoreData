//
//  CoreDataRequstType.swift
//  CoreDataExtensions
//
//  Created by YZF on 14/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataFetchRequestType: class {
    associatedtype ManagedObject: ManagedObjectType

    var fetchRequest: NSFetchRequest<NSFetchRequestResult>? { get set }
    
    func fetchRequestRefresh()
}

extension CoreDataFetchRequestType {
    public func fetchRequestRefresh() {
        self.fetchRequest = nil
    }
}

extension CoreDataFetchRequestType {
    @discardableResult
    public func fetchRequest(_ configure: (NSFetchRequest<NSFetchRequestResult>) -> Void) -> Self {
        if self.fetchRequest == nil {
            self.fetchRequest = ManagedObject.defaultFetchRequest
        }
        configure(self.fetchRequest!)
        
        return self
    }
}
