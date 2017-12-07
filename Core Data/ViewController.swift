
import UIKit
import MBProgressHUD
import Alamofire
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tbView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var names: NSMutableArray =  []
    var arrSearch = NSMutableArray()
    var searchActive:Bool = false
    var people: [NSManagedObject] = []
    
    // MARK: - UIView Life Cycle Methods -

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The List"
        tbView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "Cell")
        self.retriveData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - GET Data -
    
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
            for result in people {
                let dict = NSMutableDictionary()
                dict.setValue(result.value(forKey: "name"), forKey: "short_description")
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
        
        Alamofire.request("https://sixpacks.com/api/v1/browsebyFilter1", method: .post, parameters: dict as? [String : AnyObject], encoding: JSONEncoding.default, headers: [:])
            .responseJSON { response in switch response.result {
            case .success(let JSON):
                let dict = JSON as! NSDictionary
                let arr = dict.value(forKey: "response") as! NSArray
                
                for i in 0..<arr.count{
                    let dictData = arr.object(at: i) as! NSDictionary
                    self.names.add(dictData)
                    self.addData(name: dictData.value(forKey: "short_description") as! NSString)
                }
                self.tbView.reloadData()
                print(self.names)
            case .failure(let error):
                print("Request failed with error: \(error)")
                
            }
            self.hidHUD()
        }
    }
    
    // MARK: - Show HUD Methods -
    
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
            } catch {
                print("error : \(error)")
            }
            if searchActive {
                self.arrSearch.removeObject(at: indexPath.row)
                self.names.removeObject(at: indexPath.row)
            }
            else{
                self.names.removeObject(at: indexPath.row)
            }
            self.tbView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return self.arrSearch.count
        }
        return self.names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomCell = tableView.dequeueReusableCell(withIdentifier: "CustomCell") as! CustomCell
        if searchActive {
            let person = self.arrSearch[indexPath.row] as! NSDictionary
            cell.lblTitle.text = person.value(forKey: "short_description") as? String
        }
        else{
            let person = self.names[indexPath.row] as! NSDictionary
            cell.lblTitle.text = person.value(forKey: "short_description") as? String
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let VC = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        let person = self.people[indexPath.row]
        VC.strTitle = (person.value(forKey: "name") as? NSString)!
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    // MARK: - UISearchBar Delegate Methods -
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.arrSearch = NSMutableArray()
        if searchBar.text == "" {
            arrSearch = names
        } else {
            let predicate =
                NSPredicate(format: "short_description CONTAINS[cd] %@",searchText);
            
            let filteredArray = names.filter { predicate.evaluate(with: $0) };
            self.arrSearch.addObjects(from: filteredArray)
        }
        self.tbView.reloadData()
    }
}

