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
    var circle: MKCircle?
    var points: [MKAnnotation] = []
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D!
    var startLocation: CGPoint?
    var d: Double = 0.00015
    var kEarthRadius = 6378137.0 //Radio en el ecuador de la tierra
    
    
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
            
            updatePolygon()
        }
        else{
            let point = MKPointAnnotation()
            points.append(point)
            let lat = points[0].coordinate.latitude
            let long = points[0].coordinate.longitude
            point.coordinate = CLLocation(latitude: lat + d, longitude: long + d).coordinate
            mapView.addAnnotation(point)
                  
            updatePolygon()
        }
            
    }
    
    
    @IBAction func removeLastPointsBtnAction(_ sender: Any) {
        let annos: NSArray = NSArray.init(array: mapView!.annotations)
        var borrlat: Double = 0
        var borrlong: Double = 0
        
        // Borramos en la array points
        for i in 0..<points.count{
            if(i == (points.count-1)){
                //if (!(ann!.isEqual(self.aircraftAnnotation)))
                borrlat = points[i].coordinate.latitude
                borrlong = points[i].coordinate.longitude
                                       
                points.remove(at: i)
            }
        }
        
        // Borramos en la array de Annotations
        for n in 0..<annos.count{
            weak var ann = annos[n] as? MKAnnotation
                if((borrlat == ann!.coordinate.latitude) && (borrlong == ann!.coordinate.longitude)){
                    // Borramos annotation
                    mapView?.removeAnnotation(ann!)
                }
        }
        updatePolygon()
  
    }
    
    
    
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
          else if overlay is MKCircle {
            let circleView = MKCircleRenderer(overlay: overlay)
            circleView.strokeColor = .red
            circleView.lineWidth = 2.0
            circleView.fillColor = UIColor.red.withAlphaComponent(0.25)
            return circleView
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
            //NSLog(String(polygon!.interiorPolygons!.capacity))
            mapView.removeOverlay(polygon!)
        }
        
        // Creamos un nuevo poligono
        let coords = points.map { $0.coordinate }
        polygon = MKPolygon.init(coordinates: coords, count: coords.count)
        
        NSLog(String(regionArea(locations: coords)))
       
        mapView.addOverlay(polygon!)
        if(points.count > 0){
            updateCircle(coord: findStartWaypoint()!)
            NSLog("------------------------------------------")
            NSLog(String(findStartWaypoint()!.latitude))
            NSLog(String(findStartWaypoint()!.longitude))
            NSLog("------------------------------------------")
        }
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

    func radians(degrees: Double) -> Double{
        return degrees * .pi / 100
    }
    
    
    
    
    // https://stackoverflow.com/questions/29513966/calculate-area-of-mkpolygon-in-an-mkmapview
    
    // Calcula el area del poligono respecto del mapa en metros cuadrados
    // tiene en cuenta el radio de la tierra
    // The Spherical Case equation - Some Algorithms for polygons on a Sphere by Chamberlain & Duquette
    // NASA
    func regionArea(locations: [CLLocationCoordinate2D]) -> Double {
        guard locations.count > 2 else { return 0 }
        var area = 0.0
        
        for i in 0..<locations.count {
            let p1 = locations[i > 0 ? i - 1 : locations.count - 1]
            let p2 = locations[i]
            
            area += radians(degrees: p2.longitude - p1.longitude) * (2 + sin(radians(degrees: p1.latitude)) + sin(radians(degrees: p2.latitude)) )
            
        }
        area = -(area * kEarthRadius * kEarthRadius / 2)
        return max(area, -area)
    }
    
    
    // Draw MKCircle
    func updateCircle(coord: CLLocationCoordinate2D){
        let rad: CLLocationDistance = 20
        if (circle != nil){
                  //NSLog(String(polygon!.interiorPolygons!.capacity))
                  mapView.removeOverlay(circle!)
              }
        
        circle = MKCircle.init(center: coord, radius: rad)
        mapView.addOverlay(circle!)
    }
    
    
    
    // Find the closest waypoint
    func findStartWaypoint() -> CLLocationCoordinate2D?{
        if(points.count>0){
            var aux = points[0].coordinate
            let p1 = MKMapPoint(userLocation)
            let p2 = MKMapPoint(points[0].coordinate)
            var dis = p1.distance(to: p2)
            for i in 0..<points.count {
                let dis2 = p1.distance(to: MKMapPoint(points[i].coordinate))
                if(dis2 < dis){
                    aux = points[i].coordinate
                    dis = dis2
                }
            }
            return aux
        }
        else{
            return nil
        }
    }

}

