//
//  ViewController.swift
//  GeoLocation
//
//  Created by Naina Ghormare on 8/20/19.
//  Copyright © 2019 Naina Ghormare. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class TrackingViewController: UIViewController, GMSMapViewDelegate  {
    
    class func initiateController() -> TrackingViewController {
        let storyboard  = UIStoryboard(name: "Main", bundle: nil)
        let controller  = storyboard.instantiateViewController(withIdentifier: "TrackingViewController") as! TrackingViewController
        return controller
    }
    
    //MARK:- Outlets and variables
    @IBOutlet weak var btnReached           : UIButton!
    @IBOutlet weak var mapView              : CustomMapView!
    
//    var appointmentDetail                   = AppointmentList()
    var geofence                            = CLCircularRegion()
    var timer                               : Timer?
    var isReached                           = false
    
    //MARK:- Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if !LocationManager.shared.isTrackingStarted {
            mapView.clear()
        }
        
        let geofenceRegionCenter        = CLLocationCoordinate2DMake(21.1458, 79.0882)
        let geofenceRegion              = CLCircularRegion(center: geofenceRegionCenter,
                                                           radius: 1000,
                                                           identifier: "id")
        geofenceRegion.notifyOnEntry    = true
        geofenceRegion.notifyOnExit     = true
        self.geofence                   = geofenceRegion
        LocationManager.shared.locationManager.startMonitoring(for: geofence)
        locationSetup()
        
        LocationManager.shared.startManager()
        self.updateLocation(nil)
        mapView.isMyLocationEnabled                         = true
        self.tabBarController?.tabBar.isHidden              = true
        self.navigationController?.navigationBar.isHidden   = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Draw Path
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocation), name: NSNotification.Name(rawValue: "NSNotification.Name.UpdateLocation"), object: nil)
        
        //Do whatever you want, if entered in fence
        NotificationCenter.default.addObserver(self, selector: #selector(reachedInFence), name: NSNotification.Name(rawValue: "NSNotification.Name.ReachedInFence"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK:- Custom functions
    
    func locationSetup() {
//        let reachability = Reachability()
//        if !(reachability?.isReachable ?? false) {
//            showAlert(with: "No Internet Connection" )
//        }
        let serviceEnabled = LocationManager.shared.checklocationenable()
        if !serviceEnabled {
            let alertAction = AlertButton.init(style: .default, title: "Settings")
            let alertCancelAction = AlertButton.init(style: .cancel, title: "Cancel")
            _ = AlertManager.showAlert(withTitle: "ApplictionName" , withMessage: "Please enable location services to 'Always' for this app." , buttons: [alertAction, alertCancelAction], onViewController: self, animatedly: true, presentationCompletionHandler:nil, returnBlock: { (index) in
                switch index {
                case 0:
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        fatalError("Not approved")
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                case 1:
                    self.dismiss(animated: true, completion: nil)
                default:
                    break
                }
            }).view.tintColor = .blue
        } else {
            self.timer                      = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { (timer) in
                self.getAddressFromLatLong()
            })
        }
    }
    
    func getAddressFromLatLong() {
        LocationManager.shared.startManager()
        guard let currentLocation = LocationManager.shared.currentUserLocation else {
            let alertAction = AlertButton.init(style: .default, title: "Ok")
            _ = AlertManager.showAlert(withTitle: "ApplictionName" , withMessage: "Unable to fetch location." , buttons: [alertAction], onViewController: self, animatedly: true, presentationCompletionHandler:nil, returnBlock: { (index) in
                switch index {
                case 0:
                    self.navigationController?.popViewController(animated: true)
                default:
                    break
                }
            }).view.tintColor = .blue
            return
        }
        var startaddressstring : String = ""
        let ceo: CLGeocoder = CLGeocoder()
        ceo.reverseGeocodeLocation(currentLocation, completionHandler:
            {(placemarks, error) in
                if (error != nil) {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks
                if pm?.count ?? 0 > 0 {
                    let pm = placemarks?[0]
                    if pm?.name != nil {
                        startaddressstring = startaddressstring + (pm?.name ?? "")  + ", "
                    }
                    if pm?.subLocality != nil {
                        startaddressstring = startaddressstring + (pm?.subLocality ?? "") + ", "
                    }
                    if pm?.locality != nil {
                        startaddressstring = startaddressstring + (pm?.locality ?? "") + ", "
                    }
                    if pm?.country != nil {
                        startaddressstring = startaddressstring + (pm?.country ?? "") + ", "
                    }
                    if pm?.postalCode != nil {
                        startaddressstring = startaddressstring + (pm?.postalCode ?? "") + " "
                    }
                    if !LocationManager.shared.isTrackingStarted {
                        if startaddressstring != "" {
                            UserDefaults.standard.set(Date(), forKey: "startTime")
                            UserDefaults.standard.set(startaddressstring, forKey: "stratAddress")
                            UserDefaults.standard.set(true, forKey: "StartTravel")
                        }
                    }
                }
        })
    }
    
    //MARK:- @objc
    @objc func updateLocation(_ notification: Notification?) {
        if let location = LocationManager.shared.currentUserLocation {
            let camera          = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15.0)
            self.mapView.camera = camera
            let patientLocation = CLLocation(latitude: self.geofence.center.latitude, longitude: self.geofence.center.longitude)
            let distance = location.distance(from: patientLocation)
            if distance <= 1000 {
                isReached = true
            }
            if UserDefaults.standard.bool(forKey: "StartTravel") {
                DispatchQueue.main.async {
                    if LocationManager.shared.allcoordinates.count > 0 {
                        self.mapView.drawlivepath(userlocation: LocationManager.shared.allcoordinates)
                    }
                }
            }
        }
    }
    
    @objc func reachedInFence(_ notification: Notification?) {
        self.isReached = true
    }
    
    //MARK:- IBActions
    @IBAction func actionReached(_ sender: Any) {
        if !isReached {
//            self.showAlert(with: "You have not reached the patient's location yet.")
        } else {
//            apiCallToSaveReached()
        }
    }
    
}
