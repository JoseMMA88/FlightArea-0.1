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
    
    // Path
    var fly_points: [CLLocationCoordinate2D] = []
    var triangles: [MKPolygon] = []
    var triangles2: [MKPolygon] = []
    var triangles3: [MKPolygon] = []
    var triangles4: [MKPolygon] = []
    var triangles5: [MKPolygon] = []
    var path_coord: [CLLocationCoordinate2D] = []
    var arr_circle_auxs2: [MKCircle] = []
    
    // Debug visual
    var routeLineView: MKPolylineRenderer?
    var annotations: [MKAnnotation] = []
    
    //Variables dron
    var kradio: Int = 15
    
    
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
    
    
    @IBAction func btnActionDebug(_ sender: Any){
        mapView.removeAnnotations(points)
        for i in 0..<fly_points.count{
            
            // Creamos Annotation
            let ano: MKPointAnnotation = MKPointAnnotation()
            ano.coordinate = fly_points[i]
            ano.title = String(i)
            mapView.addAnnotation(ano)
            
            if(i < fly_points.count-1){
                // Creamos lineas
                let lines: [CLLocationCoordinate2D] = [fly_points[i], fly_points[i+1]]
                let line = MKPolyline.init(coordinates: lines, count: 2)
                mapView.addOverlay(line)
            }
        }
        
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
          else if overlay is MKPolyline {
            routeLineView = MKPolylineRenderer(overlay: overlay)
            routeLineView!.strokeColor = UIColor.blue.withAlphaComponent(0.2)
            routeLineView!.fillColor = UIColor.blue.withAlphaComponent(0.2)
            routeLineView!.lineWidth = 45
            return routeLineView!
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
        
        // TRIANGULACION
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
        
        // Buscamos y dibujamos el punto mas cercano al dron
        if(path_coord.count > 0 && points.count > 2){
            for i in 0..<points.count{
                path_coord.append(points[i].coordinate)
            }
            updateCircle(coord: findStartWaypoint()!)
            
            // Anyadimos el punto mas cercano al path de vuelo
            // y creamos el flight path
            NSLog("----------------------------------------------------")
            NSLog("Path Coords: ")
            NSLog(String(path_coord.count))
            createFlightPath()
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
    
    
    
    
    /*// https://stackoverflow.com/questions/29513966/calculate-area-of-mkpolygon-in-an-mkmapview
    
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
    }*/
    
    
    // Draw MKCircle
    func updateCircle(coord: CLLocationCoordinate2D){
        let rad: CLLocationDistance = CLLocationDistance(kradio) //metros
        if (circle != nil){
            mapView.removeOverlay(circle!)
        }
        
        // Creamos el circulo
        circle = MKCircle.init(center: coord, radius: rad)
        
        //updatePeriPoints(cent: coord, rad: rad)
        mapView.addOverlay(circle!)
    }
    
    
    
    // Find the closest waypoint to DronLocation
    func findStartWaypoint() -> CLLocationCoordinate2D?{
        if(points.count>0){
            var aux = points[0]
            let p1 = MKMapPoint(userLocation)
            let p2 = MKMapPoint(points[0].coordinate)
            var dis = p1.distance(to: p2)
            for i in 0..<points.count {
                let dis2 = p1.distance(to: MKMapPoint(points[i].coordinate))
                if(dis2 < dis){
                    aux = points[i]
                    dis = dis2
                }
            }
            return aux.coordinate
        }
        else{
            return nil
        }
    }
    
    
    // Añade una coordenada a la array de coordenas path_coords
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
                
                if(dis < CLLocationDistance(kradio)){
                    distancia = false
                    //NSLog(String(dis))
                }

            }
            
            let mapPoint = MKMapPoint(point)
            let cgpoint = polygonView!.point(for: mapPoint)
            
            if(distancia == true && polygonView!.path.contains(cgpoint)){
                let center2 = MKCircle.init(center: point, radius: 5)
                mapView.addOverlay(center2)
                
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
    
    
    /*func updatePeriPoints(cent: CLLocationCoordinate2D, rad: CLLocationDistance){
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
    }*/
    
    
    // Calcula el centro del poligono y triangula con los verticles,
    // hace una segunda triangulacion a partir de la primera triangulacion
    func updateTriangles(poli: MKPolygon){
        var aux_points: [CLLocationCoordinate2D] = []
        
        // Añadimos el centro del poligono al path
        addPointoPath(point: poli.coordinate)
        
        // Borramos los triangulos si existes
        if(triangles.count > 0){
            mapView.removeOverlays(triangles)
            triangles.removeAll()
            aux_points.removeAll()
            mapView.removeOverlays(triangles2)
            triangles2.removeAll()
            mapView.removeOverlays(triangles3)
            triangles3.removeAll()
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
            /*mapView.addOverlay(aux_trian)*/
            triangles.append(aux_trian)
        }
        
        // Borramos circulos
        if(arr_circle_auxs2.count > 0){
            mapView.removeOverlays(arr_circle_auxs2)
            arr_circle_auxs2.removeAll()
        }
        for h in 0..<triangles.count{
            // Anyade y dibuja circulos
            addPointoPath(point: triangles[h].coordinate)
            
            
            for h1 in 0..<triangles[h].pointCount{
                var aux_arr: [CLLocationCoordinate2D] = []
                
                // Anyadimos puntos
                aux_arr.append(triangles[h].coordinate)
                let p2 = triangles[h].points()[h1 > 0 ? h1 - 1 : triangles[h].pointCount - 1]
                aux_arr.append(p2.coordinate)
                let p3 = triangles[h].points()[h1]
                aux_arr.append(p3.coordinate)
                
                
                // Dibujamos triangulos2
                let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
                //mapView.addOverlay(aux_trian)
                triangles2.append(aux_trian)
                
                // Anyane y dubuja circulos
                addPointoPath(point: aux_trian.coordinate)
            }
        }
        
        for h2 in 0..<triangles2.count{
            //Anyade y dibuja circulos
            addPointoPath(point: triangles2[h2].coordinate)
            
            for h22 in 0..<triangles2[h2].pointCount{
                var aux_arr: [CLLocationCoordinate2D] = []
                
                // Anyadimos puntos
                aux_arr.append(triangles2[h2].coordinate)
                let p2 = triangles2[h2].points()[h22 > 0 ? h22 - 1 : triangles2[h2].pointCount - 1]
                aux_arr.append(p2.coordinate)
                let p3 = triangles2[h2].points()[h22]
                aux_arr.append(p3.coordinate)
                
                
                // Dibujamos triangulos3
                let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
                triangles3.append(aux_trian)
                
                //Anyade y dibuja circulos
                addPointoPath(point: aux_trian.coordinate)
            }
        }
        
        
        for h3 in 0..<triangles3.count{
            //Anyade y dibuja circulos
            addPointoPath(point: triangles3[h3].coordinate)
            
            for h33 in 0..<triangles3[h3].pointCount{
                var aux_arr: [CLLocationCoordinate2D] = []
                
                // Anyadimos puntos
                aux_arr.append(triangles3[h3].coordinate)
                let p2 = triangles3[h3].points()[h33 > 0 ? h33 - 1 : triangles3[h3].pointCount - 1]
                aux_arr.append(p2.coordinate)
                let p3 = triangles3[h3].points()[h33]
                aux_arr.append(p3.coordinate)
                
                
                // Dibujamos triangulos3
                let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
                triangles4.append(aux_trian)
                
                //Anyade y dibuja circulos
                addPointoPath(point: aux_trian.coordinate)
            }
        }
        
        for h4 in 0..<triangles4.count{
            //Anyade y dibuja circulos
            addPointoPath(point: triangles4[h4].coordinate)
            
            for h44 in 0..<triangles4[h4].pointCount{
                var aux_arr: [CLLocationCoordinate2D] = []
                
                // Anyadimos puntos
                aux_arr.append(triangles4[h4].coordinate)
                let p2 = triangles4[h4].points()[h44 > 0 ? h44 - 1 : triangles4[h4].pointCount - 1]
                aux_arr.append(p2.coordinate)
                let p3 = triangles4[h4].points()[h44]
                aux_arr.append(p3.coordinate)
                
                
                // Dibujamos triangulos3
                let aux_trian = MKPolygon.init(coordinates: aux_arr, count: 3)
                triangles5.append(aux_trian)
                
                //Anyade y dibuja circulos
                addPointoPath(point: aux_trian.coordinate)
            }
        }
    }
    
    
    
    // Ordena la array path_coords dependiendo de cual sea el punto de inicio
    func createFlightPath(){
        var aux_coords: [CLLocationCoordinate2D] = path_coord
        var derecha_coords: [CLLocationCoordinate2D] = []
        var izquierda_coords: [CLLocationCoordinate2D] = []
        var enco: Bool = false
        if(fly_points.count>0){
            fly_points.removeAll()
        }
        
        // Empezamos por el punto mas cercano al dron
        fly_points.append(findStartWaypoint()!)
        
        var i = 0
        while ( i < aux_coords.count && enco == false){
            if(fly_points[0].latitude == aux_coords[i].latitude && fly_points[0].longitude == aux_coords[i].longitude){
                aux_coords.remove(at: i)
                enco=true
            }
            i+=1
        }
        
        let tam = aux_coords.count
        var n = 0
        while(n < tam){
            // Limpiamos
            if(izquierda_coords.count>0){
                izquierda_coords.removeAll()
            }
            if(derecha_coords.count>0){
                derecha_coords.removeAll()
            }
            
            
            // Miramos derecha - izquierda
            for n11 in 0..<aux_coords.count{
            if(pointsLongPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 2 && pointsLatPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 2 ||
                 pointsLatPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 0){
                derecha_coords.append(aux_coords[n11])
             }
             else if(pointsLongPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 1 &&
                 pointsLatPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 2 ||
                 pointsLatPosition(coord_guia: fly_points[n], coord2: aux_coords[n11]) == 0){
                 izquierda_coords.append(aux_coords[n11])
             }
            }
            
            if(derecha_coords.count != 0 || izquierda_coords.count != 0){
                // Avanzamos DERECHA
                if(derecha_coords.count>0){
                    var aux = derecha_coords[0]
                    let p1 = MKMapPoint(fly_points[n])
                    let p2 = MKMapPoint(derecha_coords[0])
                    var dis = p1.distance(to: p2)
                    for n112 in 0..<derecha_coords.count{
                        let dis2 = p1.distance(to: MKMapPoint(derecha_coords[n112]))
                        if(dis2 < dis){
                            aux = derecha_coords[n112]
                            dis = dis2
                        }
                    }
                    
                    var i2 = 0
                    var enco2 = false
                    while (i2 < derecha_coords.count && enco2==false){
                        if(aux.latitude == derecha_coords[i2].latitude && aux.longitude == derecha_coords[i2].longitude){
                            derecha_coords.remove(at: i2)
                            fly_points.append(aux)
                            enco2=true
                        }
                        i2+=1
                    }
                    
                    var i22 = 0
                    var enco22 = false
                    while (i22 < aux_coords.count && enco22==false){
                        if(aux.latitude == aux_coords[i22].latitude && aux.longitude == aux_coords[i22].longitude){
                            aux_coords.remove(at: i22)
                            enco22=true
                        }
                        i22+=1
                    }
                }
            
                // Avanzamos Izquierda
                else if(izquierda_coords.count>0){
                    var aux = izquierda_coords[0]
                    let p1 = MKMapPoint(fly_points[n])
                    let p2 = MKMapPoint(izquierda_coords[0])
                    var dis = p1.distance(to: p2)
                    for n113 in 0..<izquierda_coords.count{
                        let dis2 = p1.distance(to: MKMapPoint(izquierda_coords[n113]))
                        if(dis2 < dis){
                            aux = izquierda_coords[n113]
                            dis = dis2
                        }
                    }
                    
                    var i2 = 0
                    var enco2 = false
                    while (i2 < izquierda_coords.count && enco2==false){
                        if(aux.latitude == izquierda_coords[i2].latitude && aux.longitude == izquierda_coords[i2].longitude){
                            izquierda_coords.remove(at: i2)
                            fly_points.append(aux)
                            enco2=true
                        }
                        i2+=1
                    }
                    
                    var i22 = 0
                    var enco22 = false
                    while (i22 < aux_coords.count && enco22==false){
                        if(aux.latitude == aux_coords[i22].latitude && aux.longitude == aux_coords[i22].longitude){
                            aux_coords.remove(at: i22)
                            enco22=true
                        }
                        i22+=1
                    }
                }
                n+=1
            }
            
            else if (derecha_coords.count == 0 && izquierda_coords.count == 0){
                // Avanzamos DELANTE
                var aux = aux_coords[0]
                let p1 = MKMapPoint(fly_points[n])
                let p2 = MKMapPoint(aux_coords[0])
                var dis = p1.distance(to: p2)
                for n1 in 0..<aux_coords.count{
                    let dis2 = p1.distance(to: MKMapPoint(aux_coords[n1]))
                    if(dis2 < dis){
                        aux = aux_coords[n1]
                        dis = dis2
                    }
                }
                var i2 = 0
                var enco2 = false
                while (i2 < aux_coords.count && enco2==false){
                    if(aux.latitude == aux_coords[i2].latitude && aux.longitude == aux_coords[i2].longitude){
                        aux_coords.remove(at: i2)
                        fly_points.append(aux)
                        enco2=true
                    }
                    i2+=1
                }
                n+=1
            }
        }
        
        NSLog("-----------------------------------------------------")
        for i3 in 0..<fly_points.count{
            NSLog(String(fly_points[i3].latitude))
            NSLog(String(fly_points[i3].longitude))
        }
        NSLog("-----------------------------------------------------")
    }
    
    // Si devuelve 1 esta al Oeste
    // Si devuelve 2 esta al Este
    // Si devuelve 0 esta en la misma Longitud
    func pointsLongPosition(coord_guia: CLLocationCoordinate2D, coord2: CLLocationCoordinate2D) -> Int{
        if(coord_guia.longitude < coord2.longitude){
            return 2
        }
        else if(coord_guia.longitude > coord2.longitude){
            return 1
        }
        return 0
    }
    
    
    // Si devuelve 1 esta al Norte
    // Si devuelve 2 esta al Sur
    // Si devuelve 0 esta en la misma Latitud
    func pointsLatPosition(coord_guia: CLLocationCoordinate2D, coord2: CLLocationCoordinate2D) -> Int{
        if(coord_guia.latitude < coord2.latitude){
            return 1
        }
        else if(coord_guia.latitude > coord2.latitude){
            return 2
        }
        return 0
    }
    
    
    
    
}

