//
//  ViewController.swift
//  JustCoreData
//
//  Created by Xiaoye220 on 03/26/2019.
//  Copyright (c) 2019 Xiaoye220. All rights reserved.
//

import UIKit
import JustCoreData

class RootViewController: UIViewController {

    var tableView: UITableView!
    
    enum Content: String, CaseIterable {
        case save_main          = "save"
        case save_private       = "save "
        case deleteAll_main     = "delete"
        case deleteAll_private  = "delete "
        case update_main        = "update"
        case update_private     = "update "
        case fetch_main         = "fetch"
        case fetch_private      = "fetch "
        case NSFetchedResultsController
    }
    
    var testData: [[String: Any]] {
        var dicts: [[String: Any]] = []
        for i in 1 ... 10 {
            let dict =  ["id": i,
                         "name": "Li lei",
                         "age": 25,
                         "children": [["id": 2*i-1, "name": "Ding ding", "age": 1],
                                      ["id": 2*i, "name": "La la", "age": 2]],
                         "grandFather": ["id": 1,
                                         "name": "Li gang",
                                         "age": 50]] as [String : Any]
            dicts.append(dict)
        }
        return dicts
    }
    
//    let contents: [[Content]] = [[.save_main, .save_private],
//                                 [.deleteAll_main, .deleteAll_private],
//                                 [.update_main, .update_private],
//                                 [.fetch_main, .fetch_private],
//                                 [.NSFetchedResultsController]];
    
    let contents: [[Content]] = [[.save_main, .deleteAll_main, .update_main, .fetch_main],
                                 [.save_private, .deleteAll_private, .update_private, .fetch_private],
                                 [.NSFetchedResultsController]];
    
    var cd: CoreData<Father>!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initJustCoreData()
        
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        let y = UIApplication.shared.statusBarFrame.height + 44
        
        tableView = UITableView(frame: CGRect(x: 0, y: y, width: screenWidth, height: screenHeight - y), style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // initJustCoreData
    func initJustCoreData() {
        CoreDataStack.dataModelName = "Person"
        self.cd = CoreData<Father>()
    }

}

extension RootViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Sync on the main queue"
        } else if section == 1 {
            return "Async on the private queue"
        }
        return ""
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let content = contents[indexPath.section][indexPath.row]
        cell.textLabel?.text = content.rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = contents[indexPath.section][indexPath.row]
        switch content {
        case .save_main:
            self.saveOnMainContext()
        case .save_private:
            self.saveOnPrivateContext()
        case .deleteAll_main:
            self.deleteAllOnMain()
        case .deleteAll_private:
            self.deleteAllOnPrivate()
        case .update_main:
            self.updateOnMain()
        case .update_private:
            self.updateOnPrivate()
        case .fetch_main:
            self.syncFind()
        case .fetch_private:
            self.asyncFind()
        case .NSFetchedResultsController:
            self.navigationController?.pushViewController(NSFetchedResultsViewController(), animated: true)
        }
    }
}

extension RootViewController {
    
    func saveOnMainContext() {
        cd.concurrencyType(.mainSync)
            .saveDataCount(10)
            .configure { (index, person) in
                person.updateFromDictionary(dict: self.testData[index])
            }
            .completion { (success, _) in
                print("\(Thread.current)\nsync save \(success ? "success" : "fail")")
            }
            .save()
        DispatchQueue.global().async {
            
        }
        print("perform finish")
    }
    
    func saveOnPrivateContext() {
        cd.concurrencyType(.private)
            .saveDataCount(5)
            .configure { (index, person) in
                person.name = "\(index).Han meimei"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nasync save \(success ? "success" : "fail")")
            }
            .save()
        
        print("perform finish")
    }
    
    func deleteAllOnMain() {
        cd.concurrencyType(.mainSync)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nsync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    func deleteAllOnPrivate() {
        cd.concurrencyType(.private)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nasync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    func updateOnMain() {
        cd.concurrencyType(.mainSync)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "1.Li lei"))
            }
            .configure { (index, person) in
                person.name = "Bob"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nsync update \(success ? "success" : "fail")")
            }
            .update()
        
        print("perform finish")
    }
    
    func updateOnPrivate() {
        cd.concurrencyType(.private)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "1.Han meimei"))
            }
            .configure { (index, person) in
                person.name = "Lily"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nasync update \(success ? "success" : "fail")")
            }
            .update()
        
        print("perform finish")
    }
    
    func syncFind() {
        cd.concurrencyType(.mainSync)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "Li lei"))
                    .fetchLimit(1)
                    .resultType(.managedObjectResultType)
            }
            .completion { (success, results) in
                print("\(Thread.current)\nsync find \(success ? "success" : "fail")")
                let persons = results as! [Father]
                print("result count: \(persons.count)")
            }
            .fetch()
        
        print("perform finish")
    }
    
    func asyncFind() {
        cd.concurrencyType(.private)
            .fetchRequest { _ in
                //request.predicate(NSPredicate(format: "name = %@", "Li lei"))
            }
            .completion { (success, results) in
                print("\(Thread.current)\nasync find \(success ? "success" : "fail")")
                let persons = results as! [Father]
                print("result count: \(persons.count)")
            }
            .fetch()
        
        print("perform finish")
    }
}

