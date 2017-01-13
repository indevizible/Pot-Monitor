//
//  ChartController.swift
//  Pot Monitor
//
//  Created by Nattawut Singhchai on 1/12/17.
//  Copyright © 2017 Nattawut Singhchai. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import SwiftChart

class ChartController: UIViewController {
    
    var ref: FIRDatabaseReference!
    var monit: Int?

    @IBOutlet weak var chartBack: UIView!

    var chart: Chart!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        ref = FIRDatabase.database().reference(withPath: "logs")
        
        let v = Int((Date.timeIntervalBetween1970AndReferenceDate * 1000) - (24 * 60 * 60 * 1000))
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "H:mm"
        
        
        ref.queryOrdered(byChild: "date").queryStarting(atValue: v, childKey: "date").observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                

                if self.chart != nil {
                    self.chart.removeFromSuperview()
                }

                self.chart = Chart(frame: CGRect(origin: CGPoint.zero, size: self.chartBack.frame.size))
  
                
                let json = JSON(snapshot.value!)
                let all = json.map { $1 }
                let srt = all.sorted { $0["date"].floatValue < $1["date"].floatValue }
                let firstIndex = srt.first?["date"].floatValue ?? 0
                let lastIndex = srt.last?["date"].floatValue ?? 0
                let data = srt.map { (x: ($0["date"].floatValue - firstIndex)/1000, y: $0["temp"].floatValue)}
                
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
                
                series.color = ChartColors.greyColor().withAlphaComponent(0.4)
                
                
                self.chart.gridColor = UIColor.lightGray.withAlphaComponent(0.3)
                self.chart.add(series)
                self.chart.axesColor = .clear
                self.chart.labelFont = UIFont(name: "SFUIDisplay-Light", size: 9)
                self.chart.labelColor = ChartColors.greyColor().withAlphaComponent(0.4)
                self.chartBack.addSubview(self.chart)
                
            }else{
                print("Cannot found.")
            }
        })
    }
    
    deinit {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
