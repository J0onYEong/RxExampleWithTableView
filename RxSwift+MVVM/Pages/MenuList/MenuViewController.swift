//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa // RxSwift를 UIKit과 함께 사용하는데 도움을 주는 Extension들

struct Menu {
    
    var name: String
    var price: Int
    var count: Int
}

class MenuListViewModel {
    
    let menuObservable = BehaviorSubject<[Menu]>(value: [])
    
    // lazy 프로파티사용!
    // menuObservable이 publish할 때마다 나머지 값도 업데이트
    // 이러한 처리과정을 Stream이라고 한다.
    
    lazy var itemsCount = menuObservable.map {
        $0.map { $0.count }.reduce(0, +)
    }
    
    lazy var totalPrice = menuObservable.map {
        $0.map { $0.count * $0.price }.reduce(0, +)
    }
    
    init() {
        
        let menus: [Menu] = [
            Menu(name: "메뉴1", price: 1_000, count: 100),
            Menu(name: "메뉴2", price: 2_000, count: 100),
            Menu(name: "메뉴3", price: 3_000, count: 100),
            Menu(name: "메뉴4", price: 4_000, count: 100),
        ]
        
        menuObservable.onNext(menus)
    }
}


class MenuViewController: UIViewController {
    
    
    let viewModel = MenuListViewModel()
    
    let disposeBag = DisposeBag()
    
    let cellId = "MenuItemTableViewCell"
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.menuObservable
            .observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: cellId, cellType: MenuItemTableViewCell.self)) { index, item, cell in
                
                cell.title.text = item.name
                cell.price.text = "\(item.price)"
                cell.count.text = "\(item.count)"
            }
            .disposed(by: disposeBag)
        
        viewModel.itemsCount
            .map { String($0) }
            .observeOn(MainScheduler.instance)
            // RxCocoa사용
            .bind(to: self.itemCountLabel.rx.text)
//            .subscribe(onNext: {
//                
//                self.itemCountLabel.text = "\($0)"
//            })
            .disposed(by: disposeBag)
        
        viewModel.totalPrice
            .map { $0.currencyKR() }
            .observeOn(MainScheduler.instance)
            .bind(to: self.totalPrice.rx.text)
            .disposed(by: disposeBag)
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier ?? ""
        if identifier == "OrderViewController",
            let orderVC = segue.destination as? OrderViewController {
            // TODO: pass selected menus
        }
    }

    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertVC, animated: true, completion: nil)
    }

    // MARK: - InterfaceBuilder Links

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var itemCountLabel: UILabel!
    @IBOutlet var totalPrice: UILabel!

    @IBAction func onClear() {
    }

    @IBAction func onOrder(_ sender: UIButton) {
        // TODO: no selection
        // showAlert("Order Fail", "No Orders")
        
        
//        performSegue(withIdentifier: "OrderViewController", sender: nil)
    }
}

//extension MenuViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.menus.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemTableViewCell") as! MenuItemTableViewCell
//        
//        let menu = viewModel.menus[indexPath.row]
//
//        cell.title.text = menu.name
//        cell.price.text = "\(menu.price)"
//        cell.count.text = "\(menu.count)"
//
//        return cell
//    }
//}
