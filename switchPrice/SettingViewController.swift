//
//  SettingViewController.swift
//  switchPrice
//
//  Created by YuKai on 2019/4/16.
//  Copyright © 2019 yukai. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var gameFavourite = [GameListInfo]()
    let settingItemTitle = ["UpdateGameData", "ChangeCurrency"]
    let settingItemImage = ["update.png","currency.png"]
    
    
    @IBOutlet weak var viewBackGround: UIView!
    @IBOutlet weak var indicatorViewBackGround: UIView!
    @IBOutlet weak var myIndicatorLabel: UILabel!
    @IBOutlet weak var myIndicator: UIActivityIndicatorView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingItemTitle.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! SettingTableViewCell
        cell.settingTitleLabel.text = settingItemTitle[indexPath.row]
        cell.settingDescriptionLabel.text = " "
        cell.settingImage.image = UIImage(named: settingItemImage[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let alert = UIAlertController(title: "Update Games", message: "Do you want to update the data?", preferredStyle: .alert)
            let actionYes = UIAlertAction(title: "Yes", style: .default) { (UIAlertAction) in
                self.updateGamesData()
            }
            let actionNo = UIAlertAction(title: "No", style: .destructive, handler: nil)
            
            alert.addAction(actionYes)
            alert.addAction(actionNo)
            present(alert, animated: true, completion: nil)
        }else if indexPath.row == 1{
            let viewController = AlertViewController()
            let alertController = UIAlertController(title: "Currency", message: "Select one", preferredStyle: .alert)
            alertController.setValue(viewController, forKey: "contentViewController")
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    //重新讀取資料庫
    func updateGamesData(){
        //讀取條開啟
        myIndicatorAction(isOpen: true)
        DBManager.shared.isUpdate = false
        DBManager.shared.isGameUSCheck = false
        DBManager.shared.isGameEUCheck = false
        DBManager.shared.isGameJPCheck = false
        DBManager.shared.reloadDatabase()
    }
    

    @IBOutlet weak var settingTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.settingTableView.tableFooterView = UIView()
        //建立通知事件-更新收藏清單到資料庫
        NotificationCenter.default.addObserver(self, selector: #selector(updateFavourite(notification:)), name: NSNotification.Name("UpdateFavourite") , object: nil)
        //建立通知事件-更新讀取條文字
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabel(notification:)), name: NSNotification.Name("UpdateLabel") , object: nil)
        //建立通知事件-更換貨幣完成訊息
        NotificationCenter.default.addObserver(self, selector: #selector(changeCurrencyAlert(notification:)), name: NSNotification.Name("ChangeCurrencyAlert") , object: nil)
        //讀取條關閉
        myIndicatorAction(isOpen: false)
        // Do any additional setup after loading the view.
    }
    //通知事件-更換貨幣完成訊息
    @objc func changeCurrencyAlert(notification: NSNotification) {
        let alert = UIAlertController(title: "Currency", message: "Change success.", preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(actionOK)
        present(alert, animated: true, completion: nil)
    }
    //通知事件-更新讀取條文字
    @objc func updateLabel(notification: NSNotification) {
        DispatchQueue.main.async {
            self.myIndicatorLabel.text = "Downloading..."
        }
    }
    //通知事件-更新收藏清單到資料庫
    @objc func updateFavourite(notification: NSNotification) {
        for game in gameFavourite{
            DBManager.shared.updateGameFavourite(gameCode: HomeViewController.shared.getGameCode(game: game), favourite: game.favourite)
        }
        //啟用通知事件-重新讀取遊戲清單
        NotificationCenter.default.post(name: Notification.Name("RELOAD"), object: nil)
        //讀取條關閉
        myIndicatorAction(isOpen: false)
        DispatchQueue.main.async {
            if self.myIndicatorLabel.text == "Checking..."{
                let alert = UIAlertController(title: "Data", message: "Data is new, don't need to update.", preferredStyle: .alert)
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(actionOK)
                self.present(alert, animated: true, completion: nil)
            }else{
                let alert = UIAlertController(title: "Data", message: "Data updated finish.", preferredStyle: .alert)
                let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(actionOK)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    //讀取條
    func myIndicatorAction(isOpen: Bool){
        DispatchQueue.main.async {
            self.viewBackGround.isHidden = !isOpen
            self.indicatorViewBackGround.isHidden = !isOpen
            self.myIndicatorLabel.isHidden = !isOpen
            self.myIndicator.isHidden = !isOpen
            if isOpen{
                self.myIndicatorLabel.text = "Checking..."
                self.myIndicator.startAnimating()
            }else{
                self.myIndicator.stopAnimating()
            }
        }
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
