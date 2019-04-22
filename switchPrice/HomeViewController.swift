//
//  ViewController.swift
//  switchPrice
//
//  Created by YuKai on 2019/3/21.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

struct GameListInfo : Equatable{
    var us_gameCode: String!
    var us_gameID: String!
    var us_gameTitle: String!
    var us_gameReleaseDate: String!
    var us_gameImage: String!
    var us_url: String!
    var eu_gameCode: String!
    var eu_gameID: String!
    var eu_gameTitle: String!
    var eu_gameReleaseDate: String!
    var eu_gameImage: String!
    var eu_url:String!
    var jp_gameCode: String!
    var jp_gameID: String!
    var jp_gameTitle: String!
    var jp_gameReleaseDate: String!
    var jp_gameImage: String!
    var jp_url: String!
    var language: String!
    var category: String!
    var players: String!
    var excerpt: String!
    var favourite: Bool!
}
struct CountryInfo {
    var countryID: String!
    var countryCnName: String!
    var countryEnName: String!
    var countryDollar: String!
}
extension Decimal{
    var doubleValue: Double{
        return NSDecimalNumber(decimal: self).doubleValue
    }
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    static let shared: HomeViewController = HomeViewController()
    var games: [GameListInfo]!
    var gamesSel: [GameListInfo]!
    var countries = ["JP":["cnName":"日本","enName":"Japan", "countryDollar":"JPY"],
                      "NZ":["cnName":"紐西蘭", "enName":"New Zealand", "countryDollar":"NZD"],
                      "DK":["cnName":"丹麥", "enName":"Denmark", "countryDollar":"DKK"],
                      "GB":["cnName":"英國", "enName":"United Kingdom", "countryDollar":"GBP"],
                      "GR":["cnName":"希臘", "enName":"Greece", "countryDollar":"EUR"],
                      "NO":["cnName":"挪威", "enName":"Norway", "countryDollar":"NOK"],
                      "PL":["cnName":"波蘭", "enName":"Poland", "countryDollar":"PLN"],
                      "ES":["cnName":"西班牙", "enName":"Spain", "countryDollar":"EUR"],
                      "CH":["cnName":"瑞士", "enName":"Switzerland", "countryDollar":"CHF"],
                      "SE":["cnName":"瑞典", "enName":"Sweden", "countryDollar":"SEK"],
                      "CA":["cnName":"加拿大", "enName":"Canada", "countryDollar":"CAD"],
                      "US":["cnName":"美國", "enName":"United States", "countryDollar":"USD"],
                      "ZA":["cnName":"南非", "enName":"South Africa", "countryDollar":"ZAR"],
                      "MX":["cnName":"墨西哥", "enName":"Mexico", "countryDollar":"MXN"],
                      "AU":["cnName":"澳大利亞", "enName":"Australia", "countryDollar":"AUD"],
                      "RU":["cnName":"俄羅斯", "enName":"Russian Federation", "countryDollar":"RUB"],
                      "CZ":["cnName":"捷克", "enName":"Czech", "countryDollar":"CZK"]]

    //預載資料
    var countryPrice = [String: [String: [String: Any]]]() //每款遊戲的各國價錢清單
    var gameImageArray = [String: Data]() //每款遊戲的圖片清單
    var exchangeRateList = [String:Any]() //即時匯率清單
    let userDefaults = UserDefaults.standard
    var appDefaultCurrency = "" //預設貨幣
    var gameCodeOffer = [String]()
    var gameFavourite = [GameListInfo]() //遊戲收藏清單
    
