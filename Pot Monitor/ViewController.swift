//
//  ViewController.swift
//  Pot Monitor
//
//  Created by Nattawut Singhchai on 1/12/17.
//  Copyright © 2017 Nattawut Singhchai. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON
import SwiftChart

class ViewController: UIViewController {
    
    enum ChartMode: Int {
        case temperature    = 0
        case humidity       = 1
        case soilHumidity  = 2
        case luminance      = 3
    }

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidLabel: UILabel!
    @IBOutlet weak var sHumidLabel: UILabel!
    @IBOutlet weak var luminanceLabel: UILabel!
    @IBOutlet weak var updateLabel: UILabel!
    
    @IBOutlet weak var humidIconImageView: UIImageView!
    @IBOutlet weak var soilHumidityImageView: UIImageView!
    @IBOutlet weak var lightImageView: UIImageView!
    
    @IBOutlet weak var chartBack: UIView!
    var chart: Chart!
    
    var mode = ChartMode.temperature
    
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        humidIconImageView.image = UIImage(named: "Humidity-96")?.withRenderingMode(.alwaysTemplate)
        
        soilHumidityImageView.image = UIImage(named: "Watering Can-100")?.withRenderingMode(.alwaysTemplate)
        
        lightImageView.image = UIImage(named: "Sun-96")?.withRenderingMode(.alwaysTemplate)
        
        ref = FIRDatabase.database().reference(withPath: "logs")
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = false
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd hh:mm a"
        
        ref = FIRDatabase.database().reference(withPath: "logs")
        
        let v = Int((Date.timeIntervalBetween1970AndReferenceDate * 1000) - (24 * 60 * 60 * 1000))
    
        
        ref.queryOrdered(byChild: "date").queryStarting(atValue: v, childKey: "date").observe(.value, with: { (snapshot) in
            
            if snapshot.exists() {
                
                if self.chart != nil {
                    self.chart.removeFromSuperview()
                }
                
                self.chart = Chart(frame: CGRect(origin: CGPoint.zero, size: self.chartBack.frame.size))
                
                
                let json = JSON(snapshot.value!)
                let all = json.map { $1 }
                let srt = all.sorted { $0["date"].floatValue < $1["date"].floatValue }
                
                self.currentData = srt
                
                // Display current
                let j = srt.last!
                self.tempLabel.text = String(format:"%.1fº", j["temp"].floatValue)
                self.humidLabel.text = String(format:"%.0f%%", j["humid"].floatValue)
                self.sHumidLabel.text = String(format:"%.0f%%", j["s_humid"].floatValue)
                self.luminanceLabel.text = numberFormatter.string(for: j["lux"].intValue)
                let date = Date(timeIntervalSince1970: j["date"].doubleValue / 1000)
                self.updateLabel.text = "update " + dateFormatter.string(from: date)
                
                self.updateChart()
            }else{
                print("Cannot found.")
            }
            
        })
    }
    
    var currentData: [JSON]?
    
    func updateChart() {
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "H:mm"
        
        if self.chart != nil {
            self.chart.removeFromSuperview()
        }
        
        self.chart = Chart(frame: CGRect(origin: CGPoint.zero, size: self.chartBack.frame.size))
        
        let srt = currentData ?? [JSON({})]
        
        let firstIndex = srt.first?["date"].floatValue ?? 0
        let lastIndex = srt.last?["date"].floatValue ?? 0
        let key = ["temp", "humid", "s_humid", "lux"][mode.rawValue]
        let data = srt.map { (x: ($0["date"].floatValue - firstIndex)/1000, y: $0[key].floatValue)}
        
        
        var xLabel = [Float]()
        
        let intervalPerDay: Float = 60 * 60 * 24
        
        for i in 0...3 {
            xLabel.append((Float(i) * 60 * 60 * 6) - (intervalPerDay - ((lastIndex-firstIndex)/1000)))
        }
        
        self.chart.xLabels = xLabel
        self.chart.xLabelsFormatter = { ii,vv in
            return timeFormatter.string(from: Date(timeIntervalSince1970: Double(firstIndex/1000 + vv)))
        }
        
        let series = ChartSeries(data: data)
        
        series.color = UIColor(red:0.33, green:0.79, blue:0.83, alpha:1.00)
        
        self.chart.gridColor = UIColor.lightGray.withAlphaComponent(0.3)
        self.chart.add(series)
        self.chart.axesColor = .clear
        self.chart.labelFont = UIFont(name: "SFUIDisplay-Light", size: 9)
        self.chart.labelColor = ChartColors.greyColor().withAlphaComponent(0.4)
        self.chartBack.addSubview(self.chart)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func changeMode(_ sender: UIButton) {
        let m: ChartMode = ChartMode(rawValue: sender.tag) ?? .temperature
        let tintColor = UIColor(red:0.33, green:0.79, blue:0.83, alpha:1.00)
        let grayColor = UIColor(white: 0.8, alpha: 1)
        
        tempLabel.textColor = m == .temperature ? tintColor : grayColor
        humidLabel.textColor = m == .humidity ? tintColor : grayColor
        sHumidLabel.textColor = m == .soilHumidity ? tintColor : grayColor
        luminanceLabel.textColor = m == .luminance ? tintColor : grayColor
        
        humidIconImageView.tintColor = m == .humidity ? tintColor : grayColor
        soilHumidityImageView.tintColor = m == .soilHumidity ? tintColor : grayColor
        lightImageView.tintColor = m == .luminance ? tintColor : grayColor
        
        if mode != m {
            mode = m
            updateChart()
        }
    }

}

