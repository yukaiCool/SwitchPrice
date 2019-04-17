//
//  HomeGameDetailViewController.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/2.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

struct Price {
    var country = String()
    var countryEnName = String()
    var eshopPrice = Decimal()
    var salePrice = Decimal()
}

class HomeGameDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var detailTableView: UITableView!
    
    var game = GameListInfo()
    var prices = [Price]()
    var countryPrice = [String:[String:Any]]()
    
    var image = Data()
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return countryPrice.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! HomeGameDetailTableViewCell
            //遊戲名稱
            let title = HomeViewController.shared.getGameTitle(game: game)
            if title != ""{
                cell.gameTitle.text = title
            }
            //遊戲圖片
            cell.gameImage.image = UIImage(data: image)
            //cell.gameCategory.text = "Category: " + game.category
            //遊戲支援語言
            cell.gameLanguage.text = ""
            if game.language != nil{
                cell.gameLanguage.text = "Language : " + game.language
            }else{
                cell.gameLanguage.text = " "
            }
            //遊戲銷售日期
            cell.gameReleaseDate.text = "No releaseDate"
            let releaseDate = HomeViewController.shared.getGameReleaseDate(game: game)
            if releaseDate != ""{
                cell.gameReleaseDate.text = "ReleaseDate : " + releaseDate
            }
            //遊戲遊玩人數
            if game.players != nil && game.players != ""{
                cell.gamePeople.text = "Play : " + game.players
            }else{
                cell.gamePeople.text = " "
            }
            
            //遊戲簡介
            if game.excerpt != nil && game.excerpt != ""{
                cell.gameExcerpt.text = "Introduction : " + game.excerpt
            }else{
                cell.gameExcerpt.text = " "
            }
            //遊戲優惠日期
            cell.saleDate.text = "No offer"
            let country = HomeViewController.shared.dictionaryMin(prices: countryPrice)
            if let countryData = countryPrice[country]{
                if let startDate = countryData["start_datetime"] as? String{
                    cell.saleDate.textColor = UIColor.red
                    let start = HomeViewController.shared.dateOutput(date: startDate)
                    cell.saleDate.text = "sale_Date : " + start
                    
                    if let endDate = countryData["end_datetime"] as? String{
                        let end = HomeViewController.shared.dateOutput(date: endDate)
                        cell.saleDate.text = "sale_Date : " + start + "~" + end
                    }
                    
                }
            }
            
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PriceCell", for: indexPath) as! HomeGamePriceTableViewCell
            //國家名稱
            cell.country.text = prices[indexPath.row].country
            //國家旗子圖片
            let imageStr = prices[indexPath.row].countryEnName.lowercased() + ".png"
            cell.countryImage.image = UIImage(named: imageStr)
            //無優惠價格
            let eshopPrice = prices[indexPath.row].eshopPrice
            let appDefaultCurrency = HomeViewController.shared.userDefaults.value(forKey: "appDefaultCurrency") as! String
            cell.price.text = "\(appDefaultCurrency) \(eshopPrice)"
            cell.price.textColor = UIColor.blue
            cell.discount.text = " "
            //有優惠價格
            if prices[indexPath.row].salePrice != 0{
                let salePrice = prices[indexPath.row].salePrice
                //刪除線
                let attributeStr = HomeViewController.shared.attributeStrOutput(eshopAmount: eshopPrice, saleAmount: prices[indexPath.row].salePrice)
                cell.price.textColor = UIColor.red
                cell.price.attributedText = attributeStr
                //優惠％數
                let discountStr = HomeViewController.shared.discountOutput(eshopPrice: eshopPrice.doubleValue, salePrice: salePrice.doubleValue)
                cell.discount.text = discountStr
                    
                }
            
            
            return cell
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for price in countryPrice{
            var priceData = Price(country: HomeViewController.shared.countries[price.key]!["cnName"]!,countryEnName: HomeViewController.shared.countries[price.key]!["enName"]!, eshopPrice: 0.0, salePrice: 0.0)
            var eshopPrice = price.value["eshop_default_price"] as? Decimal
            if eshopPrice == nil{
                eshopPrice = Decimal()
            }
            priceData.eshopPrice = eshopPrice!
            var salePrice = price.value["sale_default_price"] as? Decimal
            if salePrice == nil{
                salePrice = Decimal()
            }
            priceData.salePrice = salePrice!
            prices.append(priceData)
        }
        prices.sort { (Price1:Price, Price2:Price) -> Bool in
            if Price1.salePrice != 0 && Price2.salePrice != 0{
                return Price1.salePrice < Price2.salePrice
            }else if Price1.salePrice == 0 && Price2.salePrice != 0{
                return Price1.eshopPrice < Price2.salePrice
            }else if Price1.salePrice != 0 && Price2.salePrice == 0{
                return Price1.salePrice < Price2.eshopPrice
            }else{
                return Price1.eshopPrice < Price2.eshopPrice
            }
        }
        self.detailTableView.tableFooterView = UIView()
        //print(prices)
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
