//
//  DriverViewController.swift
//  Transprt
//
//  Created by Roman Sheydvasser on 12/16/16.
//  Copyright © 2016 RLabs. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var requestUsernames = [String]()
    var requestLocations = [CLLocationCoordinate2D]()
    
    var driverLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToLogin" {
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
            self.navigationController?.navigationBar.isHidden = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // gets rider requests based on drider's current location
        if let location = manager.location?.coordinate {
            let query = PFQuery(className: "RiderRequest")
            
            driverLocation = location
            
            query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
            query.limit = 10
            query.findObjectsInBackground(block: {(objects, error) in
                if let riderRequests = objects {
                    self.requestUsernames.removeAll()
                    self.requestLocations.removeAll()
                    for riderRequest in riderRequests {
                        if let username = riderRequest["username"] as? String {
                            self.requestUsernames.append(username)
                        }
                        if let location = riderRequest["location"] as? PFGeoPoint {
                            self.requestLocations.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                        }
                    }
                    self.tableView.reloadData()
                } else {
                    print("No results")
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestUsernames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let riderCLLocation: CLLocation
        
        // find distance between driverLocation and requestLocation
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        if indexPath.row < requestLocations.count {
            riderCLLocation = CLLocation(latitude: requestLocations[indexPath.row].latitude, longitude: requestLocations[indexPath.row].longitude)
            let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
            
            cell.textLabel?.text = requestUsernames[indexPath.row] + " - \(distance)km away"
        } else {
            print("error: no request location at this index")
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
