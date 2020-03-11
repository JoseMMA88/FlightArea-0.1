//
//  ViewController.swift
//  FlightArea-0.1
//
//  Created by Jose Manuel Malagón Alba on 05/03/2020.
//  Copyright © 2020 Jose Manuel Malagón Alba. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController , MKMapViewDelegate, CLLocationManagerDelegate {
    
    //MARK: OUTLETs
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    
    //MARK:VARs
    var polygon: MKPolygon?
    var points: [MKAnnotation] = []
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D!
    var startLocation: CGPoint?
    var d: Double = 0.00005
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //mapView.delegate = self
        
        initData()
        updatePolygon()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startUpdateLocation()
        //focusMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //locationManager?.stopUpdatingLocation()
    }
    
    
    //----------------------------- BUTOMS -------------------------------------------------
    
    @IBAction func focusBtnAction(_ sender: Any) {
        focusMap()
    }
    
 
    @IBAction func addPointBtnAction(_ sender: Any) {
        if(points.count == 0){
            let point = MKPointAnnotation()
            points.append(point)
            point.coordinate = CLLocation(latitude: userLocation.latitude + d, longitude: userLocation.longitude + d).coordinate
            mapView.addAnnotation(point)
        
           // d = d + 0.00015 // comentar
            NSLog(String(points.count))
            updatePolygon()
        }
        else{
            let point = MKPointAnnotation()
            points.append(point)
            let lat = points.last?.coordinate.latitude
            let long = points.last?.coordinate.longitude
            point.coordinate = CLLocation(latitude: lat! + d, longitude: long! + d).coordinate
            mapView.addAnnotation(point)
            NSLog(String(points.count))
            //d = d + 0.00015 // comentar
                  
            updatePolygon()
        }
        /*if(points){
            for i in 0..<points.count
        }*/
    }
    
    
   /* @IBAction func removeLastPointsBtnAction(_ sender: Any) {
        for i in 0..<points.count{
            if(i == ){
                points.remove(at: i)
            }
        }
        
    }*/
    
    
    
    //------------------------------ MAP VIEW ---------------------------------------------
    //MARK: MAPVIEW METHODS
    
    // Se llama al principio de la ejecucion y cuando movemos un annotation
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
          if overlay is MKPolygon {
              let polygonView = MKPolygonRenderer(overlay: overlay)
                  polygonView.strokeColor = .green
                  polygonView.lineWidth = 1.0
                  polygonView.fillColor = UIColor.green.withAlphaComponent(0.25)
              return polygonView
          }
          return MKOverlayRenderer()
      }
    
    
    // Se llama en segundo lugar
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? MKPointAnnotation else { return nil }
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "marker")
        
        if (view == nil){
            view = MKMarkerAnnotationView.init(annotation: annotation, reuseIdentifier: "marker")
            view?.canShowCallout = false
            view?.isDraggable = false
            
            // Sobreescribimos la logica de drag con la nuestra propia
            let drag = UILongPressGestureRecognizer(target: self, action: #selector(handleDrag(gesture:)))
            
            drag.minimumPressDuration = 0 // instant bru
            drag.allowableMovement = .greatestFiniteMagnitude
            view?.addGestureRecognizer(drag)
        }
        else{
            view?.annotation = annotation
        }
        
        return view
    }
    
    
    
    // Se llama a esta funcion cuando se arrastra un Annotation
    func mapView(_ mapView: MKMapView,
                 annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationView.DragState,
                 fromOldState oldState: MKAnnotationView.DragState) {
        updatePolygon()
    }
    
    
    //MARK: TOUCH HANDLING
    //Handle drag custom
    @objc func handleDrag(gesture: UILongPressGestureRecognizer){
        let annotationView = gesture.view as! MKAnnotationView
        annotationView.setSelected(false, animated: false)
        
        let location = gesture.location(in: mapView)
        
        if(gesture.state == .began){
            startLocation = location
        }
        else if (gesture.state == .changed){
            gesture.view?.transform = CGAffineTransform.init(translationX: location.x - startLocation!.x, y: location.y - startLocation!.y)
        }
        else if (gesture.state == .ended || gesture.state == .cancelled){
            let annotation = annotationView.annotation as! MKPointAnnotation
            let translate = CGPoint.init(x: location.x - startLocation!.x , y: location.y - startLocation!.y)
            let originalLocaton = mapView.convert(annotation.coordinate, toPointTo: mapView)
            let updatedLocation = CGPoint.init(x: originalLocaton.x + translate.x, y: originalLocaton.y + translate.y)
            
            annotationView.transform = CGAffineTransform.identity
            annotation.coordinate = mapView.convert(updatedLocation, toCoordinateFrom: mapView)
            
            //Actualizamos el poligono cuando acaba el gesto
            updatePolygon()
            
        }
    }
    
    
    
    
    // CLLocationManager delegate funcion, guardamos la poscion del usuario
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        if let coordinate = location?.coordinate{
            userLocation = coordinate
        }
    }
    
    
    // -----------------------------------------------------------------------------------
    
    
    
    func updatePolygon(){
        // Si hay polygon lo borramos
        if (polygon != nil){
            mapView.removeOverlay(polygon!)
        }
        
        // Creamos un nuevo poligono
        let coords = points.map { $0.coordinate }
        polygon = MKPolygon.init(coordinates: coords, count: coords.count)
        mapView.addOverlay(polygon!)
    }
    
    
    
    // Centra el mapView al UserLocation
    func focusMap(){
        let metr: CLLocationDistance = 200 //[m]
        if(userLocation != nil && CLLocationCoordinate2DIsValid(userLocation)){
            
            let region = MKCoordinateRegion.init(center: userLocation, latitudinalMeters: metr, longitudinalMeters: metr)
            
            mapView.setRegion(region, animated: true)
            

        }
        else{
            NSLog("NO TENGO LA LOCALIZACION")
        }
    }
    
    
    
    // Inicializa locationManager
    func startUpdateLocation(){
         if CLLocationManager.locationServicesEnabled(){
             if locationManager == nil {
                 locationManager = CLLocationManager.init()
                 locationManager?.delegate = self
                 locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                 locationManager?.distanceFilter = 0.1
                 
                 if (locationManager?.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)))!{
                     locationManager?.requestAlwaysAuthorization()
                 }
                 locationManager?.startUpdatingLocation()
             }
         }
     }
     
    
    func initData(){
        userLocation = kCLLocationCoordinate2DInvalid
        startLocation = CGPoint.zero
    }


}

