//
//  CoreDataProtocol.swift
//  CoreDataExtensions
//
//  Created by YZF on 14/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation


public enum ConcurrencyType {
    case privateQueue_async
    case mainQueue_async
    case mainQueue_sync
}

public enum ContextType {
    case mainContext
    case privateContext
}
