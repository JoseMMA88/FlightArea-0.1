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
    var polygonView: MKPolygonRenderer?
    var circle: MKCircle?
    var circleView: MKCircleRenderer?
    var center: MKCircle?
    
    
    var points: [MKAnnotation] = [] // Aristas del poligono
    var locationManager: CLLocationManager?// Controlador de localizacion
    var userLocation: CLLocationCoordinate2D!// Localizacion del usuario en tiempo real
    var startLocation: CGPoint?
    var d: Double = 0.00015
    
    // Calcular area
    var kEarthRadius = 6378137.0 //Radio en el ecuador de la tierra
    
    // Puntos del perimetro del circulo
    var peripoints: [CLLocationCoordinate2D] = []
    var arr_circle_auxs: [MKCircle] = []
    
    //Path
    var path: [MKAnnotation] = []
    var triangles: [MKPolygon] = []
    var path_coord: [CLLocationCoordinate2D] = []
    var arr_circle_auxs2: [MKCircle] = []
    
    
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
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.strokeColor = .green
            polygonView!.lineWidth = 1.0
            polygonView!.fillColor = UIColor.green.withAlphaComponent(0.25)
            return polygonView!
          }
          else if overlay is MKCircle {
            circleView = MKCircleRenderer(overlay: overlay)
            circleView!.strokeColor = .red
            circleView!.lineWidth = 2.0
            circleView!.fillColor = UIColor.red.withAlphaComponent(0.25)
            return circleView!
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
        
        //NSLog(String(regionArea(locations: coords)))
       
        mapView.addOverlay(polygon!)
        if(points.count > 0){
            updateCircle(coord: findStartWaypoint()!)
        }
        if(points.count > 2){
            if(center != nil){
                mapView.removeOverlay(center!)
            }
            if(path_coord.count > 0){
                path_coord.removeAll()
                //arr_circle_auxs2.removeAll()
            }
            let centr = polygon!.coordinate
            
            // Creamos el circulo
            center = MKCircle.init(center: centr, radius: 5)
            mapView.addOverlay(center!)
            
            //Triangulamos
            updateTriangles(poli: polygon!)
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
        return degrees * .pi / 180
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
        let rad: CLLocationDistance = 15 //metros
        if (circle != nil){
            mapView.removeOverlay(circle!)
        }
        
        // Creamos el circulo
        circle = MKCircle.init(center: coord, radius: rad)
        
        updatePeriPoints(cent: coord, rad: rad)
        mapView.addOverlay(circle!)
    }
    
    
    
    // Find the closest waypoint to DronLocation
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
    
    // Create waypoints path
    func createFlightPath(){
    }
    
    func addPointoPath(point: CLLocationCoordinate2D){
        var distancia = true
        
        if(path_coord.count == 0){
            path_coord.append(point)
        }
        else{
            let p2 = MKMapPoint(point)
            for i in 0..<path_coord.count{
                let p1 = MKMapPoint(path_coord[i])
                let dis = p2.distance(to: p1)
                if(dis < 15){
                    distancia = false
                    //NSLog(String(dis))
                }
                else{
                }
            }
            if(distancia == true){
                let center2 = MKCircle.init(center: point, radius: 5)
                mapView.addOverlay(center2)
                NSLog("------------------------------------")
                NSLog(String(point.latitude))
                NSLog(String(point.longitude))
                NSLog("------------------------------------")
                // Añadimos los puntos medios al path
                arr_circle_auxs2.append(center2)
                path_coord.append(point)
                distancia = false
            }
        }

    }
    
    // Calculamos unos 40 puntos del circulo
    // https://stackoverflow.com/questions/32242498/get-all-points-coordinate-on-a-mkcircle
    func radiusSearchPoints(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> [CLLocationCoordinate2D]{
        var peripoints: [CLLocationCoordinate2D] = []
        let lat = radians(degrees: center.latitude)
        let long = radians(degrees: center.longitude)
        
        var t: Double = 0
        while t <= 2 * .pi {
            let pointLat = lat + (radius / kEarthRadius) * sin(t)
            let pointLng = long + (radius / kEarthRadius) * cos(t)
            
            let point = CLLocationCoordinate2D(latitude: pointLat * 180 / .pi, longitude: pointLng * 180 / .pi)
            peripoints.append(point)
            t += 0.1
        }
        return peripoints
    }
    
    
    func updatePeriPoints(cent: CLLocationCoordinate2D, rad: CLLocationDistance){
        // Si hay dibujados, los borramos
        if(arr_circle_auxs.count > 0){
            mapView.removeOverlays(arr_circle_auxs)
            peripoints.removeAll()
        }
        
        // Obtenemos los puntos del perimetro
        // y los dibujamos
         if(polygon != nil && points.count > 2){
             peripoints = radiusSearchPoints(center: cent, radius: rad)
             for i in 0..<peripoints.count{
                 let mapPoint = MKMapPoint(peripoints[i])
                 let cgpoint = polygonView!.point(for: mapPoint)
                 if(polygonView!.path.contains(cgpoint)){
                    let circle_aux = MKCircle.init(center: peripoints[i], radius: 1)
                    arr_circle_auxs.append(circle_aux)
                    mapView.addOverlay(circle_aux)
                 }
             }
         }
    }
    
    // Calcula las diagonales del poligono y las dibuja
    func updateTriangles(poli: MKPolygon){
        var aux_points: [CLLocationCoordinate2D] = []
        
        // Añadimos el centro del poligono al path
        addPointoPath(point: poli.coordinate)
        
        // Borramos los triangulos si existes
        if(triangles.count > 0){
            mapView.removeOverlays(triangles)
            triangles.removeAll()
            aux_points.removeAll()
        }
        // Creamos los primero triangulos
        for i in 0..<points.count{
            if(i == 0){
                aux_points.append(poli.coordinate)
            }
            var aux_arr: [CLLocationCoordinate2D] = []
            aux_arr.append(poli.coordinate)
            
            let p1 = points[i > 0 ? i - 1 : points.count - 1]
            aux_arr.append(p1.coordinate)
            aux_points.append(p1.coordinate)
            
            let p2 = points[i]
            aux_arr.append(p2.coordinate)
            aux_points.append(p2.coordinate)
            
            // Dibujamos los triangulos
            let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
            mapView.addOverlay(aux_trian)
            triangles.append(aux_trian)
        }
        
        // Borramos circulos
        if(arr_circle_auxs2.count > 0){
            mapView.removeOverlays(arr_circle_auxs2)
            arr_circle_auxs2.removeAll()
        }
        for h in 0..<triangles.count{
            // Dibujar circulos
            /*let center2 = MKCircle.init(center: triangles[h].coordinate, radius: 5)
            mapView.addOverlay(center2)
            
            // Añadimos los puntos medios al path
            arr_circle_auxs2.append(center2)*/
            addPointoPath(point: triangles[h].coordinate)
            
            /*NSLog("-----------------------------------------")
            NSLog(String(triangles.count))
            NSLog(String(triangles[h].pointCount))
            NSLog("-----------------------------------------")*/
            
            for h1 in 0..<triangles[h].pointCount{
                var aux_arr: [CLLocationCoordinate2D] = []
                
                // Añadimos puntos
                aux_arr.append(triangles[h].coordinate)
                let p2 = triangles[h].points()[h1 > 0 ? h1 - 1 : triangles[h].pointCount - 1]
                aux_arr.append(p2.coordinate)
                let p3 = triangles[h].points()[h1]
                aux_arr.append(p3.coordinate)
                
                
                // Dibujamos triangulos2
                let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
                mapView.addOverlay(aux_trian)
                triangles.append(aux_trian)
                
                // Dibujar circulos
                /*let center3 = MKCircle.init(center: aux_trian.coordinate, radius: 5)
                mapView.addOverlay(center3)
                           
                // Añadimos los puntos medios al path
                arr_circle_auxs2.append(center3)*/
                addPointoPath(point: aux_trian.coordinate)
            }
        }
        /*NSLog("------------------------------------")
        NSLog(String(path_coord.count))
        NSLog(String(arr_circle_auxs2.count))
        NSLog("------------------------------------")*/
    }
    

}