    @IBOutlet weak var HomeTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    //讀取條
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var myIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewBackGround: UIView!
    @IBOutlet weak var indicatorViewBackGround: UIView!
    override func viewWillAppear(_ animated: Bool) {
        //預設貨幣
        if (userDefaults.value(forKey: "appDefaultCurrency")) == nil{
            appDefaultCurrency = "TWD"
            userDefaults.setValue(appDefaultCurrency, forKey: "appDefaultCurrency")
        }else{
            if appDefaultCurrency != (userDefaults.value(forKey: "appDefaultCurrency") as? String)!{
                appDefaultCurrency = (userDefaults.value(forKey: "appDefaultCurrency") as? String)!
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //讀取條開始
        myIndicatorAction(isOpen: true)
        
        //建立通知清單
        NotificationCenter.default.addObserver(self, selector: #selector(loadGameList(notification:)), name: NSNotification.Name("GET_DATA") , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList(notification:)), name: NSNotification.Name("HomeView") , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadGames(notification:)), name: NSNotification.Name("RELOAD") , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDatabase(notification:)), name: NSNotification.Name("ReloadDatabase") , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPrices(notification:)), name: NSNotification.Name("ReloadPrices") , object: nil)
        if DBManager.shared.isGameDatabase(){
            games = DBManager.shared.loadGameList()
            if games == nil{
                DBManager.shared.createGameList()
                games = DBManager.shared.loadGameList()
            }
            gamesSel = games
        } 
        if games != nil{
            //取得遊戲收藏清單 to FavouriteTableViewController
            favouriteButtonUpdate()
            //取得即時匯率
            DBManager.shared.exchangeRateList(completion: {(result,rateList) in
                if result{
                    self.exchangeRateList = rateList
                    DispatchQueue.main.async {
                        self.preLoad(index: 0, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
                    }
                }else{
                    print("ExchangeRate load fail.")
                }
            })
        }
        self.HomeTableView.tableFooterView = UIView()
        
    }
    //通知事件-重新讀取資料庫若有新資料則更新表格
    @objc func reloadDatabase(notification: NSNotification) {
        if DBManager.shared.isGameUSCheck && DBManager.shared.isGameEUCheck && DBManager.shared.isGameJPCheck{
            if DBManager.shared.isUpdate{
                //啟用通知事件-重新讀取遊戲清單
                NotificationCenter.default.post(name: Notification.Name("UpdateLabel"), object: nil)
                DBManager.shared.deleteGameList()
                print("Delete table.")
                DBManager.shared.createGameList()
                print("Create table.")
                games = DBManager.shared.loadGameList()
                gamesSel = games
                self.preLoad(index: 0, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
                print("Update finish.")
            }
            NotificationCenter.default.post(name: Notification.Name("UpdateFavourite"), object: nil)
        }
    }
    //通知事件-重新讀取遊戲清單
    @objc func loadGames(notification: NSNotification) {
        if DBManager.shared.isGameUSDatabase() && DBManager.shared.isGameEUDatabase() && DBManager.shared.isGameJPDatabase(){
            games = DBManager.shared.loadGameList()
            gamesSel = games
            DispatchQueue.main.async {
                self.HomeTableView.reloadData()
            }
            print("Loading finish.")
        }
    }
    //通知事件-首次安裝app執行，彙整資料庫
    @objc func loadGameList(notification: NSNotification) {
        if DBManager.shared.isFinishUS && DBManager.shared.isFinishEU && DBManager.shared.isFinishJP{
            if DBManager.shared.isGameUSDatabase() && DBManager.shared.isGameJPDatabase() && DBManager.shared.isGameEUDatabase() && !DBManager.shared.isGameDatabase(){
                DBManager.shared.spatoonUpdateData()
                DBManager.shared.createGameList()
                games = DBManager.shared.loadGameList()
                gamesSel = games
                //取得即時匯率
                DBManager.shared.exchangeRateList(completion: {(result,rateList) in
                    if result{
                        self.exchangeRateList = rateList
                        self.preLoad(index: 0, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
                    }else{
                        print("ExchangeRate load fail.")
                    }
                })
                print("Loading finish.")
            }else if DBManager.shared.isGameUSDatabase() && DBManager.shared.isGameJPDatabase() && DBManager.shared.isGameEUDatabase() && DBManager.shared.isGameDatabase(){
                //讀取條stop
                //myIndicatorAction(isOpen: false)
                print("Database is finish.")
            }else{
                //讀取條stop
                myIndicatorAction(isOpen: false)
                let alert = UIAlertController(title: "Fail", message: "Data download failed,Please go to Setting->UpdateGameData", preferredStyle: .alert)
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(actionOK)
                present(alert, animated: true, completion: nil)
            }
            
        }
    }
    //通知事件-重新讀取遊戲清單並且條停止讀取條
    @objc func reloadList(notification: NSNotification) {
        DispatchQueue.main.async {
            self.HomeTableView.reloadData()
            //讀取條停止
            self.myIndicatorAction(isOpen: false)
        }
        print("Reloading finish.")
    }
    //通知事件-貨幣更換重新讀取遊戲價錢
    @objc func reloadPrices(notification: NSNotification) {
        updateCountryPrice()
        DispatchQueue.main.async {
            self.HomeTableView.reloadData()
        }
        print("Reload prices finish.")
    }
    
    //UISearchBar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == ""{
            //讀取條開始
            myIndicatorAction(isOpen: true)
            gamesSel = games
            countryPrice = [String: [String: [String: Any]]]()
            DispatchQueue.main.async {
                self.preLoad(index: 0, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
            }
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if searchBar.text == ""{
            gamesSel = games
        }else{
            //讀取條開始
            myIndicatorAction(isOpen: true)
            gamesSel = []
            for game in games{
                if getGameTitle(game: game).lowercased().hasPrefix(searchBar.text!.lowercased()){
                    gamesSel.append(game)
                }
            }
            if gamesSel.count > 0{
                countryPrice = [String: [String: [String: Any]]]()
                DispatchQueue.main.async {
                    self.preLoad(index: 0, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
                }
            }else{
                DispatchQueue.main.async {
                    //讀取條停止
                    self.myIndicatorAction(isOpen: false)
                    self.HomeTableView.reloadData()
                }
            }
        }
        
        searchBar.resignFirstResponder()
    }
    //Decimal做除法運算
    func calculateProfitRate(tatolProfit: Decimal, tatolBet: Decimal) -> Double{
        let profitRate: Decimal = tatolProfit/tatolBet
        return profitRate.doubleValue
    }
    //Get GameTitle
    func getGameTitle(game: GameListInfo) -> String{
        var gameTitle = String()
        if let title = game.us_gameTitle{
            gameTitle = title
        }else if let title = game.eu_gameTitle{
            gameTitle = title
        }else if let title = game.jp_gameTitle{
            gameTitle = title
        }
        return gameTitle
    }
    //Get GameID
    func getGameID(game: GameListInfo) -> Array<String>{
        var gameID = Array<String>()
        if let id = game.us_gameID{
            gameID.append(id)
        }
        if let id = game.eu_gameID{
            gameID.append(id)
        }
        if let id = game.jp_gameID{
            gameID.append(id)
        }
        return gameID
    }
    //Get GameCode
    func getGameCode(game: GameListInfo) -> String{
        var gameCode = String()
        if let code = game.us_gameCode{
            gameCode = code
        }else if let code = game.eu_gameCode{
            gameCode = code
        }else if let code = game.jp_gameCode{
            gameCode = code
        }
        return gameCode
    }
    //Get GameReleaseDate
    func getGameReleaseDate(game: GameListInfo) -> String{
        var gameReleaseDate = String()
        if let releaseDate = game.us_gameReleaseDate{
            gameReleaseDate = releaseDate
        }else if let releaseDate = game.eu_gameReleaseDate{
            gameReleaseDate = releaseDate
        }else if let releaseDate = game.jp_gameReleaseDate{
            gameReleaseDate = releaseDate
        }
        return gameReleaseDate
    }
    //Get GameImage
    func getGameImage(game: GameListInfo) -> String{
        var gameImage = String()
        if let image = game.us_gameImage{
            gameImage = image
        }else if let image = game.eu_gameImage{
            gameImage = image
        }else if let image = game.jp_gameImage{
            gameImage = image
        }
        return gameImage
    }
    
    
    //傳值到下一個頁面
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gameDetail"{
            let homeGameDetailViewController = segue.destination as? HomeGameDetailViewController
            if let row = self.HomeTableView?.indexPathForSelectedRow?.row{
                homeGameDetailViewController?.game = gamesSel[row]
                homeGameDetailViewController?.countryPrice = countryPrice[getGameCode(game: gamesSel[row])]!
                homeGameDetailViewController?.image = gameImageArray[getGameCode(game: gamesSel[row])]!
            }
        }
        
    }
    //Cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if games == nil{
            return 0
        }else{
            return gamesSel.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! HomeTableViewCell
        if gamesSel != nil{
            
            //預載後面二十筆資料
            
            if (indexPath.row-5)%10 == 0{
                print("index = \(indexPath.row)")
                DispatchQueue.main.async {
                    self.preLoad(index: indexPath.row+5, count: 10, preLoadGames: self.gamesSel, viewName: "HomeView", exchangeRate: self.exchangeRateList)
                }
            }
            //遊戲名稱
            cell.gameTitleLabel.text = getGameTitle(game: gamesSel[indexPath.row])
            cell.eshopPriceLabel.text = " "
            cell.discountLabel.text = " "
            cell.saleDateLabel.text = " "
            cell.countryLabel.text = " "
            //遊戲收藏
            if gamesSel[indexPath.row].favourite{
                cell.favouriteButton.setImage(UIImage(named: "loved.png"), for: .normal)
            }else{
                cell.favouriteButton.setImage(UIImage(named: "love.png"), for: .normal)
            }
            cell.favouriteButton.tag = indexPath.row
            cell.favouriteButton.addTarget(self, action: Selector(("favouriteButton:")) , for: UIControl.Event.touchUpInside)
            //遊戲價錢
//            if let price = countryPrice["AB22A"]{
//                print(price)
//            }
            if let countryPriceList = countryPrice[getGameCode(game: gamesSel[indexPath.row])] {
                let country = dictionaryMin(prices: countryPrice[getGameCode(game: gamesSel[indexPath.row])]!)
                if let priceList = countryPriceList[country]{
                    if let countryData = countries[country]{
                        cell.countryLabel.text = countryOutput(country: countryData)
                    }
                    //無優惠的價錢
                    let eshopAmount = priceList["eshop_default_price"] as? Decimal
                    if eshopAmount != nil {
                        cell.eshopPriceLabel.textColor = UIColor.blue
                        cell.eshopPriceLabel.text = "\(appDefaultCurrency) \(String(describing: eshopAmount!))"
                        if eshopAmount == 0{
                            cell.eshopPriceLabel.text = "FREE"
                        }
                    }
                    //有優惠的價錢
                    let saleAmount = priceList["sale_default_price"] as? Decimal
                    if saleAmount != nil && eshopAmount != nil{
                        //刪除線
                        let attributeString = attributeStrOutput(eshopAmount: eshopAmount!, saleAmount: saleAmount!)
                        cell.eshopPriceLabel.textColor = UIColor.red
                        cell.eshopPriceLabel.attributedText = attributeString
                       
                    }
                    //折扣
                    let eshopPrice = priceList["eshopPrice"] as? Double
                    let salePrice = priceList["salePrice"] as? Double
                    if eshopPrice != nil && salePrice != nil{
                        let discountStr = discountOutput(eshopPrice: eshopPrice!, salePrice: salePrice!)
                        cell.discountLabel.text = discountStr
                        
                    }
                    //優惠起迄日期
                    if let saleDate = priceList["end_datetime"] as? String{
                        let date = dateOutput(date: saleDate)
                        cell.saleDateLabel.textColor = UIColor.red
                        cell.saleDateLabel.text = "EndDate:" + date
                    }
                }else{
                    cell.countryLabel.text = "未販售"
                }
                
            }
            //銷售日期
            let releaseDate = getGameReleaseDate(game: gamesSel[indexPath.row])
            cell.releaseDateLabel.text = releaseDate
            
            //遊戲圖片
            cell.gameImage.image = UIImage(contentsOfFile: "home.png")
            if let data = gameImageArray[getGameCode(game: gamesSel[indexPath.row])]{
                cell.gameImage.image = UIImage(data: data)
            }
            
        }
        
        
        return cell
    }
    //遊戲收藏按鈕
    @IBAction func favouriteButton(_ sender: UIButton) {
        if gamesSel[sender.tag].favourite{
            gamesSel[sender.tag].favourite = false
        }else{
            gamesSel[sender.tag].favourite = true
        }
        DBManager.shared.updateGameFavourite(gameCode: getGameCode(game: gamesSel[sender.tag]), favourite: gamesSel[sender.tag].favourite)
        games = DBManager.shared.loadGameList()
        favouriteButtonUpdate()
        self.HomeTableView.reloadData()
    }
    //遊戲收藏按鈕處理
    func favouriteButtonUpdate(){
        //取得遊戲收藏清單
        gameFavourite = [GameListInfo]()
        for game in games{
            if game.favourite{
                gameFavourite.append(game)
            }
        }
        if gameFavourite.count != 0{
            if let navController = self.tabBarController?.viewControllers?[1] as? UINavigationController{
                if let favouriteController = navController.viewControllers[0] as? FavouriteViewController{
                    favouriteController.gameFavourite = gameFavourite
                    favouriteController.games = gamesSel
                }
            }
            if let navController = self.tabBarController?.viewControllers?[2] as? UINavigationController{
                if let settingController = navController.viewControllers[0] as? SettingViewController{
                    settingController.gameFavourite = gameFavourite
                }
            }
            
        }
    }
    //優惠價格文字輸出處理
    func attributeStrOutput(eshopAmount: Decimal, saleAmount: Decimal) -> NSMutableAttributedString{
        let appDefaultCurrency = userDefaults.value(forKey: "appDefaultCurrency") as! String
        let previousPrice = String(describing: eshopAmount)
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: previousPrice, attributes: [NSAttributedString.Key.font:UIFont(name: "HelveticaNeue-Light", size: 13.0)!])
        attributeString.addAttribute(NSAttributedString.Key.baselineOffset, value: 0, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray, range: NSRange(location:0,length:attributeString.length))
        let currentPrice : NSMutableAttributedString = NSMutableAttributedString(string: "\(appDefaultCurrency) \(String(describing: saleAmount))" )
        currentPrice.append(attributeString)
        
        return currentPrice
    }
    //遊戲最便宜的國家文字輸出
    func countryOutput(country: [String:String]) -> String{
        let enName = country["enName"]
        let cnName = country["cnName"]
        let countryStr = enName!+"("+cnName!+")"
        return countryStr
    }
    //遊戲折扣文字輸出處理
    func discountOutput(eshopPrice: Double, salePrice: Double) -> String{
        var scale = 2
        var value1 = Decimal(floatLiteral: eshopPrice)
        var value2 = Decimal(floatLiteral: salePrice)
        var roundedValue1 = Decimal()
        var roundedValue2 = Decimal()
        NSDecimalRound(&roundedValue1, &value1, scale, NSDecimalNumber.RoundingMode.plain)
        NSDecimalRound(&roundedValue2, &value2, scale, NSDecimalNumber.RoundingMode.plain)
        scale = 0
        let discount = calculateProfitRate(tatolProfit: roundedValue2, tatolBet: roundedValue1)*100
        var value3 = Decimal(floatLiteral: discount)
        var roundedValue3 = Decimal()
        NSDecimalRound(&roundedValue3, &value3, scale, NSDecimalNumber.RoundingMode.plain)
        let discountStr = "-\(100-roundedValue3)%"
        
        return discountStr
    }
    //日期格式輸出處理
    func dateOutput(date: String) -> String{
        let dateFormot = DateFormatter()
        dateFormot.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = dateFormot.date(from: date)
        dateFormot.dateFormat = "yyyy-MM-dd"
        let date = dateFormot.string(from: dateString!)
        return date
    }
    //讀取條開關
    func myIndicatorAction(isOpen: Bool){
        DispatchQueue.main.async {
            self.viewBackGround.isHidden = !isOpen
            self.indicatorViewBackGround.isHidden = !isOpen
            self.downloadLabel.isHidden = !isOpen
            self.myIndicator.isHidden = !isOpen
            if isOpen{
                self.myIndicator.startAnimating()
            }else{
                self.myIndicator.stopAnimating()
            }
        }
    }
    //cell回到第一筆資料
    @IBAction func backTop(_ sender: UIBarButtonItem) {
        callBackTop()
    }
    func callBackTop(){
        let secon = 0
        let row = 0
        let index = IndexPath(row: row, section: secon)
        self.HomeTableView.scrollToRow(at: index, at: .top, animated: true)
    }
    
    //取最大值
    func dictionaryMin(prices: [String: [String: Any]]) -> String{
        var minCountry = ""
        var minPrice:Decimal = 0.0
        if prices.count > 0{
            for dict in prices{
                let nowPrice = dict.value["eshop_default_price"] as! Decimal
                let nowSalePrice = dict.value["sale_default_price"] as? Decimal

                if minCountry == ""{
                    minCountry = dict.key
                    if nowSalePrice != nil{
                        minPrice = nowSalePrice!
                    }else{
                        minPrice = nowPrice
                    }
                }else if nowSalePrice != nil{
                    if minPrice > nowSalePrice!{
                        minCountry = dict.key
                        minPrice = nowSalePrice!
                    }else if minPrice > nowPrice{
                        minCountry = dict.key
                        minPrice = nowPrice
                    }
                }else if minPrice > nowPrice{
                    minCountry = dict.key
                    minPrice = nowPrice
                }
            }
        }
        return minCountry
    }
    //貨幣轉換器
    func calculateCurrency(currency: String, price: Double, exchangeRateList: [String:Any]) -> Decimal{
        //換算匯率
        let defaultCurrency = userDefaults.value(forKey: "appDefaultCurrency") as! String
        var roundedDefaultPrice = Decimal()
        if currency != "USD"{
            if let toCurrency = exchangeRateList["USD\(currency)"] as? [String:Any]{
                let rate = toCurrency["Exrate"] as! Double
                if let toFinalCurrency = exchangeRateList["USD\(defaultCurrency)"] as? [String:Any]{
                    //轉換成美金USD
                    let value1 = Decimal(floatLiteral: price)
                    let value2 = Decimal(floatLiteral: rate)
                    //var roundedValue1 = Decimal()
                    //var roundedValue2 = Decimal()
                    //四捨五入到小數點第四位
                    var scale = 4
                    //NSDecimalRound(&roundedValue1, &value1, scale, NSDecimalNumber.RoundingMode.plain)
                    //NSDecimalRound(&roundedValue2, &value2, scale, NSDecimalNumber.RoundingMode.plain)
                    //根據匯率去換算
                    let toUSDPrice = self.calculateProfitRate(tatolProfit: value1, tatolBet: value2)
                    //轉換成app預設貨幣
                    //USD to app預設貨幣的匯率
                    let defaultCurrencyRate = toFinalCurrency["Exrate"] as! Double
                    //根據匯率去換算
                    var toDefaultPrice = Decimal(floatLiteral: toUSDPrice * defaultCurrencyRate)
                    //四捨五入到小數點第二位
                    scale = 2
                    NSDecimalRound(&roundedDefaultPrice, &toDefaultPrice, scale, NSDecimalNumber.RoundingMode.plain)
                }
            }
        }else{
            
            //轉換成app預設貨幣
            if let toFinalCurrency = exchangeRateList["USD\(defaultCurrency)"] as? [String:Any]{
                
                //USD to app預設貨幣的匯率
                let defaultCurrencyRate = toFinalCurrency["Exrate"] as! Double
                //根據匯率去換算
                var toDefaultPrice = Decimal(floatLiteral: price * defaultCurrencyRate)
                //四捨五入到小數點第二位
                let scale = 2
                NSDecimalRound(&roundedDefaultPrice, &toDefaultPrice, scale, NSDecimalNumber.RoundingMode.plain)
            }
        }
        return roundedDefaultPrice
    }
    func updateCountryPrice(){
        for price in countryPrice{
            let gameCode = price.key
            for data in price.value{
                let country = data.key
                let currency = countries[country]!["countryDollar"]
                if let eshopPrice = data.value["eshopPrice"] as? Double{
                    let defaultPrice = self.calculateCurrency(currency: currency!, price: eshopPrice, exchangeRateList: self.exchangeRateList)
                    self.countryPrice[gameCode]![country]!["eshop_default_price"] = defaultPrice
                }
                if let salePrice = data.value["salePrice"] as? Double{
                    let defaultPrice = self.calculateCurrency(currency: currency!, price: salePrice, exchangeRateList: self.exchangeRateList)
                    self.countryPrice[gameCode]![country]!["sale_default_price"] = defaultPrice
                }
            }
        }
    }
    //預載遊戲價錢及遊戲圖片
    func preLoad(index:Int, count: Int, preLoadGames: [GameListInfo], viewName: String, exchangeRate: [String:Any]){
        if preLoadGames.count > 0 && preLoadGames.count >= index && exchangeRate.count > 0{
            
            if countryPrice[getGameCode(game: preLoadGames[index])] == nil{
                
                //讀取條開始
                //self.myIndicator.startAnimating()
                //self.indicatorBackground.alpha = 0.85
                //self.indicatorBackground.isHidden = false
                //self.downloadLabel.isHidden = false
                //需預載的GameID Array
                var gameIDArray = Array<String>()
                var idToCode = [String:String]()
                var range = index+count-1
                if preLoadGames.count < index+count{
                    range = preLoadGames.count-1
                }
                for i in index...range{
                    print(i)
                    let gameCode = getGameCode(game: preLoadGames[i])
                    //透過url下載遊戲圖片
                    do{
                        let url = URL(string: getGameImage(game: preLoadGames[i]))
                        let data = try Data(contentsOf: url!)
                        gameImageArray[gameCode] = data
                    }catch{
                        print(error.localizedDescription)
                    }
                    
                    //預載的價錢清單初始化
                    countryPrice[gameCode] = [String: [String: Double]]()
                    for id in getGameID(game: preLoadGames[i]){
                        gameIDArray.append(id)
                        idToCode[id] = gameCode
                    }
                    
                }
                
                //透過switch price api下載遊戲價錢
                var index = 0
                let listCount = countries.count
//                var r = Int()
//                if (gameIDArray.count) % 50 == 0{
//                    r = gameIDArray.count / 50
//                }else{
//                    r = (gameIDArray.count / 50) + 1
//                }
                
                for country in countries{
                    DBManager.shared.loadGameIDCountryPrice(gameID: gameIDArray, countryID: country.key, completion: {(result, countryPriceList) in
                        if result{
                            for priceList in countryPriceList{
                                let sales_Status = priceList["sales_status"] as? String
                                if sales_Status == "onsale" || sales_Status == "preorder"{
                                    let eshopPriceList = priceList["regular_price"] as? [String: Any]
                                    let salePriceList = priceList["discount_price"] as? [String: Any]
                                    let title_id = String(priceList["title_id"] as! Int)
                                    let gameCode = idToCode[title_id]
                                    if self.countryPrice[gameCode!] == nil{
                                        self.countryPrice[gameCode!] = [String:[String:Double]]()
                                    }
                                    self.countryPrice[gameCode!]![country.key] = [String: Any]()
                                    
                                    
                                    if eshopPriceList != nil{
                                        if let eshopPrice = Double(eshopPriceList!["raw_value"] as! String){
                                            self.countryPrice[gameCode!]![country.key]!["eshopPrice"] = eshopPrice
                                            //換算匯率
                                            
                                            if let currency = eshopPriceList!["currency"] as? String{
                                                
                                                let defaultPrice = self.calculateCurrency(currency: currency, price: eshopPrice, exchangeRateList: exchangeRate)
                                                self.countryPrice[gameCode!]![country.key]!["eshop_default_price"] = defaultPrice
                                                
                                            }
                                        }
                                        if let eshopAmount = eshopPriceList!["amount"] as? String{
                                            self.countryPrice[gameCode!]![country.key]!["eshopAmount"] = eshopAmount
                                        }
                                        
                                    }
                                    if salePriceList != nil{
                                        if let salePrice = Double(salePriceList!["raw_value"] as! String){
                                            self.countryPrice[gameCode!]![country.key]!["salePrice"] = salePrice
                                            let start_datetime = salePriceList!["start_datetime"] as! String
                                            let end_datetime = salePriceList!["end_datetime"] as! String
                                            if start_datetime != ""{
                                                self.countryPrice[gameCode!]![country.key]!["start_datetime"] = start_datetime
                                            }
                                            if end_datetime != ""{
                                                self.countryPrice[gameCode!]![country.key]!["end_datetime"] = end_datetime
                                            }
                                            if let saleAmount = salePriceList!["amount"] as? String{
                                                self.countryPrice[gameCode!]![country.key]!["saleAmount"] = saleAmount
                                            }
                                            //換算匯率
                                            if let currency = eshopPriceList!["currency"] as? String{
                                                
                                                let defaultPrice = self.calculateCurrency(currency: currency, price: salePrice, exchangeRateList: exchangeRate)
                                                self.countryPrice[gameCode!]![country.key]!["sale_default_price"] = defaultPrice
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            index += 1
                            if index == listCount{
                                NotificationCenter.default.post(name: Notification.Name(viewName), object: nil)
                            }
                        }else{
                            print("API Fail.")
                        }
                        
                    })
//                    for i in 0...r-1{
//                        var gameIDArrayStr = ArraySlice<String>()
//                        if i == r-1{
//                            gameIDArrayStr = gameIDArray[i*50 ..< gameIDArray.endIndex]
//                        }else{
//                            gameIDArrayStr = gameIDArray[i*50 ..< (i+1)*50-1]
//                        }
//
//                    }
                    
                }
            }
        }
        
        
    }
    
}

