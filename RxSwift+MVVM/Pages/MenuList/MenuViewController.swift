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
import RxRelay

struct Menu {
    
    var id: Int
    var name: String
    var price: Int
    var count: Int
}

// ViewModel로 테스트 케이스를 만들기가 굉장히 수월하다
class MenuListViewModel {
    
    // Relay는 에러가 발생해도 스트림이 종료되지 않는다.
    let menuObservable = BehaviorRelay<[Menu]>(value: [])
    
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
        
        _ = APIService.fetchAllMenusWithRx()
            .map { data in
                
                struct ResponseData: Decodable {
                    
                    var menus: [MenuItem]
                }
                
                guard let decoded = try? JSONDecoder().decode(ResponseData.self, from: data) else {
                    
                    fatalError()
                }
                
                return decoded.menus.enumerated().map { index, item in
                    
                    Menu(id: index, name: item.name, price: item.price, count: 0)
                }
            }
            .take(1)
            .subscribe(onNext: menuObservable.accept)
    }
    
    func clearMenus() {
        
        // 한번 값 수령시 자동 Dispose(take), 호출마다 구독
        _ = menuObservable
            .map { menus in
                menus.map {
                    Menu(id: $0.id, name: $0.name, price: $0.price, count: 0)
                }
            }
            .take(1)
            .subscribe(onNext: { self.menuObservable.accept($0)})
        
    }
    
    func onChange(menu: Menu, increase: Int) {
        
        _ = menuObservable
            .map { menus in
                
                menus.map { m in
                    
                    if m.id == menu.id {
                        
                        return Menu(id: m.id, name: m.name, price: m.price, count: max(m.count+increase, 0))
                    }
                    
                    return m
                }
            }
            .take(1)
            .subscribe(onNext: {
                
                // 값을 변경하고, 자신이 다시 publish하는 패턴, take를 사용해 재귀호출을 막음
                self.menuObservable.accept($0)
            })
    }
}


class MenuViewController: UIViewController {
    
    
    let viewModel = MenuListViewModel()
    
    let disposeBag = DisposeBag()
    
    let cellId = "MenuItemTableViewCell"
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 추후 분석
        viewModel.menuObservable
            .observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: cellId, cellType: MenuItemTableViewCell.self)) { index, item, cell in
                
                cell.title.text = item.name
                cell.price.text = "\(item.price)"
                cell.count.text = "\(item.count)"
                
                cell.onChange = { [weak self] increase in
                    
                    self?.viewModel.onChange(menu: item, increase: increase)
                }
                
            }
            .disposed(by: disposeBag)
        
        viewModel.itemsCount
            .map { String($0) }
//            .observeOn(MainScheduler.instance)
//            .bind(to: self.itemCountLabel.rx.text)
            .asDriver(onErrorJustReturn: "") // 드라이버는 항상 메인에서 동작
            .drive(self.itemCountLabel.rx.text)
//            .subscribe(onNext: {
//                
//                self.itemCountLabel.text = "\($0)"
//            })
            .disposed(by: disposeBag)
        
        viewModel.totalPrice
            .map { $0.currencyKR() }
            .catchErrorJustReturn("") //에러발생시 스트림을 끊지 말고 기본값 리턴
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
        
        viewModel.clearMenus()
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
