//
//  ViewController.swift
//  Switcheroo
//
//  Created by Samuel Lichlyter on 5/16/19.
//  Copyright © 2019 Samuel Lichlyter. All rights reserved.
//

import UIKit
import ArcGIS
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var mapSegmentedControl: UISegmentedControl!
    
    private let arcGISMapView: AGSMapView = {
        let mapView = AGSMapView()
        mapView.map = AGSMap(basemapType: .navigationVector, latitude: 44.5637844, longitude: -123.281633, levelOfDetail: 13)
        return mapView
    }()
    
    private var googleMapView: GMSMapView!
    
    private var heatmapLayer: GMUHeatmapTileLayer!
    private var gradientColors: [UIColor] = [.blue, .red]
    private var gradientStartPoints: [NSNumber] = [0.1, 1.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.addSubview(arcGISMapView)
        setupLayout(mapView: arcGISMapView)
        
        setupGoogleMap()
        setupLayout(mapView: googleMapView)
    }
    
    private func setupGoogleMap() {
        let camera = GMSCameraPosition(latitude: 44.5637844, longitude: -123.281633, zoom: 13)
        googleMapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        self.view.addSubview(googleMapView)
        googleMapView.isHidden = true
        setupGoogleHeatmap()
    }
    
    private func setupGoogleHeatmap() {
        heatmapLayer = GMUHeatmapTileLayer()
        heatmapLayer.radius = 50
        heatmapLayer.opacity = 0.8
        heatmapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartPoints, colorMapSize: 512)

        addHeatmap()

        heatmapLayer.map = googleMapView
    }
    
    private func addHeatmap() {
        var list = [GMUWeightedLatLng]()
        do {
            if let path = Bundle.main.url(forResource: "Location History", withExtension: "json") {
                let data = try Data(contentsOf: path)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    let locations = object["locations"] as! [[String: Any]]
                    for item in locations {
                        let lat = item["latitudeE7"] as! Double
                        let lng = item["longitudeE7"] as! Double
                        let coords = GMUWeightedLatLng(coordinate: CLLocationCoordinate2DMake(lat / 1e7, lng / 1e7), intensity: 1.0)
                        list.append(coords)
                    }
                } else {
                    print("Could not read JSON")
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        heatmapLayer.weightedData = list
    }
    
    private func setupLayout(mapView: UIView) {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: mapSegmentedControl.topAnchor, constant: -10).isActive = true
    }
    
    @IBAction func mapSegmentedControlValueChanged(_ sender: Any) {
        let selected = MapState(rawValue: mapSegmentedControl.selectedSegmentIndex)!
        switch selected {
        case .arcgis:
            arcGISMapView.isHidden = false
            googleMapView.isHidden = true
        case .google:
            arcGISMapView.isHidden = true
            googleMapView.isHidden = false
        }
    }
    
}

enum MapState: Int {
    case arcgis = 0
    case google
}

