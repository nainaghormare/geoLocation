//
//  CustomMapView.swift
//  IotiedNurseApp
//
//  Created by Naina Ghormare on 6/12/19.
//  Copyright © 2019 smartData Enterprizes. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Polyline

class CustomMapView: GMSMapView {
    
    var strokeColor:UIColor         = .blue
    var strokeWidth:CGFloat         = 5.0
    
    var showUserLocation: Bool = false {
        didSet {
            self.isUserInteractionEnabled = self.showUserLocation
        }
    }
    
    //MARK: Draw path between two points
    func drawpath(array:[CLLocationCoordinate2D], startMarker:String?, endMarker:String?, isKilled: Bool)  {
        self.clear()
        let path                    = GMSMutablePath()
        for obj in array{
            path.add(CLLocationCoordinate2D(latitude: obj.latitude, longitude: obj.longitude))
        }
        let camera                  = GMSCameraPosition.camera(withLatitude: array[0].latitude, longitude: array[0].longitude, zoom: 20.0)
        self.camera                 = camera
        if !isKilled {
            let startmarker         = GMSMarker()
            let endmarker           = GMSMarker()
            
            startmarker.position    = CLLocationCoordinate2D(latitude: array[0].latitude, longitude: array[0].longitude)
            endmarker.position      = CLLocationCoordinate2D(latitude: (array.last?.latitude)!, longitude: (array.last?.longitude)!)
            
            startmarker.map         = self
            endmarker.map           = self
            
            if let start = startMarker {
                startmarker.icon    = UIImage(named: start)?.withRenderingMode(.alwaysTemplate)
            }
            if let end = endMarker {
                endmarker.icon      = UIImage(named: end)?.withRenderingMode(.alwaysTemplate)
            }
        }
        
        let rectangle = GMSPolyline(path: path)
        DispatchQueue.main.async {
            rectangle.strokeWidth = self.strokeWidth
            rectangle.strokeColor = self.strokeColor
            rectangle.map = self
        }
        let bounds = GMSCoordinateBounds(path: path)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 20)
        self.moveCamera(update)
    }
    
    //MARK: Live tracking
    func drawlivepath(userlocation: [CLLocation]) {
        let path = GMSMutablePath()
        for obj in userlocation{
            path.add(CLLocationCoordinate2D(latitude: obj.coordinate.latitude, longitude: obj.coordinate.longitude))
        }
        DispatchQueue.main.async {
            let polyline            = GMSPolyline(path: path)
            polyline.strokeWidth    = self.strokeWidth
            polyline.strokeColor    = self.strokeColor
            polyline.map            = self
        }
    }
    
}




