import Foundation
import RxSwift
import RxCocoa

class  TeamInfoRegistViewController: UIViewController {
    
    private var viewModel: TeamInfoRegistViewModel!
    
    private lazy var ui: TeamInfoRegistUI = {
        let ui = TeamInfoRegistUIImpl()
        ui.viewController = self
        return ui
    }()
    
    private lazy var routing: TeamInfoRegistRouting = {
        let routing = TeamInfoRegistRoutingImpl()
        routing.viewController = self
        return routing
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ui.setup(storeName: R.string.locarizable.team_info_title())
        viewModel = TeamInfoRegistViewModel(teamField: ui.teamNameField.rx.text.orEmpty.asDriver(),
                                            gradeField: ui.gradeField.rx.text.orEmpty.asDriver(),
                                            sportsKindField: ui.sportsKindField.rx.text.orEmpty.asDriver())
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ui.setupToolBar(ui.gradeField,
                        type: .grade,
                        toolBar: ui.gradeToolBar,
                        content: viewModel?.outputs.gradeArr.value ?? [R.string.locarizable.empty()],
                        vc: self)
        ui.setupToolBar(ui.sportsKindField,
                        type: .sports,
                        toolBar: ui.sportsKindToolBar,
                        content: viewModel?.outputs.sportsKindArr.value ?? [R.string.locarizable.empty()],
                        vc: self)
    }
}

extension TeamInfoRegistViewController {
    
    private func setupViewModel() {
        viewModel?.outputs.isNextBtnEnable
            .distinctUntilChanged()
            .asObservable()
            .subscribe(onNext: { [weak self] isValid in
                isValid ? self?.ui.nextBtn.setupAnimation() : self?.ui.nextBtn.teardownAnimation()
            }).disposed(by: viewModel.disposeBag)
        
        viewModel.outputs.isOverTeamField
            .distinctUntilChanged() 
            .subscribe(onNext: { bool in
                if bool {
                    self.ui.teamNameField.backgroundColor = AppResources.ColorResources.appCommonClearOrangeColor
                    AlertController.showAlertMessage(alertType: .overChar, viewController: self)
                } else {
                    self.ui.teamNameField.backgroundColor = .white
                }
            }).disposed(by: viewModel.disposeBag)
        
        ui.nextBtn.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.ui.nextBtn.bounce()
            }).disposed(by: viewModel.disposeBag)

        ui.nextBtn.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] _ in
                self?.viewModel?.saveToSingleton(team: self?.ui.teamNameField.text ?? "",
                                                 grade: self?.ui.gradeField.text ?? "",
                                                 sportsKind: self?.ui.sportsKindField.text ?? "")
                self?.routing.RepresentMemberRegister()
            }).disposed(by: viewModel.disposeBag)
        
        ui.gradeDoneBtn.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .bind { [weak self] _ in
                if let _ = self?.ui.gradeField.isFirstResponder {
                    self?.ui.gradeField.resignFirstResponder()
                }
            }.disposed(by: viewModel.disposeBag)
        
        ui.sportsKindDoneBtn.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .bind { [weak self] _ in
                if let _ = self?.ui.sportsKindField.isFirstResponder {
                    self?.ui.sportsKindField.resignFirstResponder()
                }
            }.disposed(by: viewModel.disposeBag)
        
        ui.teamNameField.rx.controlEvent(.editingDidEndOnExit)
            .bind { [weak self] _ in
                self?.ui.teamNameField.resignFirstResponder()
            }.disposed(by: viewModel.disposeBag)
        
        ui.viewTapGesture.rx.event
            .bind { [weak self] _ in
                self?.view.endEditing(true)
            }.disposed(by: viewModel.disposeBag)
    }
}

extension TeamInfoRegistViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return TeamInfoRegisterResources.View.pickerNumberOfComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case is GradePickerView: return viewModel?.outputs.gradeArr.value.count ?? 0
        case is SportsKindPickerView: return viewModel?.outputs.sportsKindArr.value.count ?? 0
        default: return 0
        }
    }
}

extension TeamInfoRegistViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case is GradePickerView: return viewModel?.outputs.gradeArr.value[row] ?? R.string.locarizable.empty()
        case is SportsKindPickerView: return viewModel?.outputs.sportsKindArr.value[row] ?? R.string.locarizable.empty()
        default: return Optional<String>("")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case is GradePickerView: ui.gradeField.text = viewModel?.outputs.gradeArr.value[row]
        case is SportsKindPickerView: ui.sportsKindField.text = viewModel?.outputs.sportsKindArr.value[row]
        default: break
        }
    }
}
