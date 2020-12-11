//
//  RouteViewController.swift
//  MyNavi
//
//  Created by Lin Cui on 2020-10-22.
//

import UIKit
import CoreLocation
import MapKit
//import CoreData

class RouteViewController: UIViewController, CLLocationManagerDelegate,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var textFrom: UITextField!
    @IBOutlet weak var textTo: UITextField!
    @IBOutlet weak var routeTable: UITableView!
    
    @IBOutlet weak var routeButton: UIButton!
    // let managedObjectContext: NSManagedObjectContext
   // var moStudents: [NSManagedObject] = []
    
    var fromLocation : CLLocation?
    var toLocation : CLLocation?
    
    var allRoutes : [MKRoute] = []
    
    var messageFromMap : CLLocation?
    
    var delegate : RouteViewDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(messageFromMap ?? "not found current location")
        // Do any additional setup after loading the view.
        routeButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allRoutes.count
    }//how many rows
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }//how big is the cell
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier:
                                                        "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        tableCell.textLabel?.text = "via \(allRoutes[indexPath.row].name): \(meterToKilometer(meters: allRoutes[indexPath.row].distance))km, \(secondsToHoursMinutesSeconds(seconds: Int(allRoutes[indexPath.row].expectedTravelTime)))"
        
        tableCell.textLabel?.font = UIFont.systemFont(ofSize: 12.5,weight: .bold)
        tableCell.accessoryType = .disclosureIndicator
        return tableCell
    }//What to put in cells
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if textFrom.text!.isEmpty {
            self.forwardGeocoding(address: textTo.text!, completion: { (location) in
                if let locationTo = location {
                    self.delegate?.routeViewDidFinish(sender: self, data: self.allRoutes[indexPath.row],fromLocation: self.messageFromMap!,toLocation: locationTo,fromName:"Current location",toPlaceName: self.textTo.text!)
                }
            })
        //delegate?.routeViewDidFinish(sender: self, data: allRoutes[indexPath.row],fromLocation: messageFromMap,toLocation: <#T##CLLocation#>)
        }else{
            forwardGeocoding(address:textFrom.text!, completion: { (location) in
                if let locationFrom = location {
                    // found source, try to find destination next
                    self.forwardGeocoding(address:self.textTo.text!, completion: { (location) in
                        if let locationTo = location {
                            // found destination, calculate routes
                            self.delegate?.routeViewDidFinish(sender: self, data: self.allRoutes[indexPath.row],fromLocation: locationFrom,toLocation: locationTo,fromName:self.textFrom.text!,toPlaceName: self.textTo.text!)
                        }
                        else {
                            // not found destination, show alert
                        }
                    })
                }
                else {
                    // not found the source, show alert
                }
            })
        }
        dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showRoute(_ sender: Any) {
        
        if textFrom.text!.isEmpty && textTo.text!.isEmpty{
            print("both empty")
            let alertController = UIAlertController(title: "Error", message: "Please fill all", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true)
        }else if !textFrom.text!.isEmpty && !textTo.text!.isEmpty{
            forwardGeocoding(address:textFrom.text!, completion: { (location) in
                if let locationFrom = location {
                    // found source, try to find destination next
                    self.forwardGeocoding(address:self.textTo.text!, completion: { (location) in
                        if let locationTo = location {
                            // found destination, calculate routes
                            self.route(from:locationFrom, to:locationTo)
                            
                        }
                        else {
                            // not found destination, show alert
                        }
                    })
                }
                else {
                    // not found the source, show alert
                }
            })
        }else if textFrom.text!.isEmpty && !textTo.text!.isEmpty{
            print("one empty, I am looking for this")
            self.forwardGeocoding(address:self.textTo.text!, completion: { (location) in
                if let locationTo = location {
                    // found destination, calculate routes
                    self.route(from:self.messageFromMap!, to:locationTo)
                    
                }
                else {
                    // not found destination, show alert
                }
            })
        }else{
            let alertController = UIAlertController(title: "Error", message: "Please fill all", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            self.present(alertController,animated: true)
        }
        
    }
    
    
    
    //address to location
    func forwardGeocoding(address: String, completion: @escaping((CLLocation?) -> Void)) -> Void
    {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if let error = error
            {
                print(error.localizedDescription)
                completion(nil) // passing null location
            }
            else
            {
                // pass the first location to the closure
                let placemark = placemarks?[0]
                completion(placemark?.location)
            }
        })
    }
    
    
    //location to address
    func reverseGeocoding(location: CLLocation, completion: @escaping((CLPlacemark?) -> Void))
    {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if let error = error
            {
                print(error.localizedDescription)
                completion(nil) // passing null placemark
            }
            else
            {
                // pass the first placemark to closure
                completion(placemarks?[0])
            }
        })
    }
    
    func route(from: CLLocation, to: CLLocation)
    {
        // request directions
        let request = MKDirections.Request()
        let fromPlacemark = MKPlacemark(coordinate: from.coordinate)
        let toPlacemark = MKPlacemark(coordinate: to.coordinate)
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        // calculate directions
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: { (response, error) in
            if let error = error {
                // show alert
                print(error)
                return
            }
            self.allRoutes = response!.routes
            if let routes = response?.routes
            {
                print("amount of route is \(self.allRoutes.count)")
                self.routeTable.reloadData()
                for route in routes
                {
                    print("Name: " + route.name)
                    print("Distance: \(route.distance)")
                    print("Expected Travel Time: \(route.expectedTravelTime)")
                }
            }
            
        })
        //print("2 nd amount of route is \(self.allRoutes.count)")
    }
    func secondsToHoursMinutesSeconds (seconds : Int) -> String {
      return "\(seconds / 3600):\((seconds % 3600) / 60):\((seconds % 3600) % 60)"
    }
    func meterToKilometer(meters:Double)-> String{
        return "\(meters/1000)"
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

protocol RouteViewDelegate : AnyObject
{
    
    //abstract function
    
    func routeViewDidFinish(sender:RouteViewController,data : MKRoute,fromLocation:CLLocation,toLocation:CLLocation,fromName:String,toPlaceName:String)
    
}
