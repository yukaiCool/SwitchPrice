//
//  DBManager.swift
//  switchPrice
//
//  Created by YuKai on 2019/3/21.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit


class DBManager: NSObject, XMLParserDelegate {
    //使用函式只需要DBManager.shared.Do_something()
    static let shared: DBManager = DBManager()
    //資料庫名稱
    let databaseFileName = "database.sqilte"
    //資料庫路徑
    var pathToDatabase : String!
    //使用FMDB建立資料庫物件
    var database : FMDatabase!
    //資料庫欄位
    let field_US_gameTable = "gameUS"
    let field_EU_gameTable = "gameEU"
    let field_JP_gameTable = "gameJP"
    let field_TempGame_gameTable = "TempGame"
    let field_Game_gameTable = "Game"
    //US
    let field_gameUS_gameID = "uid"
    let field_gameUS_gameTitle = "name"
    let field_gameUS_releaseDate = "releaseDate"
    let field_gameUS_gameImage = "image"
    let field_gameUS_gameCode = "gameCode"
    let field_gameUS_category = "category"
    let field_gameUS_players = "number_of_players"
    let field_gameUS_url = "id"
    //EU
    let field_gameEU_nsuid_txt = "nsuid_txt"
    let field_gameEU_title = "title"
    let field_gameEU_dates_released_dts = "dates_released_dts"
    let field_gameEU_image_url = "image_url"
    let field_gameEU_product_code_txt = "product_code_txt"
    let field_gameEU_url = "url"
    let field_gameEU_language = "language_availability"
    let field_gameEU_players = "players_to"
    let field_gameEU_category = "game_category"
    let field_gameEU_excerpt = "excerpt"
    //JP
    let field_gameJP_nsuid = "nsuid"
    let field_gameJP_title_name = "title_name"
    let field_gameJP_maker_kana = "maker_kana"
    let field_gameJP_sales_date = "sales_date"
    let field_gameJP_screenshot_img_url = "screenshot_img_url"
    let field_gameJP_initial_code = "initial_code"
    let field_gameJP_url = "linkURL"
    //是否需要更新
    var isUpdate = false
    var isGameUSCheck = false
    var isGameEUCheck = false
    var isGameJPCheck = false
    //遊戲清單
    //----------US-----------------
    var gameUSArray = [Any]()
    var gamesTotal = 0
    var isFinishUS = false
    //----------US-----------------
    //----------EU-----------------
    var gameEUArray = [Any]()
    var gameTitle = ""
    var isFinishEU = false
    //----------EU-----------------
    //----------JP-----------------
    var gameJPArray: [GameJP] = []
    var eName: String = String()
    var nsuid = String()
    var title_name = String()
    var maker_kana = String()
    var sales_date = String()
    var screenshot_img_url = String()
    var initial_code = String()
    var url = String()
    var isFinishJP = false
    //----------JP-----------------
    //初始化物件
    override init() {
        super.init()
        
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDirectory.appending("/\(databaseFileName)")
        print("Path:\(pathToDatabase!)")
    }
    
