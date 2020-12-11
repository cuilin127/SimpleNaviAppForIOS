//
//  MapViewController.swift
//  MyNavi
//
//  Created by Lin Cui on 2020-10-22.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate,RouteViewDelegate{
    
    
    let locationManager = CLLocationManager()
    var route : MKRoute?
    
    var currentLocation : CLLocation?
    var hasRoute : Bool = false
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var modeChanger: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        map.showsCompass = false  // Hide built-in compass

        var compassButton = MKCompassButton(mapView: map)   // Make a new compass
        compassButton.compassVisibility = .visible          // Make it visible

        map.addSubview(compassButton) // Add it to the view

        // Position it as required

        compassButton.translatesAutoresizingMaskIntoConstraints = false
        compassButton.trailingAnchor.constraint(equalTo: map.trailingAnchor, constant: -12).isActive = true
        compassButton.topAnchor.constraint(equalTo: map.topAnchor, constant: 12).isActive = true
        
        
        
        
        map.isRotateEnabled = true
        map.showsScale = true
        
        
        map.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        //ask for user permition
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
            
        }
        
    }
    @IBAction func changeMode(_ sender: Any) {
        
        if modeChanger.selectedSegmentIndex == 0{
            self.map.mapType = .standard
        }
        else if modeChanger.selectedSegmentIndex == 1{
            self.map.mapType = .satellite
        }
        else{
            self.map.mapType = .hybrid
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "goRoute"
        {
            //self.map.removeOverlay(map.overlays as! MKOverlay)
            if let vc = segue.destination as? RouteViewController
            {
                vc.delegate = self
                //cannot access ui component
                //vc.label.text = "from FirstViewController"
                vc.messageFromMap = currentLocation
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,didUpdateLocations locations: [CLLocation])
    {
        if let coord = locations.first?.coordinate {
            
            //labelLatitude.text = "Latitude: \(coord.latitude)"
            //labelLongitude.text = "Longitude: \(coord.longitude)"
            print("Latitude: \(coord.latitude)")
            print("Longitude: \(coord.longitude)")
            
            currentLocation =  locationManager.location
            print("current location is\(String(describing: currentLocation))")
            // update map
            let center = CLLocationCoordinate2D(latitude:coord.latitude,
                                                longitude:coord.longitude)
            let span = MKCoordinateSpan(latitudeDelta:(1/222.222),longitudeDelta:(1/222.222))
            let region = MKCoordinateRegion(center:center, span:span)
            map.setRegion(region, animated:true)
            locationManager.stopUpdatingLocation()
        }
    }
    func mapView(_ mapView:MKMapView,
                 rendererFor overlay:MKOverlay) -> MKOverlayRenderer
    {
        // if overlay is polyline, return MKPolylineRenderer
        if let polyline = overlay as? MKPolyline
        {
            let renderer = MKPolylineRenderer(polyline:polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer(overlay:overlay)
    }
    
    func routeViewDidFinish(sender: RouteViewController, data:MKRoute,fromLocation:CLLocation,toLocation:CLLocation,fromName:String,toPlaceName:String) {
        
        print("hello world")
        print(data.name)
        route = data
        let pin = MKPointAnnotation()
        pin.coordinate = toLocation.coordinate
        pin.title = toPlaceName
        self.map.addAnnotation(pin)
        if fromLocation != currentLocation{
            let pin2 = MKPointAnnotation()
            pin2.coordinate = fromLocation.coordinate
            pin2.title = fromName
            self.map.addAnnotation(pin2)
        }
        self.map.addOverlay(route!.polyline,level:MKOverlayLevel.aboveRoads)
        self.map.setVisibleMapRect(route!.polyline.boundingMapRect,animated:true)
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
