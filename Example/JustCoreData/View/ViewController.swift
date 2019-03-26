//
//  ViewController.swift
//  JustCoreData
//
//  Created by Xiaoye220 on 03/26/2019.
//  Copyright (c) 2019 Xiaoye220. All rights reserved.
//

import UIKit
import JustCoreData

class ViewController: UIViewController {

    var tableView: UITableView!
    
    enum Content: String, CaseIterable {
        case save_main
        case save_private
        case deleteAll_main
        case deleteAll_private
        case update_main
        case update_private
        case find_sync
        case find_async
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
    
    let contents: [Content] = Content.allCases;
    
    var cd: CoreData<Father>!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initJustCoreData()
        
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        let y = UIApplication.shared.statusBarFrame.height + 44
        
        tableView = UITableView(frame: CGRect(x: 0, y: y, width: screenWidth, height: screenHeight - y))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initJustCoreData() {
        CoreDataStack.dataModelName = "Person"
        self.cd = CoreData<Father>()
    }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let content = contents[indexPath.row]
        cell.textLabel?.text = content.rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = contents[indexPath.row]
        switch content {
        case .save_main:
            self.saveInMainContext()
        case .save_private:
            self.saveInPrivateContext()
        case .deleteAll_main:
            self.deleteAllInMain()
        case .deleteAll_private:
            self.deleteAllInPrivate()
        case .update_main:
            self.updateInMain()
        case .update_private:
            self.updateInPrivate()
        case .find_sync:
            self.syncFind()
        case .find_async:
            self.asyncFind()
        case .NSFetchedResultsController:
            self.navigationController?.pushViewController(NSFetchedResultsViewController(), animated: true)
        }
    }
}

extension ViewController {
    func saveInMainContext() {
        cd.concurrencyType(.mainQueue_sync)
            .saveDataCount(10)
            .configure { (index, person) in
                person.updateFromDictionary(dict: self.testData[index])
            }
            .completion { (success, _) in
                print("\(Thread.current)\nsync save \(success ? "success" : "fail")")
            }
            .save()
        
        print("perform finish")
    }
    
    func saveInPrivateContext() {
        cd.concurrencyType(.privateQueue_async)
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
    
    func deleteAllInMain() {
        cd.concurrencyType(.mainQueue_sync)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nsync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    func deleteAllInPrivate() {
        cd.concurrencyType(.privateQueue_async)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nasync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    func updateInMain() {
        cd.concurrencyType(.mainQueue_sync)
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
    
    func updateInPrivate() {
        cd.concurrencyType(.privateQueue_async)
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
        cd.concurrencyType(.mainQueue_sync)
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
            .read()
        
        print("perform finish")
    }
    
    func asyncFind() {
        cd.concurrencyType(.privateQueue_async)
            .fetchRequest { _ in
                //request.predicate(NSPredicate(format: "name = %@", "Li lei"))
            }
            .completion { (success, results) in
                print("\(Thread.current)\nasync find \(success ? "success" : "fail")")
                let persons = results as! [Father]
                print("result count: \(persons.count)")
            }
            .read()
        
        print("perform finish")
    }
}

