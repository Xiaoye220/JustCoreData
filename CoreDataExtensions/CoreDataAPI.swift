//
//  CoreDataAPI.swift
//  CoreDataExtensions
//
//  Created by YZF on 7/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData


class CoreDataAPI<E: NSManagedObject>: CoreDataOperationsType where E: ManagedObjectType  {
    
    public static var fetchBatchSize: Int {
        return 100
    }
    
    public typealias ManageObject = E
    
}
