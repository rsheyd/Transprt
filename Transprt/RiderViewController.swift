//
//  RiderViewController.swift
//  Transprt
//
//  Created by Roman Sheydvasser on 12/16/16.
//  Copyright © 2016 RLabs. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var riderRequestActive = false
    var driverOnTheWay = false
    
    @IBOutlet weak var driverNameLbl: UILabel!
    @IBOutlet weak var driverDistanceLbl: UILabel!
    @IBOutlet weak var callTransBtn: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func logoutBtnPressed(_ sender: Any) {
        PFUser.logOutInBackground()
        locationManager.stopUpdatingLocation()
        self.performSegue(withIdentifier: "segueToLogin", sender: nil)
    }
    
    @IBAction func callTransBtnPressed(_ sender: Any) {
        if riderRequestActive {
            riderRequestActive = false
            callTransBtn.setTitle("Call a transprt", for: [])
            self.driverNameLbl.isHidden = true
            self.driverDistanceLbl.isHidden = true
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: { (objects, error) in
                if let riderRequests = objects {
                    for object in riderRequests {
                        object.deleteInBackground()
                    }
                }
            })
        } else {
            riderRequestActive = true
            
            callTransBtn.setTitle("Cancel transprt", for: [])
            self.driverNameLbl.isHidden = false
            self.driverNameLbl.text = "Requesting ride from local drivers..."
            
            if userLocation.latitude != 0 && userLocation.longitude != 0 {
                let riderRequest = PFObject(className: "RiderRequest")
                riderRequest["username"] = PFUser.current()?.username
                riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
                riderRequest.saveInBackground(block: { (success, error) in
                    if success {
                    } else {
                        self.displayAlert(title: "Error.", message: "Could not call transprt. Please try again.")
                    }
                })
            } else {
                displayAlert(title: "Could not call transprt.", message: "Cannot detect your location.")
            }
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // shows rider's current location with a pin
        if let location = manager.location?.coordinate {
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            if driverOnTheWay == false {
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(self.map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation
                annotation.title = "Your Location"
                self.map.addAnnotation(annotation)
            }
            
            // update user location in Parse
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: { (objects, error) in
                if let riderRequests = objects {
                    for object in riderRequests {
                        object["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                        object.saveInBackground()
                    }
                }
            })
        }
        
        if riderRequestActive == true {
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.current()?.username!)!)
            query.findObjectsInBackground(block: { (objects, error) in
                if let riderRequests = objects {
                    for riderRequest in riderRequests {
                        if let driverUsername = riderRequest["driverResponded"] {
                            let query = PFQuery(className: "DriverLocation")
                            query.whereKey("username", equalTo: driverUsername)
                            query.findObjectsInBackground(block: { (objects, error) in
                                if let driverLocations = objects {
                                    for driverLocationObject in driverLocations {
                                        if let driverLocation = driverLocationObject["location"] as? PFGeoPoint {
                                            self.driverOnTheWay = true
                                            self.driverDistanceLbl.isHidden = false
                                            
                                            self.driverNameLbl.text = "Your driver's name: \(driverUsername)"
                                            
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            let riderCLLocation = CLLocation(latitude:self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                                            let roundedDistance = round(distance * 100) / 100
                                            self.driverDistanceLbl.text = "Your driver is currently \(roundedDistance)km away."
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            self.map.setRegion(region, animated: true)
                                            
                                            self.map.removeAnnotations(self.map.annotations)
                                            
                                            let userAnnotation = MKPointAnnotation()
                                            userAnnotation.coordinate = self.userLocation
                                            userAnnotation.title = "Your location"
                                            self.map.addAnnotation(userAnnotation)
                                            
                                            let driverAnnotation = MKPointAnnotation()
                                            driverAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            driverAnnotation.title = "Your driver \(driverUsername)"
                                            self.map.addAnnotation(driverAnnotation)
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // check for active request
        callTransBtn.isHidden = true
        driverDistanceLbl.isHidden = true
        driverNameLbl.isHidden = true
        map.layer.borderWidth = 1
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        query.findObjectsInBackground(block: { (objects, error) in
            if let objects = objects {
                if objects.count > 0 {
                    self.riderRequestActive = true
                    self.callTransBtn.setTitle("Cancel transprt", for: [])
                    self.driverNameLbl.isHidden = false
                    self.driverNameLbl.text = "Requesting ride from local drivers..."
                }
            }
            self.callTransBtn.isHidden = false
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
