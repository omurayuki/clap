import UIKit
import RxSwift
import RxCocoa
import Firebase

class TimeLineViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private var isSelected = false
    var timelineCellArray = [TimelineCellData]()
    var dataTitleFromFireStore = [String]()
    var dataDateFromFiewstore = [String]()
    
    private lazy var ui: TimeLineUI = {
        let ui = TimeLineUIImpl()
        ui.viewController = self
        ui.timelineTableView.register(TimelineCell.self, forCellReuseIdentifier: String(describing: TimelineCell.self))
        ui.timelineTableView.dataSource = self
        ui.timelineTableView.delegate = self
        return ui
    }()
    
    private lazy var routing: TimeLineRouting = {
        let routing = TimeLineRoutingImpl2()
        routing.viewController = self
        return routing
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ui.setup(vc: self)
        hiddenBtn()
        setupViewModel()
        Firebase.db
            .collection("diary")
            .document(AppUserDefaults.getValue(keyName: "teamId"))
            .collection("diaries")
            .whereField("submit", isEqualTo: true)
            .getDocuments { [weak self] (snapshot, error) in
            if let _ = error { return }
            guard let snapshot = snapshot else { return }
            var i = 0
            for document in snapshot.documents {
                var data = document.data()
                self?.dataTitleFromFireStore.append(data["text_1"] as? String ?? "")
                self?.dataDateFromFiewstore.append(data["date"] as? String ?? "")
                self?.timelineCellArray.append(TimelineCellData(date: DateOperator.parseDate(self?.dataDateFromFiewstore[i] ?? ""),
                                                                time: "21:00",
                                                                title: self?.dataTitleFromFireStore[i],
                                                                name: "亀太郎",
                                                                image: URL(string: ""),
                                                                diaryID: ""))
                i += 1
                TimelineSingleton.sharedInstance.sections = TableSection.group(rowItems: self?.timelineCellArray ?? [TimelineCellData](), by: { headline in
                    DateOperator.firstDayOfMonth(date: headline.date ?? Date())
                })
            }
               self?.ui.timelineTableView.reloadData()
        }
    }
}

extension TimeLineViewController {
    
    private func setupViewModel() {
        ui.menuBtn.rx.tap
            .bind(onNext: { [weak self] _ in
                self?.ui.menuBtn.bounce(completion: {
                    self?.selectedTargetMenu()
                })
            }).disposed(by: disposeBag)
        
        ui.memberBtn.rx.tap
            .bind(onNext: { [weak self] _ in
                self?.ui.memberBtn.bounce(completion: {
                    guard let this = self else { return }
                    this.selectedTargetMenu()
                    this.routing.showDiaryGroup()
                })
            }).disposed(by: disposeBag)
        
        ui.diaryBtn.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.ui.diaryBtn.bounce(completion: {
                    guard let this = self else { return }
                    this.selectedTargetMenu()
                    this.routing.showDiaryRegist()
                })
            }).disposed(by: disposeBag)
    }
    
    private func selectedTargetMenu() {
        if isSelected {
            UIView.animate(withDuration: 0.7,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.7,
                           options: .curveEaseOut,
                           animations: {
                self.ui.hiddenBtnPosition(vc: self)
                self.hiddenBtn()
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.7,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.7,
                           options: .curveEaseOut,
                           animations: {
                self.ui.showBtnPosition(vc: self)
                self.showBtn()
                self.view.layoutIfNeeded()
            })
        }
        isSelected = !isSelected
    }
    
    private func showBtn() {
        ui.memberBtn.alpha = 1
        ui.diaryBtn.alpha = 1
    }
    
    private func hiddenBtn() {
        ui.memberBtn.alpha = 0
        ui.diaryBtn.alpha = 0
    }
}

extension TimeLineViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return TimelineSingleton.sharedInstance.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = TimelineSingleton.sharedInstance.sections[section].sectionItem
        return DateFormatter().convertToMonthAndYears(date)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TimelineSingleton.sharedInstance.sections[section].rowItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineCell.self), for: indexPath) as? TimelineCell else { return UITableViewCell() }
        let cellDetail = TimelineSingleton.sharedInstance.sections[indexPath.section].rowItems[indexPath.row]
        cell.configureInit(image: "cellDetail.image", title: cellDetail.title ?? "", name: cellDetail.name ?? "", time: cellDetail.time ?? "")
        return cell
    }
}

extension TimeLineViewController: UITableViewDelegate {
    
}
