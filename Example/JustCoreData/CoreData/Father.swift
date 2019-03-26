//
//  Person.swift
//  CoreDataExtensions
//
//  Created by YZF on 4/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import JustCoreData

extension Father: ManagedObjectType {
    
    public static var entityName: String {
        return "Father"
    }
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }
}

