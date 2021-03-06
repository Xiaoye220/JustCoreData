![pod](https://img.shields.io/badge/pod-JustCoreData-brightgreen.svg)
![iOS](https://img.shields.io/badge/iOS-8.0-green.svg)
![lisence](https://img.shields.io/badge/license-MIT-orange.svg)
![swift](https://img.shields.io/badge/swift-5.0-red.svg)

# JustCoreData

## CocoaPods

```
use_frameworks!
pod 'JustCoreData'
```

## Usage

### 1.Data Model

先看例子中的 Data Model
>Data model in the example

![DataModel](screenshot/DataModel.png)


### 2.ManagedObjectType

实体需要实现 ManagedObjectType 协议，协议实现了根据实体名和默认 NSSortDescriptor ，并提供了根据 Dictionary 给实体赋值的功能。
>Entities should implement ManagedObjectType protocol.

```swift
extension Father: ManagedObjectType {
    public static var entityName: String {
        return "Father"
    }
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }
}
```


### 3.Usage

#### 3.1 DataSource

自定义 dict 用来存储需要进行操作的数据。
>dicts are the data that should to be saved

```swift
var dicts: [[String: Any]] {
        var dicts: [[String: Any]] = []
        for i in 1 ... 10 {
            let dict =  ["id": i,
                         "name": "Li lei",
                         "age": 25,
                         "children": [["id": 2*i-1, "name": "Ding ding", "age": 1],
                                      ["id": 2*i, "name": "La la", "age": 2]],
                         "parent": ["id": i,
                                    "name": "Li gang",
                                    "age": 50]] as [String : Any]
            dicts.append(dict)
        }
        return dicts
    }
```
#### 3.2 Init

dataModelName is the name of .xcdatamodeld file

```Swift
let cd = CoreData<Father>()

CoreDataStack.dataModelName = "Person"
```

#### 3.3 Save
```swift
cd.concurrencyType(.mainSync)
    .saveDataCount(10)
    .configure { (index, person) in
        person.updateFromDictionary(dict: self.dicts[index])
    }
    .completion { (success, _) in
        print("\(Thread.current)\nsync save \(success ? "success" : "fail")")
    }
    .save()
```

`person.updateFromDictionary(dict: self.dicts[index])` can update entity with dictionary. If there are relationships between entities, the relationships can also be implemented .Of course, you can update entity by your own way.

#### 3.4 Fetch

```swift
cd.concurrencyType(.mainSync)
    .fetchRequest { request in
        request.predicate(NSPredicate(format: "name = %@", "Li lei"))
        	.fetchLimit(1)
        	.resultType(.managedObjectResultType)
        // ......
    }
    .completion { (success, results) in
        print("\(Thread.current)\nsync find \(success ? "success" : "fail")")
        let persons = results as! [Father]
        print("result count: \(persons.count)")
    }
    .fetch()
```

#### 3.5 Update
```swift
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
```

#### 3.6 Delete
```swift
cd.concurrencyType(.mainSync)
    .fetchRequest { _ in }
    .completion { (success, _) in
        print("\(Thread.current)\nsync delete \(success ? "success" : "fail")")
    }
    .delete()
```

### 4.NSFetchedResultsController

`FetchedResultsManager` encapsulates the `NSFetchedResultsController` logic to make `NSFetchedResultsController` easy to use

#### Usage
``` Swift 
class NSFetchedResultsViewController: UITableViewController {

    var fetchedResultsManager: FetchedResultsManager<Father>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // init FetchedResultsManager
        fetchedResultsManager = FetchedResultsManager<Father>(contextType: .private,
                                                              tableView: tableView,
                                                              sectionName: nil,
                                                              cacheName: nil,
                                                              fetchRequestConfigure: nil)
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
    
}
```
