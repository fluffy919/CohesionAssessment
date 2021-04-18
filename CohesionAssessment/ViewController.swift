//
//  ViewController.swift
//  CohesionAssessment
//
//  Created by B on 4/18/21.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    lazy var locationManager : CLLocationManager = CLLocationManager()
    let ENTERED_REGION_MESSAGE = "Welcome to Cohesion!"
    let ENTERED_REGION_NOTIFICATION_ID = "EnteredRegionNotification"
    let EXITED_REGION_MESSAGE = "Bye! Hope you had a great day in Cohesion!"
    let EXITED_REGION_NOTIFICATION_ID = "ExitedRegionNotification"
    var location: [NSManagedObject] = []
    let entityName = "EntryPoint"
    let Cohesion_Lat = 37.349304
    let Cohesion_Lon = -121.875630
    let geofenceRadius: CLLocationDistance = 400
    let notificationCenter = UNUserNotificationCenter.current()
    var managedContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.mapView.delegate = self
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        notificationCenter.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if granted { print("All set!") }
            else if let error = error { print(error.localizedDescription) }
        }
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        // To locate JSON file
        let dirPaths = NSSearchPathForDirectoriesInDomains(.applicationDirectory,
                                                           .userDomainMask, true)
        NSLog("%@", dirPaths.first!)
        
    }

    func setupGeofenceForCohesion() {
        
        let geofenceRegionCenter =
            CLLocationCoordinate2DMake(Cohesion_Lat, Cohesion_Lon)
        
        let geofenceRegion =
            CLCircularRegion(center: geofenceRegionCenter, radius: geofenceRadius, identifier: "CurrentLocation")
        geofenceRegion.notifyOnExit = true
        geofenceRegion.notifyOnEntry = true
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let mapRegion = MKCoordinateRegion(center: geofenceRegionCenter, span: span)
        self.mapView.setRegion(mapRegion, animated: true)
        
        let regionCircle = MKCircle(center: geofenceRegionCenter, radius: geofenceRadius)
        self.mapView.addOverlay(regionCircle)
        self.mapView.showsUserLocation = true;
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            self.locationManager.startMonitoring(for: geofenceRegion)
        }
        
    }
    
    // Saving, Fetching and Deleting Coredata
    func saveCoreData(latitudeVal: Double, longitudeVal: Double) {
      
        let entity =
            NSEntityDescription.entity(forEntityName: entityName,
                                   in: managedContext)!

        let location = NSManagedObject(entity: entity,
                                   insertInto: managedContext)
        
        let date = Date()
        
        location.setValue(latitudeVal, forKeyPath: "latitude")
        location.setValue(longitudeVal, forKeyPath: "longitude")
        location.setValue(date, forKey: "time")
      
        do {
            
            try managedContext.save()
            
        } catch let error as NSError {
            
            print("Could not save. \(error), \(error.userInfo)")
            
        }
    }
    
    func fetchCoreData() {
      
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: entityName)
      
        do {
            
            // Convert to JSON format for API call
            let locations = try managedContext.fetch(fetchRequest)
            convertToJSONArray(objectArray: locations)
            
            // Clear Core Data after fetched
            clearCoreData()
            
        } catch let error as NSError {
            
            print("Could not fetch. \(error), \(error.userInfo)")
            
        }
        
    }

    func clearCoreData() {
        
        let fetchRequest =
            NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        let batchDeleteRequest =
            NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            
            try managedContext.execute(batchDeleteRequest)
            
        } catch {
            
            print("Could not delete. \(error)")
            
        }
        
    }
    
    // From Core Data to JSON for API call
    func convertToJSONArray(objectArray: [NSManagedObject]) {
        
        var jsonArray: [[String: Any]] = []
        
        for item in objectArray {
            
            var dict: [String: Any] = [:]
            
            for attribute in item.entity.attributesByName {
                
                //Check if value is present, then add key to dictionary so as to avoid the nil value crash
                if let value = item.value(forKey: attribute.key) {
                    
                    if attribute.key == "time" {
                        
                        // Formatting date values for JSON standard
                        let dateFormat: DateFormatter = DateFormatter()
                        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        dict[attribute.key] = dateFormat.string(from: value as! Date)
                        
                    } else {
                        
                        dict[attribute.key] = value
                        
                    }
                    
                }
                
            }
            
            jsonArray.append(dict)
            
        }
        
        // Writing in local file instead of API call
        do {
            
            let fileUR = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("location.json")

            try JSONSerialization.data(withJSONObject: jsonArray)
                .write(to: fileUR)
            
        } catch {
            
            print("Fail of JSON \(error)")
            
        }
    }

}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if (status == CLAuthorizationStatus.authorizedAlways) {
            //App Authorized, make geofence
            self.setupGeofenceForCohesion()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        print("Started Monitoring Region: \(region.identifier)")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        print(ENTERED_REGION_MESSAGE)
        
        let lat = manager.location?.coordinate.latitude ?? 0.0
        let lon = manager.location?.coordinate.longitude ?? 0.0
        saveCoreData(latitudeVal: lat, longitudeVal: lon) // Save the entry location with the current time
        
        self.createLocalNotification(message: ENTERED_REGION_MESSAGE, identifier: ENTERED_REGION_NOTIFICATION_ID)
        
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        print(EXITED_REGION_MESSAGE)
        
        fetchCoreData() // Fetch value when exit the region
        
        self.createLocalNotification(message: EXITED_REGION_MESSAGE, identifier: EXITED_REGION_NOTIFICATION_ID)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func createLocalNotification(message: String, identifier: String) {
        
        //Create a local notification
        let content = UNMutableNotificationContent()
        content.title = "Cohesion"
        content.body = message
        content.sound = UNNotificationSound.default
        
        // Deliver the notification
        let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: nil)
        
        // Schedule the notification
        notificationCenter.add(request) { (error) in
        }
        
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let overlayRenderer : MKCircleRenderer = MKCircleRenderer(overlay: overlay);
        overlayRenderer.lineWidth = 4.0
        overlayRenderer.strokeColor = UIColor(red: 7.0/255.0, green: 106.0/255.0, blue: 255.0/255.0, alpha: 1)
        overlayRenderer.fillColor = UIColor(red: 0.0/255.0, green: 203.0/255.0, blue: 208.0/255.0, alpha: 0.7)
        
        return overlayRenderer
    }
    
}
