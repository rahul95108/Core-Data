
import UIKit
import MBProgressHUD
import Alamofire
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tbView: UITableView!
    var names: NSMutableArray =  []
    var people: [NSManagedObject] = []
    
    // MARK: - UIView Life Cycle Methods -

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The List"
        tbView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.retriveData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func retriveData(){
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Person")
        
        do {
            people = try managedContext.fetch(fetchRequest)
            print(people)
            
            for result in people {
                let dict = NSMutableDictionary()
                dict.setValue(result.value(forKey: "name"), forKey: "product_name")
                self.names.add(dict)
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        if self.names.count > 0 {
            tbView.reloadData()
        }
        else{
            self.showHUD()
            self.callPostService()
        }
    }
    
    func callPostService(){
        let dict = NSMutableDictionary()
        dict.setValue("", forKey: "attribute_id")
        dict.setValue("", forKey: "brand_id")
        dict.setValue("", forKey: "category_id")
        dict.setValue("", forKey: "flavour_id")
        dict.setValue("", forKey: "goal_id")
        dict.setValue("", forKey: "measure_id")
        dict.setValue("20", forKey: "page_limit")
        dict.setValue("1", forKey: "page_num")
        dict.setValue("1", forKey: "product_type")
        dict.setValue("1", forKey: "sort_by")
        dict.setValue("412", forKey: "user_id")
        
        Alamofire.request("http://dev.sixpacks.com/api/v1/browsebyFilter1", method: .post, parameters: dict as? [String : AnyObject], encoding: JSONEncoding.default, headers: [:])
            .responseJSON { response in switch response.result {
            case .success(let JSON):
                let dict = JSON as! NSDictionary
                let arr = dict.value(forKey: "response") as! NSArray
                
                for i in 0..<arr.count{
                    let dictData = arr.object(at: i) as! NSDictionary
                    self.names.add(dictData)
                    self.addData(name: dictData.value(forKey: "product_name") as! NSString)
                }
                self.tbView.reloadData()
                print(self.names)
              //  print("response :-----> ",response)
            case .failure(let error):
                print("Request failed with error: \(error)")
                
            }
            self.hidHUD()
        }
    }
    
    func showHUD(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading"
    }
    
    func hidHUD(){
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    func addData(name:NSString){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Person", in: managedContext)
        
        let person = NSManagedObject(entity: entity!, insertInto: managedContext)
        person.setValue(name, forKey: "name")
        do {
            try managedContext.save()
            people.append(person)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - TableView Delegate Methods -
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
             managedContext.delete(people[indexPath.row] as NSManagedObject)
            
            do {
                try managedContext.save()
              //  self.tableView.reloadData()
            } catch {
                print("error : \(error)")
            }
            
            self.names.removeObject(at: indexPath.row)
            self.tbView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        
        let person = self.names[indexPath.row] as! NSDictionary
        cell.textLabel?.text = person.value(forKey: "product_name") as? String
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let VC = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        let person = self.people[indexPath.row]
        VC.strTitle = (person.value(forKey: "name") as? NSString)!
        self.navigationController?.pushViewController(VC, animated: true)
    }
}

