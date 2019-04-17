//
//  FavouriteViewController.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/11.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class FavouriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //讀取條
    @IBOutlet weak var viewBackGround: UIView!
    @IBOutlet weak var indicatorViewBackGround: UIView!
    @IBOutlet weak var myIndicatorLabel: UILabel!
    @IBOutlet weak var myIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var favouriteTableView: UITableView!
    
    var games = [GameListInfo]()
    var gameFavourite = [GameListInfo]()
    var gameFavouriteOld = [GameListInfo]()
    //預載資料
    var countryPrice = [String: [String: [String: Any]]]() //每款遊戲的各國價錢清單
    var gameImageArray = [String: Data]() //每款遊戲的圖片清單
    var exchangeRateList = [String:Any]() //即時匯率清單
    var appDefaultCurrency = "TWD" //預設貨幣
    var gameCodeOffer = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //通知事件-撈玩遊戲價錢及圖片執行cell reloadData
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList(notification:)), name: NSNotification.Name("FavouriteView") , object: nil)
        //通知事件-重新撈遊戲價錢
        NotificationCenter.default.addObserver(self, selector: #selector(preLoad(notification:)), name: NSNotification.Name("ChangeCurrencyPreLoad") , object: nil)

        // Do any additional setup after loading the view.
    }
    //讀取條開關
    func myIndicatorAction(isOpen: Bool){
        DispatchQueue.main.async {
            self.viewBackGround.isHidden = !isOpen
            self.indicatorViewBackGround.isHidden = !isOpen
            self.myIndicatorLabel.isHidden = !isOpen
            self.myIndicator.isHidden = !isOpen
            if isOpen{
                self.myIndicator.startAnimating()
            }else{
                self.myIndicator.stopAnimating()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print(gameFavourite)
        //取得即時匯率
        if gameFavourite != gameFavouriteOld{
            NotificationCenter.default.post(name: Notification.Name("ChangeCurrencyPreLoad"), object: nil)
        }else{
            //讀取條關閉
            self.myIndicatorAction(isOpen: false)
        }
        self.favouriteTableView.tableFooterView = UIView()
        
    }
    //通知事件-重新撈遊戲價錢
    @objc func preLoad(notification: NSNotification) {
        //讀取條啟動
        myIndicatorAction(isOpen: true)
        gameFavouriteOld = gameFavourite
        HomeViewController.shared.countryPrice = [String: [String: [String: Any]]]()
        HomeViewController.shared.gameImageArray = [String: Data]()
        DBManager.shared.exchangeRateList(completion: {(result,rateList) in
            if result{
                self.exchangeRateList = rateList
                HomeViewController.shared.preLoad(index: 0, count: 10, preLoadGames: self.gameFavourite, viewName: "FavouriteView", exchangeRate: self.exchangeRateList)
                
            }else{
                print("ExchangeRate load fail.")
            }
        })
    }
    //通知事件-撈玩遊戲價錢及圖片執行cell reloadData
    @objc func reloadList(notification: NSNotification) {
        countryPrice = HomeViewController.shared.countryPrice
        gameImageArray = HomeViewController.shared.gameImageArray
        DispatchQueue.main.async {
            self.favouriteTableView.reloadData()
        }
        //讀取條關閉
        self.myIndicatorAction(isOpen: false)
        print("Reloading finish.")
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameFavourite.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! FavouriteTableViewCell
        if gameFavourite.count != 0{
            let gameCode = HomeViewController.shared.getGameCode(game: gameFavourite[indexPath.row])
            
            cell.eshopPriceLabel.text = " "
            cell.discountLabel.text = " "
            cell.saleDateLabel.text = " "
            cell.countryLabel.text = " "
            //遊戲名稱
            cell.gameTitleLabel.text = HomeViewController.shared.getGameTitle(game: gameFavourite[indexPath.row])
            //遊戲圖片
            if gameImageArray.count > 0 && gameImageArray[gameCode] != nil{
                cell.gameImage.image = UIImage(data: gameImageArray[gameCode]!)
            }
            //遊戲收藏
            if gameFavourite[indexPath.row].favourite{
                cell.favouriteButton.setImage(UIImage(named: "loved.png"), for: .normal)
            }else{
                cell.favouriteButton.setImage(UIImage(named: "love.png"), for: .normal)
            }
            cell.favouriteButton.tag = indexPath.row
            cell.favouriteButton.addTarget(self, action: #selector(HomeViewController.favouriteButton(_:)) , for: UIControl.Event.touchUpInside)
            //遊戲銷售日期
            let releaseDate = HomeViewController.shared.getGameReleaseDate(game: gameFavourite[indexPath.row])
            cell.releaseDateLabel.text = releaseDate
            //遊戲價錢
            if (countryPrice[gameCode] != nil) && countryPrice.count > 0{
                //print(countryPrice)
                let countryPriceList = countryPrice[gameCode]
                let minPriceCountry = HomeViewController.shared.dictionaryMin(prices: countryPrice[gameCode]!)
                if let priceList = countryPriceList![minPriceCountry]{
                    let appDefaultCurrency = HomeViewController.shared.userDefaults.value(forKey: "appDefaultCurrency") as! String
                    //遊戲價格最便宜的國家
                    if let countryData = HomeViewController.shared.countries[minPriceCountry]{
                        cell.countryLabel.text = HomeViewController.shared.countryOutput(country: countryData)
                    }
                    //遊戲無優惠的價格
                    let eshopAmount = priceList["eshop_default_price"] as? Decimal
                    if eshopAmount != nil {
                        cell.eshopPriceLabel.textColor = UIColor.blue
                        cell.eshopPriceLabel.text = "\(appDefaultCurrency) \(String(describing: eshopAmount!))"
                        if eshopAmount == 0{
                            cell.eshopPriceLabel.text = "FREE"
                        }
                    }
                    //遊戲優惠時的價格
                    let saleAmount = priceList["sale_default_price"] as? Decimal
                    if saleAmount != nil && eshopAmount != nil{
                        //刪除線
                        let attributeString = HomeViewController.shared.attributeStrOutput(eshopAmount: eshopAmount!, saleAmount: saleAmount!)
                        cell.eshopPriceLabel.textColor = UIColor.red
                        cell.eshopPriceLabel.attributedText = attributeString
                        
                    }
                    let eshopPrice = priceList["eshopPrice"] as? Double
                    let salePrice = priceList["salePrice"] as? Double
                    if eshopPrice != nil && salePrice != nil{
                        let discountStr = HomeViewController.shared.discountOutput(eshopPrice: eshopPrice!, salePrice: salePrice!)
                        cell.discountLabel.text = discountStr
                        
                    }
                    //優惠起迄日期
                    if let saleDate = priceList["end_datetime"] as? String{
                        let date = HomeViewController.shared.dateOutput(date: saleDate)
                        cell.saleDateLabel.text = date
                    }
                }else{
                    cell.countryLabel.text = "未販售"
                }
            }
            
            
            
        }
        
        return cell
    }
    //傳值到下一個頁面
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gameDetail"{
            let homeGameDetailViewController = segue.destination as? HomeGameDetailViewController
            if let row = self.favouriteTableView?.indexPathForSelectedRow?.row{
                homeGameDetailViewController?.game = gameFavourite[row]
                homeGameDetailViewController?.countryPrice = countryPrice[HomeViewController.shared.getGameCode(game: gameFavourite[row])]!
                homeGameDetailViewController?.image = gameImageArray[HomeViewController.shared.getGameCode(game: gameFavourite[row])]!
            }
        }
        
    }
    @IBAction func favouriteButton(_ sender: UIButton) {
        if gameFavourite[sender.tag].favourite{
            gameFavourite[sender.tag].favourite = false
        }else{
            gameFavourite[sender.tag].favourite = true
        }
        DBManager.shared.updateGameFavourite(gameCode: HomeViewController.shared.getGameCode(game: gameFavourite[sender.tag]), favourite: gameFavourite[sender.tag].favourite)
        if !gameFavourite[sender.tag].favourite{
            gameFavourite.remove(at: sender.tag)
        }
        NotificationCenter.default.post(name: Notification.Name("RELOAD"), object: nil)
        gameFavouriteOld = gameFavourite
        self.favouriteTableView.reloadData()
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
