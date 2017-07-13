//
//  NSManageObject+Extension.swift
//  CoreDataExtensions
//
//  Created by YZF on 5/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("the entity \(type(of: self)) is not key value coding-compliant for the key \"\(key)\".")
    }
    

}
