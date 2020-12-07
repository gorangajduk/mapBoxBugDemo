//
//  MapViewController.swift
//  mbBugDemo
//
//  Created by Goran Gajduk on 12/3/20.
//

import Mapbox

class MapViewController: UIViewController, MGLMapViewDelegate {
    @IBOutlet weak var mapView: MGLMapView!
    var loadBuggyVersion = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // basic mapview setup
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 62.11, longitude: 7.23), zoomLevel: 4, animated: false)
        
        // add toggle button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Toggle style",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(changeStyle))
        
        // set map style
        if loadBuggyVersion,
           let styleURL = self.getTopoStyleURL() {
            mapView.styleURL = styleURL
        } else {
            mapView.styleURL = MGLStyle.outdoorsStyleURL
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !loadBuggyVersion,
           let styleURL = self.getTopoStyleURL() {
            mapView.styleURL = styleURL
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // add images to style
        self.addImagesTo(style)
        // add geo features
        self.addMapGeoFeatures()
    }
    
    func addImagesTo(_ style: MGLStyle) {
        // get all files in the images folder
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/images"
        guard let items = try? fm.contentsOfDirectory(atPath: path) else {
            print("Could not read folder 'images'")
            return
        }
    
        // add all images to the style with file name as name
        for item in items {
            if let image = UIImage(contentsOfFile: "\(path)/\(item)") {
                let name = (item as NSString).deletingPathExtension
                style.setImage(image,
                               forName: name)
            }
        }
    }
        
    func addMapGeoFeatures() {
        guard let style = mapView.style,
              let shape = self.getFeaturesFromFile() else {
            return
        }
        
        // create a shape source and add it to the map style
        let shapeSource = MGLShapeSource(identifier: "source", shape: shape, options: nil)
        style.addSource(shapeSource)
        
        // add style layers for the different types of features
        let fillLayer = MGLFillStyleLayer(identifier: "fillLayer", source: shapeSource)
        fillLayer.predicate = NSPredicate(format: "%@ = 'Polygon'", NSExpression.geometryTypeVariable)
        fillLayer.fillColor = NSExpression(forKeyPath: "style.fillColor")
        fillLayer.fillOpacity = NSExpression(forKeyPath: "style.fillOpacity")
        style.addLayer(fillLayer)
        
        let lineLayer = MGLLineStyleLayer(identifier: "linesLayer",
                                          source: shapeSource)
        lineLayer.lineColor = NSExpression(forKeyPath: "style.color")
        lineLayer.lineJoin = NSExpression(forKeyPath: "style.lineJoin")
        lineLayer.lineOpacity = NSExpression(forKeyPath: "style.opacity")
        lineLayer.lineWidth = NSExpression(forKeyPath: "style.weight")
        style.addLayer(lineLayer)
        
        // used for symbols with icons
        let symbolLayer = MGLSymbolStyleLayer(identifier: "symbolsLayer", source: shapeSource)
        symbolLayer.predicate = NSPredicate(format: "symbol != nil")
        symbolLayer.iconImageName = NSExpression(forKeyPath: "symbol")
        symbolLayer.iconScale = NSExpression(forConstantValue: 0.4)
        symbolLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.red)
        symbolLayer.iconHaloWidth = NSExpression(forConstantValue: 20.0)
        symbolLayer.iconOffset = NSExpression(forConstantValue: [0.0, -1.3])
        symbolLayer.symbolAvoidsEdges = NSExpression(forConstantValue: false)
        symbolLayer.symbolPlacement = NSExpression(forConstantValue: "point")
        symbolLayer.symbolSpacing = NSExpression(forConstantValue: 0.0)
        symbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        symbolLayer.textColor = NSExpression(forConstantValue: UIColor.black)
        symbolLayer.textHaloColor = NSExpression(forConstantValue: UIColor.white)
        symbolLayer.textHaloWidth = NSExpression(forConstantValue: 0.75)
        symbolLayer.textHaloBlur = NSExpression(forConstantValue: 0.5)
        symbolLayer.textOptional = NSExpression(forConstantValue: true)
        symbolLayer.textOffset = NSExpression(forConstantValue: [0.0, 1.5])
        symbolLayer.text = NSExpression(forKeyPath: "label.text")
        style.addLayer(symbolLayer)
        
        // used for symbols without icons
        let labelsLayer = MGLSymbolStyleLayer(identifier: "labelsLayer", source: shapeSource)
        labelsLayer.predicate = NSPredicate(format: "symbol == nil")
        labelsLayer.textColor = NSExpression(forConstantValue: UIColor.black)
        labelsLayer.textHaloColor = NSExpression(forConstantValue: UIColor.white)
        labelsLayer.textHaloWidth = NSExpression(forConstantValue: 0.75)
        labelsLayer.textHaloBlur = NSExpression(forConstantValue: 0.5)
        labelsLayer.textAllowsOverlap = NSExpression(forConstantValue: true)
        labelsLayer.textOffset = NSExpression(forConstantValue: [0.0, 0])
        labelsLayer.text = NSExpression(forKeyPath: "label.text")
        style.addLayer(labelsLayer)
        
        // draws a red circle around features with "selected": true
        let selectedLayer = MGLCircleStyleLayer(identifier: "selectedLayer",
                                                source: shapeSource)
        selectedLayer.predicate = NSPredicate(format: "selected != nil")
        selectedLayer.circleRadius = NSExpression(forConstantValue: 20.0)
        selectedLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.red)
        selectedLayer.circleOpacity = NSExpression(forConstantValue: 0.0)
        selectedLayer.circleStrokeWidth = NSExpression(forConstantValue: 2.0)
        style.addLayer(selectedLayer)
    }
    
    // creates a MGLShape from the features.json
    func getFeaturesFromFile() -> MGLShape? {
        if let path = Bundle.main.path(forResource: "features", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let shape = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
                return shape
            } catch let err {
                print(err)
            }
        }
        return nil
    }
    
    // return a URL to the topo.json map style
    func getTopoStyleURL() -> URL? {
        if let path = Bundle.main.path(forResource: "topo", ofType: "json") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    // toggles between the default outdoors and topo styles
    @objc func changeStyle() {
        if mapView.styleURL == MGLStyle.outdoorsStyleURL,
           let styleURL = self.getTopoStyleURL() {
            mapView.styleURL = styleURL
        } else {
            mapView.styleURL = MGLStyle.outdoorsStyleURL
        }
    }
}
