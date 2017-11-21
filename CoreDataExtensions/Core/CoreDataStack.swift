//
//  CoreDataStack.swift
//
//  Created by YZF on 2016/11/29.
//  Copyright © 2016年 YZF. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    static var dataModelName: String?
    
    static let shared = CoreDataStack()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        guard let dataModelName = CoreDataStack.dataModelName else { fatalError("CoreDataStack.dataModelName cann't be nil") }
        let modelURL = Bundle.main.url(forResource: dataModelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard let dataModelName = CoreDataStack.dataModelName else { fatalError("CoreDataStack.dataModelName cann't be nil") }
        
        var coordinator = NSPersistentStoreCoordinator.init(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent(dataModelName + ".sqlite")
        print("\(url!.path)")
        
        var error: NSError? = nil

        // icloud supports
//        let options = [NSPersistentStoreUbiquitousContentNameKey: "contentNameKey",
//                       NSPersistentStoreUbiquitousContainerIdentifierKey: "containerIdentifierKey"]

        do{
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        }catch{
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return coordinator
    }()
    
    /// main NSManagedObjectContext
    lazy var mainManagedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        var managedObjectContext = NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return managedObjectContext
    }()
    
    /// private NSManagedObjectContext
    lazy var privateManagedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        var managedObjectContext = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        
        managedObjectContext.performAndWait() {
            
            managedObjectContext.persistentStoreCoordinator = coordinator
            
            // Avoid using default merge policy in multi-threading environment:
            // when we delete (and save) a record in one context,
            // and try to save edits on the same record in the other context before merging the changes,
            // an exception will be thrown because Core Data by default uses NSErrorMergePolicy.
            // Setting a reasonable mergePolicy is a good practice to avoid that kind of exception.
            managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        NotificationCenter.default.addObserver(CoreDataStack.shared, selector: #selector(CoreDataStack.contextDidSaveNotificationHandler), name: .NSManagedObjectContextDidSave, object: nil)
        
        return managedObjectContext
    }()
    
    /// Handler for NSManagedObjectContextDidSaveNotification.
    /// Observe NSManagedObjectContextDidSaveNotification and merge the changes to the main context from other contexts.
    /// We rely on this to sync between contexts, thus avoid most of merge conflicts and keep UI refresh.
    /// In the sample code, we don’t edit the main context so not syncing with the private queue context won’t trigger any issue.
    @objc func contextDidSaveNotificationHandler(notification: NSNotification){
        let sender = notification.object as! NSManagedObjectContext
        if sender !== self.mainManagedObjectContext {
            self.mainManagedObjectContext.perform() {
                self.mainManagedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        } else {
            self.privateManagedObjectContext.perform() {
                self.privateManagedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(CoreDataStack.shared)
    }
    
}
