//
//  NSFetchedResultsViewController.swift
//  CoreDataExtensions
//
//  Created by YZF on 13/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import UIKit

class NSFetchedResultsViewController: UITableViewController {

    var fetchedResultsManager: FetchedResultsManager<Person>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchedResultsManager = FetchedResultsManager.init(fetchRequest: Person.sortedFetchRequest, contextType: .mainContext, tableView: tableView, sectionName: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsManager.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsManager.numberOfItemsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        let obj = fetchedResultsManager.objectAtIndexPath(indexPath)
        cell?.textLabel?.text = "id: " + String(obj.id) + "  name: " + obj.name!
        return cell!
    }
    
    @IBAction func save(_ sender: Any) {
        Person.save(by: .mainContext, dataCount: 1) {
            $1.id = 1000
            $1.name = "Lily"
        }
    }
    @IBAction func deletePerson(_ sender: Any) {
        Person.delete(by: .mainContext, predicate: NSPredicate.init(format: "name = %@", "Lily"))
    }
 
    
}