    //創建資料庫
    func createDatabase() -> Bool {
        var created = false
        //當數據庫檔案不存在時創建資料庫
        if !FileManager.default.fileExists(atPath: pathToDatabase){
            database = FMDatabase(path: pathToDatabase)
            //當資料庫存在時
            if database != nil{
                //打開資料庫
                if database.open(){
                    //創建資料庫語法primary key
                    let createGameUSTableQuery = "create table \(field_US_gameTable)(" +
                                "\(field_gameUS_gameID) text primary key not null, " +
                                "\(field_gameUS_gameTitle) text not null, " +
                                "\(field_gameUS_gameCode) text not null, " +
                                "\(field_gameUS_releaseDate) date, " +
                                "\(field_gameUS_gameImage) text, " +
                                "\(field_gameUS_category) text, " +
                                "\(field_gameUS_players) text, " +
                                "\(field_gameUS_url) text)"
                    let createGameEUTableQuery = "create table \(field_EU_gameTable)(" +
                                "\(field_gameEU_nsuid_txt) text primary key not null, " +
                                "\(field_gameEU_title) text not null, " +
                                "\(field_gameEU_product_code_txt) text not null, " +
                                "\(field_gameEU_dates_released_dts) date, " +
                                "\(field_gameEU_image_url) text, " +
                                "\(field_gameEU_category) text, " +
                                "\(field_gameEU_language) text, " +
                                "\(field_gameEU_url) text, " +
                                "\(field_gameEU_excerpt) text, " +
                                "\(field_gameEU_players) text)"
                    let createGameJPTableQuery = "create table \(field_JP_gameTable)(" +
                                "\(field_gameJP_nsuid) text primary key not null, " +
                                "\(field_gameJP_title_name) text not null, " +
                                "\(field_gameJP_maker_kana) text not null, " +
                                "\(field_gameJP_initial_code) text not null, " +
                                "\(field_gameJP_sales_date) date, " +
                                "\(field_gameJP_screenshot_img_url) text, " +
                                "\(field_gameJP_url) text)"
                    
                    //執行資料庫語法
                    do{
                        try database.executeUpdate(createGameUSTableQuery, values: nil)
                        try database.executeUpdate(createGameEUTableQuery, values: nil)
                        try database.executeUpdate(createGameJPTableQuery, values: nil)
                        created = true
                        print("Database created!")
                    }
                    catch{
                        print("Could not create table!")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                }
                else{
                    print("Could not open the datebase!")
                }
            }
        }
        return created
    }
    //打開資料庫
    func openDatabase() ->Bool{
        if database == nil{
            if FileManager.default.fileExists(atPath: pathToDatabase){
                database = FMDatabase(path: pathToDatabase)
            }
        }
        
        if database != nil{
            if database.open(){
                return true
            }
        }
        return false
    }
    //-----------------------------------US-----------------------------------------------
    //讀取遊戲清單總共有幾款遊戲
    func loadURLGameUSTotal(completion: @escaping (_ result: Bool) -> Void) {
        //美國switch遊戲資料庫URL
        let urlUS = URL(string: "https://www.nintendo.com/json/content/get/filter/game?system=switch&sort=title")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            if error == nil{
                let responseStatus = response as! HTTPURLResponse
                if responseStatus.statusCode == 200{
                    if let dataDic = try? (JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:[String:AnyObject]]) {
                        DispatchQueue.main.async {
                            self.gamesTotal = dataDic["filter"]!["total"] as! Int
                            completion(true)
                        }
                    }
                    else{
                        print("No data")
                        completion(false)
                    }
                }
            }else{
                print("<=== HTTP Load Fail ===>")
                print(error?.localizedDescription as Any)
            }
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    //US_GAME 通過url下載資料庫到手機資料庫
    func loadURLGameUSData(total: Int ,completion: @escaping (_ result: Bool) -> Void){
        //美國switch遊戲資料庫URL
        let urlUS = URL(string: "https://www.nintendo.com/json/content/get/filter/game?system=switch&sort=title&limit=200&offset=\(total)")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            if error == nil{
                let responseStatus = response as! HTTPURLResponse
                if responseStatus.statusCode == 200{
                    if let dataDic = try? (JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:[String:Any]]) {
                        self.gameUSArray = dataDic["games"]!["game"] as! [Any]
                        completion(true)

                    }
                    else{
                        print("No data")
                        completion(false)
                    }
                }
            }else{
                print("<=== HTTP Load Fail ===>")
                print(error?.localizedDescription as Any)
            }
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    
    //US_GAME 遊戲清單新增到資料庫
    func insertGameUSData(){
        if openDatabase(){
            var queryGameList = ""
            for game in gameUSArray{
                let gameValue = game as! [String:Any]
                //遊戲ID
                let uid = gameValue["nsuid"] as? String
                if uid != nil {
                    //遊戲名稱
                    let name = gameValue["title"] as! String
                    let converterName = name.replacingOccurrences(of: "'", with: "''")
                    queryGameList += "insert into \(field_US_gameTable)(" +
                                    "\(field_gameUS_gameTitle), " +
                                    "\(field_gameUS_gameID), " +
                                    "\(field_gameUS_gameCode), " +
                                    "\(field_gameUS_releaseDate), " +
                                    "\(field_gameUS_gameImage), " +
                                    "\(field_gameUS_category), " +
                                    "\(field_gameUS_players), " +
                                    "\(field_gameUS_url))" +
                                    "values('\(converterName)','\(uid!)'"
                    //遊戲商品序號
                    let gameCode = gameValue["game_code"] as! String
                    let replacingGameCode = gameCode.replacingOccurrences(of: "-", with: "")
                    queryGameList += ", '\(replacingGameCode.suffix(5))'"
                    //販售時間
                    let releaseDate = gameValue["release_date"] as? String
                    if releaseDate != nil{
                        let dateFormot = DateFormatter()
                        dateFormot.dateFormat = "MMM dd, yyyy"
                        let date = dateFormot.date(from: releaseDate!)
                        dateFormot.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormot.string(from: date!)
                        queryGameList += ", '\(dateString)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲圖片連結
                    let image = gameValue["front_box_art"] as? String
                    if image != nil{
                        queryGameList += ", '\(image!)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲類型
                    if (gameValue["category"] as? [String]) != nil{
                        var category = ""
                        for categoryStr in (gameValue["category"] as! [String]){
                            category += categoryStr + ","
                        }
                        queryGameList += ", '\(category)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊玩人數
                    if (gameValue["number_of_players"] as? String) != nil{
                        let players = gameValue["number_of_players"] as! String
                        queryGameList += ", '\(players)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲資料連結
                    if (gameValue["id"] as? String) != nil{
                        let url = "https://www.nintendo.com/games/detail/" + (gameValue["number_of_players"] as! String)
                        queryGameList += ", '\(url)');"
                    }else{
                        queryGameList += ", null);"
                    }
                    
                }
            }
            if !database.executeStatements(queryGameList){
                print("Failed to insert initial data into the database(GameUSTable).")
                print(database.lastError())
                print(database.lastErrorMessage())
            }
            database.close()
        }
    }
    //彙整US_GAME讀取資料到存入資料庫
    func createUSGameToDatabase(){
        //US_GAME 讀取遊戲清單數量
        loadURLGameUSTotal{(result) in
            if result{
                var isLoad = true
                var count = 0
                var total = 0
                while isLoad{
                    if count <= self.gamesTotal{
                        //解析JSON
                        self.loadURLGameUSData(total: count, completion: {(result: Bool) in
                            if result{
                                //存入資料庫(gameUSTable)
                                self.insertGameUSData()
                                print("US_GAME:第\(total)~\(total+200)筆 Database insert finish.")
                                total += 200
                                if total > self.gamesTotal{
                                    self.isFinishUS = true
                                    NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
                                }
                                
                            }else{
                                print("US_GAME: Database insert fail.")
                                
                            }
                        })
                        count += 200
                    }else{
                        isLoad = false
                    }
                }
            }
            else{
                print("Database load gameUSTotal fail.")
            }
        }
    }
    //判斷US GAME是否有資料
    func isGameUSDatabase() -> Bool{
        if openDatabase(){
            let query = "select * from \(field_US_gameTable)"
            do{
                let result = try database.executeQuery(query, values: nil)
                if result.next(){
                    return true
                }
            }catch{
               print(error.localizedDescription)
            }
            database.close()
        }
        return false
    }
    //暫時用文件匯入US GAME
    func loadGameUS(){
        if openDatabase(){
            if let pathToFile = Bundle.main.path(forResource: "gameUS", ofType: "txt"){
                do{
                    let fileContents = try String(contentsOfFile: pathToFile)
                    let fileData = fileContents.components(separatedBy: "\n")
                    
                    var query = ""
                    var index = 1
                    for data in fileData{
                        let dataParts = data.components(separatedBy: "\t")
                        
                        let uid = dataParts[0].replacingOccurrences(of: " ", with: "")
                        let name = dataParts[1].replacingOccurrences(of: "'", with: "''")
                        let gamecode = dataParts[2]
                        let releaseDate = dataParts[3].replacingOccurrences(of: "\"", with: "")
                        let dateFormot = DateFormatter()
                        dateFormot.dateFormat = "MMM dd, yyyy"
                        let date = dateFormot.date(from: releaseDate)
                        dateFormot.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormot.string(from: date!)
                        let image = dataParts[4]
                        
                        query += "insert into \(field_US_gameTable)(\(field_gameUS_gameTitle),\(field_gameUS_gameID),\(field_gameUS_gameCode),\(field_gameUS_releaseDate),\(field_gameUS_gameImage)) values('\(name)','\(uid)','\(gamecode)','\(dateString)','\(image)');"
                        
                        index += 1
                    }
                    
                    if !database.executeStatements(query) {
                        
                        print("Failed to insert initial data into the database.")
                        print(database.lastError(), database.lastErrorMessage())
                    }
                }catch{
                    print(error.localizedDescription)
                }
            }
            
            database.close()
        }
        
    }
    //重新讀取資料庫判斷是否要更新資料庫
    func updateGameUSDatabase(){
        isGameUSCheck = true
        NotificationCenter.default.post(name: Notification.Name("ReloadDatabase"), object: nil)
    }
    //-----------------------------------US-----------------------------------------------
    //-----------------------------------EU-----------------------------------------------
    //EU_GAME 通過url下載資料庫到手機資料庫
    func loadURLGameEUData(completion: @escaping (_ result: Bool) -> Void){
        //歐洲switch遊戲資料庫URL
        let urlUS = URL(string: "https://search.nintendo-europe.com/en/select?fq=type:GAME%20AND%20system_type:nintendoswitch*%20AND%20product_code_txt:*&q=*&sort=sorting_title%20asc&wt=json&rows=9999&start=0")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            if error == nil{
                let responseStatus = response as! HTTPURLResponse
                if responseStatus.statusCode == 200{
                    if let dataDic = try? (JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:[String:Any]]) {
                        self.gameEUArray = [Any]()
                        self.gameEUArray = dataDic["response"]!["docs"] as! [Any]
                        completion(true)
                    }
                    else{
                        completion(false)
                    }
                }
            }else{
                print("<=== HTTP Load Fail ===>")
                print(error?.localizedDescription as Any)
            }
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    
    //EU_GAME 遊戲清單新增到資料庫
    func insertGameEUData(games: [Any]){
        if openDatabase(){
            var queryGameList = ""
            for game in games{
                let gameValue = game as! [String:Any]
                let name = gameValue["title"] as? String
                let uid = gameValue["nsuid_txt"] as? [String]
                //判斷遊戲ID是否存在 及 是否有重複資料
                if uid != nil && name != gameTitle{
                    //遊戲ID
                    let id = uid![0]
                    //遊戲名稱
                    let converterName = name!.replacingOccurrences(of: "'", with: "''")
                    //新增語法
                    queryGameList += "insert into \(field_EU_gameTable)(" +
                                    "\(field_gameEU_title), " +
                                    "\(field_gameEU_nsuid_txt), " +
                                    "\(field_gameEU_product_code_txt), " +
                                    "\(field_gameEU_dates_released_dts), " +
                                    "\(field_gameEU_image_url), " +
                                    "\(field_gameEU_category), " +
                                    "\(field_gameEU_players), " +
                                    "\(field_gameEU_language), " +
                                    "\(field_gameEU_url), " +
                                    "\(field_gameEU_excerpt)) " +
                                    "values('\(converterName)','\(id)'"
                    //遊戲商品序號
                    let gameCode = gameValue["product_code_txt"] as! [String]
                    let code = gameCode[0]
                    let replacingGameCode = code.replacingOccurrences(of: " ", with: "")
                    queryGameList += ", '\(replacingGameCode.suffix(5))'"
                    //販售時間
                    let releaseDate = gameValue["dates_released_dts"] as? [String]
                    if releaseDate != nil{
                        let date = releaseDate![0]
                        let dateFormot = DateFormatter()
                        dateFormot.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let dateToFormot = dateFormot.date(from: date)
                        dateFormot.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormot.string(from: dateToFormot!)
                        queryGameList += ", '\(dateString)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲圖片連結
                    let image = gameValue["image_url"] as? String
                    if image != nil{
                        queryGameList += ", 'http:\(image!)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲類型
                    if (gameValue["game_category"] as? [String]) != nil{
                        let category = gameValue["game_category"] as! [String]
                        queryGameList += ", '\(category[0])'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊玩人數
                    if (gameValue["players_to"] as? Int) != nil{
                        let players = String(gameValue["players_to"] as! Int) + " players"
                        queryGameList += ", '\(players)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲語言
                    if (gameValue["language_availability"] as? [String]) != nil{
                        let language = gameValue["language_availability"] as! [String]
                        queryGameList += ", '\(language[0])'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲資料連結
                    if (gameValue["url"] as? String) != nil{
                        let url = "https://www.nintendo.co.uk" + (gameValue["url"] as! String)
                        queryGameList += ", '\(url)'"
                    }else{
                        queryGameList += ", null"
                    }
                    //遊戲說明
                    if (gameValue["excerpt"] as? String) != nil{
                        let excerpt = gameValue["excerpt"] as! String
                        let converterExcerpt = excerpt.replacingOccurrences(of: "'", with: "''")
                        queryGameList += ", '\(converterExcerpt)');"
                    }else{
                        queryGameList += ", null);"
                    }
                    //print(queryGameList)
                    //判斷是否有重複資料
                    gameTitle = name!
                    
                    
                }
            }
            if !database.executeStatements(queryGameList){
                print("Failed to insert initial data into the database(GameEUTable).")
                print(database.lastError())
                print(database.lastErrorMessage())
            }
            database.close()
        }
    }
    //彙整EU_GAME讀取資料到存入資料庫
    func createEUGameToDatabase(){
        //EU_GAME 解析JSON
        loadURLGameEUData(completion: {(result) in
            if result{
                //存入資料庫(gameEUTable)
                self.insertGameEUData(games: self.gameEUArray)
                self.isFinishEU = true
                print("EU_GAME: Database insert finish.")
                NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
            }else{
                print("EU_GAME: Datebase insert fail.")
            }
        })
    }
    //判斷EU GAME是否有資料
    func isGameEUDatabase() -> Bool{
        if openDatabase(){
            let query = "select * from \(field_EU_gameTable)"
            do{
                let result = try database.executeQuery(query, values: nil)
                if result.next(){
                    return true
                }
            }catch{
                print(error.localizedDescription)
            }
            database.close()
        }
        return false
    }
    //重新讀取資料庫判斷是否要更新資料庫
    func updateGameEUDatabase(){
        loadURLGameEUData { (result) in
            if result{
                self.checkGameEUHaveNewData()
            }else{
                print("EU Games load fail.")
                //print("EU Games data is new, don't need to update.")
            }
        }
    }
    func checkGameEUHaveNewData(){
        if openDatabase(){
            //判斷資料是否需要新增或修改
            var insertData = [Any]()
            for game in self.gameEUArray{
                let gameValue = game as! [String:Any]
                let id = gameValue["nsuid_txt"] as? [String]
                if id != nil{
                    let gameID = id![0]
//                    let gameTitle = gameValue["title"] as? String
//                    let code = gameValue["product_code_txt"] as! [String]
//                    let gameCode = code[0]
//                    let releaseDate = gameValue["dates_released_dts"] as? [String]
//                    if releaseDate != nil{
//                        let date = releaseDate![0]
//                        let gameReleaseDate = HomeViewController.shared.dateOutput(date: date)
//                    }
                    let query = "select * from \(field_EU_gameTable) where \(field_gameEU_nsuid_txt)=?"
                    do{
                        let result = try database.executeQuery(query, values: [gameID])
                        
                        if !result.next(){
                            //New data to insert
                            insertData.append(gameValue)
                            
                        }else{
                            //old data to update
                            
                        }
                    }catch{
                        print(error.localizedDescription)
                    }
                    
                }
            }
            //New data to insert
            if insertData.count > 0{
                insertGameEUData(games: insertData)
                print("EU Game insert success for \(insertData.count)")
                isUpdate = true
                //NotificationCenter.default.post(name: Notification.Name("ReloadDatabase"), object: nil)
            }else{
                print("EU Game no new data.")
            }
            database.close()
            isGameEUCheck = true
            NotificationCenter.default.post(name: Notification.Name("ReloadDatabase"), object: nil)
        }
    }
    //-----------------------------------EU-----------------------------------------------
    //-----------------------------------JP-----------------------------------------------
    //JP_GAME 通過url下載資料庫到手機資料庫
    func loadURLGameJPData(completion: @escaping (_ result: Bool) -> Void){
        //歐洲switch遊戲資料庫URL
        let urlUS = URL(string: "https://www.nintendo.co.jp/data/software/xml/switch.xml")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else{
                print(error ?? "unknow errer.")
                completion(false)
                return
            }
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            completion(true)
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    //JP_GAME 遊戲清單新增到資料庫
    func insertGameJPData(games: [GameJP]){
        if openDatabase(){
            var queryGameList = ""
            for game in games{
                //遊戲ID
                let uid = game.nsuid
                //遊戲名稱
                let name = game.title_name
                let converterName = name.replacingOccurrences(of: "'", with: "''")
                //新增語法
                queryGameList += "insert into \(field_JP_gameTable)(" +
                                "\(field_gameJP_title_name), " +
                                "\(field_gameJP_nsuid), " +
                                "\(field_gameJP_maker_kana), " +
                                "\(field_gameJP_initial_code), " +
                                "\(field_gameJP_sales_date), " +
                                "\(field_gameJP_screenshot_img_url), " +
                                "\(field_gameJP_url)) " +
                                "values('\(converterName)','\(uid)'"
                //遊戲片假名
                let maker_kana = game.maker_kana
                queryGameList += ", '\(maker_kana)'"
                //遊戲商品序號
                let gameCode = game.initial_code
                queryGameList += ", '\(gameCode)'"
                //販售日期
                let releaseDate = game.sales_date
                let dateFormot = DateFormatter()
                dateFormot.dateFormat = "yyyy.MM.dd"
                if let dateToFormot = dateFormot.date(from: releaseDate){
                    dateFormot.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormot.string(from: dateToFormot)
                    queryGameList += ", '\(dateString)'"
                }else{
                    queryGameList += ", null"
                }
                
                //遊戲圖片
                let image = game.screenshot_img_url
                queryGameList += ", '\(image)'"
                //遊戲資料連結
                let url = game.url
                queryGameList += ", '\(url)');"
                
      
            }
            if !database.executeStatements(queryGameList){
                print("Failed to insert initial data into the database(GameEUTable).")
                print(database.lastError())
                print(database.lastErrorMessage())
            }
            database.close()
        }
    }
    //XMLParser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        eName = elementName
        if elementName == "TitleInfo"{
            nsuid = String()
            title_name = String()
            maker_kana = String()
            sales_date = String()
            screenshot_img_url = String()
            initial_code = String()
            url = String()
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "TitleInfo"{
            let gameJP = GameJP()
            gameJP.nsuid = nsuid
            gameJP.title_name = title_name
            gameJP.maker_kana = maker_kana
            gameJP.sales_date = sales_date
            gameJP.screenshot_img_url = screenshot_img_url
            gameJP.initial_code = initial_code
            gameJP.url = url
            gameJPArray.append(gameJP)
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if eName == "TitleName"{
            title_name = string
        }else if eName == "MakerName"{
            maker_kana = string
        }else if eName == "LinkURL"{
            let data = string.replacingOccurrences(of: "/titles/", with: "")
            nsuid = data
        }else if eName == "SalesDate"{
            sales_date = string
        }else if eName == "ScreenshotImgURL"{
            screenshot_img_url = string
        }else if eName == "InitialCode"{
            let data = string.replacingOccurrences(of: " ", with: "")
            initial_code = String(data.suffix(5))
        }else if eName == "LineURL"{
            let data = "https://ec.nintendo.com/JP/ja" + string
            url = data
        }
    }
    //彙整JP_GAME讀取資料到存入資料庫
    func createJPGameToDatabase(){
        //JP_GAME 解析XML
        loadURLGameJPData(completion: {(result) in
            if result{
                self.insertGameJPData(games: self.gameJPArray)
                self.isFinishJP = true
                print("JP_GAME: Database insert finish.")
                NotificationCenter.default.post(name: Notification.Name("GET_DATA"), object: nil)
            }else{
                print("JP_GAME: Datebase insert fail.")
            }
        })
    }
    //判斷JP GAME是否有資料
    func isGameJPDatabase() -> Bool{
        if openDatabase(){
            let query = "select * from \(field_JP_gameTable)"
            do{
                let result = try database.executeQuery(query, values: nil)
                if result.next(){
                    return true
                }
            }catch{
                print(error.localizedDescription)
            }
            database.close()
        }
        return false
    }
    //重新讀取資料庫判斷是否要更新資料庫
    func updateGameJPDatabase(){
        loadURLGameJPData { (result) in
            if result{
                self.checkGameJPHaveNewData()
            }else{
                print("JP Games load fail.")
                //print("EU Games data is new, don't need to update.")
            }
        }
    }
    func checkGameJPHaveNewData(){
        if openDatabase(){
            //判斷資料是否需要新增或修改
            var insertData = [GameJP]()
            for game in self.gameJPArray{
                let gameID = game.nsuid
                if gameID != ""{
                    let query = "select * from \(field_JP_gameTable) where \(field_gameJP_nsuid)=?"
                    do{
                        let result = try database.executeQuery(query, values: [gameID])
                        
                        if !result.next(){
                            //New data to insert
                            insertData.append(game)
                            
                        }else{
                            //old data to update
                            
                        }
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
            //New data to insert
            if insertData.count > 0{
                insertGameJPData(games: insertData)
                print("JP Game insert success for \(insertData.count)")
                isUpdate = true
            }else{
                print("JP Game no new data.")
            }
            database.close()
            isGameJPCheck = true
            NotificationCenter.default.post(name: Notification.Name("ReloadDatabase"), object: nil)
        }
    }
    //-----------------------------------JP-----------------------------------------------
    //------------------------------------------------------------------------------------
    //讀取遊戲清單
    func loadGameList() -> [GameListInfo]!{
        var games: [GameListInfo]!
        if openDatabase(){
            let query = "select * from \(field_Game_gameTable) order by case when us_gamecode is null then 1 else 0 end, us_gamecode asc"
            do{
                let results = try database.executeQuery(query, values: nil)        
                while results.next(){
                    var category = ""
                    if let data = results.string(forColumn: "us_category"){
                        category = data
                    }else if let data = results.string(forColumn: "eu_category"){
                        category = data
                    }
                    var players = ""
                    if let data = results.string(forColumn: "us_players"){
                        players = data
                    }else if let data = results.string(forColumn: "eu_players"){
                        players = data
                    }
                    var game = GameListInfo(us_gameCode: results.string(forColumn: "us_gamecode"),
                                            us_gameID: results.string(forColumn: "us_nsuid"),
                                            us_gameTitle: results.string(forColumn: "us_title"),
                                            us_gameReleaseDate: results.string(forColumn: "us_releasedate"),
                                            us_gameImage: results.string(forColumn: "us_gameimage"),
                                            us_url: results.string(forColumn: "us_url"),
                                            eu_gameCode: results.string(forColumn: "eu_gamecode"),
                                            eu_gameID: results.string(forColumn: "eu_nsuid"),
                                            eu_gameTitle: results.string(forColumn: "eu_title"),
                                            eu_gameReleaseDate: results.string(forColumn: "eu_releasedate"),
                                            eu_gameImage: results.string(forColumn: "eu_gameimage"),
                                            eu_url: results.string(forColumn: "eu_url"),
                                            jp_gameCode: results.string(forColumn: "jp_gamecode"),
                                            jp_gameID: results.string(forColumn: "jp_nsuid"),
                                            jp_gameTitle: results.string(forColumn: "jp_title"),
                                            jp_gameReleaseDate: results.string(forColumn: "jp_releasedate"),
                                            jp_gameImage: results.string(forColumn: "jp_gameimage"),
                                            jp_url: results.string(forColumn: "jp_url"),
                                            language: results.string(forColumn: "eu_language"),
                                            category: category,
                                            players: players,
                                            excerpt: results.string(forColumn: "eu_excerpt"),
                                            favourite: results.bool(forColumn: "favourite"))
                    if games == nil{
                        games = [GameListInfo]()
                    }
                    game = extensionGame(game: game)
                    if HomeViewController.shared.getGameCode(game: game) != ""{
                        games.append(game)
                    }

                }
            }catch{
                print(error.localizedDescription)
            }
            database.close()
        }
        return games
    }
    //遊戲清單例外處理
    func extensionGame(game: GameListInfo) -> GameListInfo{
        var gameEx = game
        if gameEx.us_gameCode == "AB38A" {
            if gameEx.us_gameTitle == "NBA 2K18" && gameEx.jp_gameTitle == "NBA 2K18"{
                
            }else if gameEx.us_gameTitle == "NBA 2K18 Legend Edition" && gameEx.jp_gameTitle == "レジェンド エディション"{
                gameEx = euGameToNil(game: gameEx)
                gameEx.us_gameCode = "AB38A2"
                gameEx.jp_gameCode = "AB38A2"
                
            }else if gameEx.us_gameTitle == "NBA 2K18 Legend Edition Gold" && gameEx.jp_gameTitle == "レジェンド エディション ゴールド"{
                gameEx = euGameToNil(game: gameEx)
                gameEx.us_gameCode = "AB38A3"
                gameEx.jp_gameCode = "AB38A3"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.us_gameCode == "AGBLA" {
            if gameEx.us_gameTitle == "Dragon Marked for Death: Frontline Fighters" && gameEx.jp_gameTitle == "ベーシックセット - 皇女と戦士 -"{
                
            }else if gameEx.us_gameTitle == "Dragon Marked for Death: Advanced Attackers" && gameEx.jp_gameTitle == "エキスパートセット - 忍びと魔女 -"{
                gameEx = euGameToNil(game: gameEx)
                gameEx.us_gameCode = "AGBLA2"
                gameEx.jp_gameCode = "AGBLA2"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.us_gameCode == "AQNYA" {
            if gameEx.us_gameTitle == "NBA 2K19" && gameEx.jp_gameTitle == "NBA 2K19"{
                
            }else if gameEx.us_gameTitle == "NBA 2K19 20th Anniversary Edition" && gameEx.jp_gameTitle == "周年記念エディション"{
                gameEx = euGameToNil(game: gameEx)
                gameEx.us_gameCode = "AQNYA2"
                gameEx.jp_gameCode = "AQNYA2"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.us_gameCode == "AQYTB" {
            if gameEx.us_gameTitle == "NAtelier Rorona ~The Alchemist of Arland~ DX"{
                
            }else if gameEx.us_gameTitle == "Atelier Arland series Deluxe Pack" {
                gameEx = euGameToNil(game: gameEx)
                gameEx.us_gameCode = "AQYTB2"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.jp_gameCode == "AD2DA" {
            if gameEx.jp_gameTitle == "信長の野望･大志 "{
                
            }else if gameEx.jp_gameTitle == "信長の野望･大志 with パワーアップキット " {
                gameEx.jp_gameCode = "AD2DA2"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.jp_gameCode == "AQYTA" {
            if gameEx.jp_gameTitle == "アトリエ ～アーランドの錬金術士１・２・３～ DX"{
                
            }else if gameEx.jp_gameTitle == "ロロナのアトリエ ～アーランドの錬金術士～ DX" {
                gameEx.jp_gameCode = "AQYTA2"
            }else{
                gameEx = GameListInfo()
            }
        }
        if gameEx.jp_gameCode == "AAB6A" {
            gameEx.jp_gameCode = "AAB6B"
        }
        if gameEx.eu_gameCode == "AAB6C" {
            gameEx.eu_gameCode = "AAB6B"
        }
        return gameEx
    }
    func euGameToNil(game: GameListInfo) -> GameListInfo{
        var gameEx = game
        gameEx.eu_gameTitle = nil
        gameEx.eu_gameCode = nil
        gameEx.eu_gameImage = nil
        gameEx.eu_gameID = nil
        gameEx.eu_gameReleaseDate = nil
        return gameEx
    }
    //更新Game表
    func updateGameFavourite(gameCode: String, favourite: Bool){
        if openDatabase(){
            let query = "update \(field_Game_gameTable) set favourite=? where us_gamecode=? or eu_gamecode=? or jp_gamecode=?"
            do{
                try database.executeUpdate(query, values: [favourite,gameCode,gameCode,gameCode])
            }catch{
                print(error.localizedDescription)
            }
            database.close()
        }
    }
    //讀取每款遊戲各國的價錢
    func loadGameIDCountryPrice(gameID: Array<String>, countryID: String, completion: @escaping (_ result: Bool,_ countryPriceList: [[String: Any]]) -> Void){
        var gameIDSting = ""
        for id in gameID{
            gameIDSting += "\(id),"
        }
        //獲取各國遊戲的價錢
        let urlUS = URL(string: "https://api.ec.nintendo.com/v1/price?country=\(countryID)&lang=en&ids=\(gameIDSting)")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            if error == nil{
                let responseStatus = response as! HTTPURLResponse
                if responseStatus.statusCode == 200{
                    if let dataDic = try? (JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]) {
                        let countryPrice = dataDic["prices"] as! [[String:Any]]
                        completion(true,countryPrice)
                    }
                    else{
                        let countryPrice = [[String: Any]]()
                        completion(false,countryPrice)
                    }
                }
            }else{
                print("<=== HTTP Load Fail ===>")
                print(error?.localizedDescription as Any)
            }
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    //取得即時匯率
    func exchangeRateList(completion: @escaping(_ result: Bool,_ rateList: [String:Any]) -> Void){
        //即時匯率api
        let urlUS = URL(string: "https://tw.rter.info/capi.php")
        //設定委任對象為自己
        let session = URLSession.shared
        //設定下載網址
        let dataTask = session.dataTask(with: urlUS!, completionHandler: {(data, response, error) in
            if error == nil{
                let responseStatus = response as! HTTPURLResponse
                if responseStatus.statusCode == 200{
                    if let dataDic = try? (JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]) {
                        DispatchQueue.main.async {
                            completion(true,dataDic)
                        }
                    }
                    else{
                        let dataDic = [String:Any]()
                        completion(false, dataDic)
                    }
                }
            }else{
                print("<=== HTTP Load Fail ===>")
                print(error?.localizedDescription as Any)
            }
        })
        //啟動或重新啟動下載動作
        dataTask.resume()
    }
    //處理漆彈大作戰2的資料
    func spatoonUpdateData(){
        if openDatabase(){
            let querySpatoon2 = "update \(field_EU_gameTable) set \(field_gameEU_product_code_txt)='AAB6B' where \(field_gameEU_product_code_txt)='AAB6C';update \(field_JP_gameTable) set \(field_gameJP_initial_code)='AAB6B' where \(field_gameJP_initial_code)='AAB6A';"
            
            database.executeStatements(querySpatoon2)
            
            database.close()
        }
        
    }
    //重新讀取資料庫
    func reloadDatabase(){
        updateGameUSDatabase()
        updateGameEUDatabase()
        updateGameJPDatabase()
    }
    //刪除彙整的遊戲清單
    func deleteGameList(){
        if openDatabase(){
            let query = "drop table \(field_TempGame_gameTable);drop table \(field_Game_gameTable)"
            database.executeStatements(query)

            database.close()
        }
    }
    //彙整遊戲清單
    func createGameList(){
        if openDatabase(){
            let queryTempGame = "create table \(field_TempGame_gameTable) AS " +
                 "SELECT \(field_US_gameTable).\(field_gameUS_gameTitle) AS us_title, " +
                        "\(field_EU_gameTable).\(field_gameEU_title) AS eu_title, " +
                        "\(field_US_gameTable).\(field_gameUS_gameID) AS us_nsuid, " +
                        "\(field_EU_gameTable).\(field_gameEU_nsuid_txt) AS eu_nsuid, " +
                        "\(field_US_gameTable).\(field_gameUS_gameCode) AS us_gamecode, " +
                        "\(field_EU_gameTable).\(field_gameEU_product_code_txt) AS eu_gamecode, " +
                        "\(field_US_gameTable).\(field_gameUS_releaseDate) AS us_releasedate, " +
                        "\(field_EU_gameTable).\(field_gameEU_dates_released_dts) AS eu_releasedate, " +
                        "\(field_US_gameTable).\(field_gameUS_gameImage) AS us_gameimage, " +
                        "\(field_EU_gameTable).\(field_gameEU_image_url) AS eu_gameimage, " +
                        "\(field_US_gameTable).\(field_gameUS_category) AS us_category, " +
                        "\(field_EU_gameTable).\(field_gameEU_category) AS eu_category, " +
                        "\(field_US_gameTable).\(field_gameUS_url) AS us_url, " +
                        "\(field_EU_gameTable).\(field_gameEU_url) AS eu_url, " +
                        "\(field_US_gameTable).\(field_gameUS_players) AS us_players, " +
                        "\(field_EU_gameTable).\(field_gameEU_players) AS eu_players, " +
                        "\(field_EU_gameTable).\(field_gameEU_language) AS eu_language, " +
                        "\(field_EU_gameTable).\(field_gameEU_excerpt) AS eu_excerpt " +
                 "FROM \(field_EU_gameTable) LEFT OUTER JOIN \(field_US_gameTable) ON " +
                        "\(field_US_gameTable).\(field_gameUS_gameCode) = \(field_EU_gameTable).\(field_gameEU_product_code_txt) " +
                 "UNION " +
                 "SELECT \(field_US_gameTable).\(field_gameUS_gameTitle) AS us_title, " +
                        "\(field_EU_gameTable).\(field_gameEU_title) AS eu_title, " +
                        "\(field_US_gameTable).\(field_gameUS_gameID) AS us_nsuid, " +
                        "\(field_EU_gameTable).\(field_gameEU_nsuid_txt) AS eu_nsuid, " +
                        "\(field_US_gameTable).\(field_gameUS_gameCode) AS us_gamecode, " +
                        "\(field_EU_gameTable).\(field_gameEU_product_code_txt) AS eu_gamecode, " +
                        "\(field_US_gameTable).\(field_gameUS_releaseDate) AS us_releasedate, " +
                        "\(field_EU_gameTable).\(field_gameEU_dates_released_dts) AS eu_releasedate, " +
                        "\(field_US_gameTable).\(field_gameUS_gameImage) AS us_gameimage, " +
                        "\(field_EU_gameTable).\(field_gameEU_image_url) AS eu_gameimage, " +
                        "\(field_US_gameTable).\(field_gameUS_category) AS us_category, " +
                        "\(field_EU_gameTable).\(field_gameEU_category) AS eu_category, " +
                        "\(field_US_gameTable).\(field_gameUS_url) AS us_url, " +
                        "\(field_EU_gameTable).\(field_gameEU_url) AS eu_url, " +
                        "\(field_US_gameTable).\(field_gameUS_players) AS us_players, " +
                        "\(field_EU_gameTable).\(field_gameEU_players) AS eu_players, " +
                        "\(field_EU_gameTable).\(field_gameEU_language) AS eu_language, " +
                        "\(field_EU_gameTable).\(field_gameEU_excerpt) AS eu_excerpt " +
                 "FROM \(field_US_gameTable) LEFT OUTER JOIN \(field_EU_gameTable) ON " +
                        "\(field_US_gameTable).\(field_gameUS_gameCode) = \(field_EU_gameTable).\(field_gameEU_product_code_txt)"
            let queryGame = "create table \(field_Game_gameTable) AS " +
                 "SELECT " +
                        "us_title, " +
                        "eu_title, " +
                        "\(field_JP_gameTable).\(field_gameJP_title_name) AS jp_title, " +
                        "us_gamecode, " +
                        "eu_gamecode, " +
                        "\(field_JP_gameTable).\(field_gameJP_initial_code) AS jp_gamecode, " +
                        "us_nsuid, eu_nsuid, \(field_JP_gameTable).\(field_gameJP_nsuid) AS jp_nsuid, " +
                        "us_releasedate, " +
                        "eu_releasedate, " +
                        "\(field_JP_gameTable).\(field_gameJP_sales_date) AS jp_releasedate, " +
                        "us_gameimage, " +
                        "eu_gameimage, " +
                        "\(field_JP_gameTable).\(field_gameJP_screenshot_img_url) AS jp_gameimage, " +
                        "us_category, " +
                        "eu_category, " +
                        "us_url, " +
                        "eu_url, " +
                        "\(field_JP_gameTable).\(field_gameJP_url) AS jp_url, " +
                        "us_players, " +
                        "eu_players, " +
                        "eu_language, " +
                        "eu_excerpt " +
                 "FROM \(field_TempGame_gameTable) LEFT OUTER JOIN \(field_JP_gameTable) ON " +
                        "\(field_TempGame_gameTable).us_gamecode = \(field_JP_gameTable).\(field_gameJP_initial_code) " +
                 "UNION " +
                 "SELECT " +
                        "us_title, " +
                        "eu_title, " +
                        "\(field_JP_gameTable).\(field_gameJP_title_name) AS jp_title, " +
                        "us_gamecode, " +
                        "eu_gamecode, " +
                        "\(field_JP_gameTable).\(field_gameJP_initial_code) AS jp_gamecode, " +
                        "us_nsuid, eu_nsuid, \(field_JP_gameTable).\(field_gameJP_nsuid) AS jp_nsuid, " +
                        "us_releasedate, " +
                        "eu_releasedate, " +
                        "\(field_JP_gameTable).\(field_gameJP_sales_date) AS jp_releasedate, " +
                        "us_gameimage, " +
                        "eu_gameimage, " +
                        "\(field_JP_gameTable).\(field_gameJP_screenshot_img_url) AS jp_gameimage, " +
                        "us_category, " +
                        "eu_category, " +
                        "us_url, " +
                        "eu_url, " +
                        "\(field_JP_gameTable).\(field_gameJP_url) AS jp_url, " +
                        "us_players, " +
                        "eu_players, " +
                        "eu_language, " +
                        "eu_excerpt " +
                 "FROM \(field_JP_gameTable) LEFT OUTER JOIN \(field_TempGame_gameTable) ON " +
                        "\(field_TempGame_gameTable).us_gamecode = \(field_JP_gameTable).\(field_gameJP_initial_code)"
            
            let addGameQuery = "alter table \(field_Game_gameTable) add favourite boolean default 0"

            do{
                try database.executeUpdate(queryTempGame, values: nil)
                try database.executeUpdate(queryGame, values: nil)
                try database.executeUpdate(addGameQuery, values: nil)
                print("Finish.")
            }catch{
                print("Fail.")
                print(error.localizedDescription)
            }
            database.close()
        }else{
            print("Database opened fail.")
        }
        
    }

}
