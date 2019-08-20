//
//  LocationManager.swift
//  IotiedNurseApp
//
//  Created by Naina Ghormare on 5/28/19.
//  Copyright © 2019 smartData Enterprizes. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import Polyline

class LocationManager: NSObject {
    
    static let shared                               = LocationManager()
    var allcoordinates          : [CLLocation]      = []
    var currentUserLocation     : CLLocation?
    
    lazy var locationManager    : CLLocationManager = {
        return CLLocationManager()
    }()
    
    var isTrackingStarted: Bool {
        return UserDefaults.standard.bool(forKey: "StartTravel")
    }
    
    var totalDistance: Double {
        var distance            = 0.0
        var startLoc            : CLLocation?
        for loc in allcoordinates {
            distance            += (startLoc?.distance(from: loc) ?? 0.0)/1000
            startLoc            = loc
        }
        return distance
    }
    
    //Do all setup of mapview according to your requirement and make delegate to self here.
    func setupLocationManager() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.allowsBackgroundLocationUpdates    = false
        self.locationManager.distanceFilter                     = 7
        self.locationManager.activityType                       = .automotiveNavigation
        self.locationManager.delegate                           = self
        // save previous coordinates
        self.allcoordinates             = []//getCordinatesFromLocalDB()
    }
    
    //While starting the tracking make setup here for updating location.
    func startManager() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startMonitoringSignificantLocationChanges()
                self.locationManager.startUpdatingLocation()
            }
        } else {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    //In stopManager stop the services you dont require after stoping the tracking.
    func stopManager() {
        //        self.locationManager.stopUpdatingLocation()
        //        self.locationManager.stopMonitoringSignificantLocationChanges()
        if #available(iOS 11.0, *) {
            self.locationManager.showsBackgroundLocationIndicator   = false
        } else {
            // Fallback on earlier versions
        }
    }
    
    //MARK: Location Permission in foreground
    func checklocationenable() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied, .authorizedWhenInUse:
                return false
            case .authorizedAlways:
                return true
            }
        } else {
            return false
        }
    }
    
    //If you are saving the coordintes in coreData then retrieve cordinates from stored string of polyline.
//    func getCordinatesFromLocalDB() -> [CLLocation] {
//        var returnArray                 = [CLLocation]()
//        let ongoingTrack                = CoreDataStackManager.sharedManager.getCurrentTrackData()
//        if self.isTrackingStarted {
//            let decodedCoordinates      : Array<CLLocationCoordinate2D> = decodePolyline(ongoingTrack[0].polyline ?? "", precision: 1e5) ?? [CLLocationCoordinate2D]()
//            for cordinates in decodedCoordinates {
//                let getLat              : CLLocationDegrees = cordinates.latitude
//                let getLon              : CLLocationDegrees = cordinates.longitude
//                let getLatLon           : CLLocation        = CLLocation(latitude: getLat, longitude: getLon)
//                returnArray.append(getLatLon)
//            }
//        }
//        return returnArray
//    }
    
    //Save all your tracking data (ids, coordintes, path) in coredata
    func saveLocation(location: CLLocation) {
//        let ongoingTrack                = CoreDataStackManager.sharedManager.getCurrentTrackData()
        let distance                    = (self.allcoordinates.last)?.distance(from: location) ?? 0.0
        let km                          = distance/1000
        if km <= 1.0 {
            self.allcoordinates.append(location)
        }
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    // MARK: CLLocationManagerDelegate methods
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            print("User denied for Location Service")
        case .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startMonitoringSignificantLocationChanges()
            print("Successfully Authorized for Location Service")
        case .authorizedWhenInUse:
            print("Limited Location Service Authorized")
        default:
            print("Something went wrong with Location Service")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            print("L: 196 Something went wrong with Location Service\(error.localizedDescription)")
            manager.stopMonitoringSignificantLocationChanges()
            return
        }
        print("L: 200 Something went wrong with Location Service\(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            //Save the location from here.
            self.currentUserLocation = location
            if self.isTrackingStarted && location.horizontalAccuracy > 0.0 && location.horizontalAccuracy < 20.0 {
                self.saveLocation(location: location)
            }
            //Fire notification to controller where you want to show GMSCameraPosition and draw live path.
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NSNotification.Name.UpdateLocation"), object: nil)
        }
    }
    
    // called when user Enters a monitored region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            // Note enter time
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NSNotification.Name.ReachedInFence"), object: nil)
            print("Entered region")
        }
    }
    
    // called when user Exits a monitored region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            // Note exit time. Calculate hours spent at a location. Also store entered time and exited time
            print("Exited region")
        }
    }
    
}


