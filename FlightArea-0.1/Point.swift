//
//  Point.swift
//  FlightArea-0.1
//
//  Created by Jose Manuel Malagón Alba on 03/04/2020.
//  Copyright © 2020 Jose Manuel Malagón Alba. All rights reserved.
//

import Foundation
import MapKit

class Point{
    
    // MARK: VARS
    var coords: CLLocationCoordinate2D?
    var visited: Bool
    var index: Int
    
    
    init(coords: CLLocationCoordinate2D) {
        self.coords = coords
        self.visited = false
        self.index = 0
    }
    
    func setIndex(ind: Int){
        self.index = ind
    }
    
}
