//
//  Father.swift
//  CoreDataExtensions
//
//  Created by YZF on 11/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import JustCoreData

extension GrandFather: ManagedObjectType {
    
    public static var entityName: String {
        return "GrandFather"
    }
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor.init(key: "id", ascending: true)]
    }
}


