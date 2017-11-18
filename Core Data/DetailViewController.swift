
import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var txtTitle: UITextField!
    
    var strTitle = NSString()
    
    // MARK : - UIView Life Cycle Methods -

    override func viewDidLoad() {
        super.viewDidLoad()
        txtTitle.text = self.strTitle as String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK : - UIbutton Action Methods -
    
    @IBAction func btnUpdate(_ sender: AnyObject){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        
        do {
            let array_users = try managedContext.fetch(fetchRequest)
            let user = array_users[0]
            
            user.setValue(txtTitle.text, forKey: "name")
            //save the context
            do {
                try managedContext.save()
                print("saved!")
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {
                
            }
        } catch {
            print("Error with request: \(error)")
        }
        self.navigationController?.popViewController(animated: true)
    }
}
