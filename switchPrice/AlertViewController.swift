//
//  AlertViewController.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/16.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class AlertViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    var countries = [["country":"TW","cnName":"台灣","enName":"Taiwan", "countryDollar":"TWD"],
                     ["country":"JP","cnName":"日本","enName":"Japan", "countryDollar":"JPY"],
                   ["country":"NZ","cnName":"紐西蘭", "enName":"New Zealand", "countryDollar":"NZD"],
                   ["country":"DK","cnName":"丹麥", "enName":"Denmark", "countryDollar":"DKK"],
                   ["country":"GB","cnName":"英國", "enName":"United Kingdom", "countryDollar":"GBP"],
                   ["country":"GR","cnName":"希臘", "enName":"Greece", "countryDollar":"EUR"],
                   ["country":"NO","cnName":"挪威", "enName":"Norway", "countryDollar":"NOK"],
                   ["country":"PL","cnName":"波蘭", "enName":"Poland", "countryDollar":"PLN"],
                   ["country":"ES","cnName":"西班牙", "enName":"Spain", "countryDollar":"EUR"],
                   ["country":"CH","cnName":"瑞士", "enName":"Switzerland", "countryDollar":"CHF"],
                   ["country":"SE","cnName":"瑞典", "enName":"Sweden", "countryDollar":"SEK"],
                   ["country":"CA","cnName":"加拿大", "enName":"Canada", "countryDollar":"CAD"],
                   ["country":"US","cnName":"美國", "enName":"United States", "countryDollar":"USD"],
                   ["country":"ZA","cnName":"南非", "enName":"South Africa", "countryDollar":"ZAR"],
                   ["country":"MX","cnName":"墨西哥", "enName":"Mexico", "countryDollar":"MXN"],
                   ["country":"AU","cnName":"澳大利亞", "enName":"Australia", "countryDollar":"AUD"],
                   ["country":"RU","cnName":"俄羅斯", "enName":"Russian Federation", "countryDollar":"RUB"],
                   ["country":"CZ","cnName":"捷克", "enName":"Czech", "countryDollar":"CZK"]]
    
    @IBOutlet weak var alertTableView: UITableView!
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! AlertTableViewCell
        let currency = countries[indexPath.row]["countryDollar"]
        let appDefaultCurrency = HomeViewController.shared.userDefaults.value(forKey: "appDefaultCurrency") as! String
        
        if currency == appDefaultCurrency{
            
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        let countryStr = (countries[indexPath.row]["enName"]?.lowercased())!+".png"
        cell.currencyImage.image = UIImage(named: countryStr)
        cell.currencyLabel.text = countries[indexPath.row]["countryDollar"]!
        return cell
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(HomeViewController.shared.appDefaultCurrency)
        HomeViewController.shared.userDefaults.setValue(countries[indexPath.row]["countryDollar"], forKey: "appDefaultCurrency")
        HomeViewController.shared.appDefaultCurrency = countries[indexPath.row]["countryDollar"]!
        print(HomeViewController.shared.appDefaultCurrency)
        NotificationCenter.default.post(name: Notification.Name("ReloadPrices"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("ChangeCurrencyPreLoad"), object: nil)
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: Notification.Name("ChangeCurrencyAlert"), object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var size: CGSize?
        if countries.count < 4{
            size = CGSize(width: 272, height: 100)
        }else if countries.count < 6{
            size = CGSize(width: 272, height: 150)
        }else if countries.count < 8{
            size = CGSize(width: 272, height: 200)
        }else{
            size = CGSize(width: 272, height: 250)
        }
        self.preferredContentSize = size!
        self.alertTableView.register(UINib(nibName: "AlertTableViewCell", bundle: nil), forCellReuseIdentifier: "CELL")
        alertTableView.delegate = self
        alertTableView.dataSource = self
        // Do any additional setup after loading the view.
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
