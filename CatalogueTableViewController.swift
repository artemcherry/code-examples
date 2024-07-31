//
//  CatalogueTableViewController.swift
//  MySubsidies-Prod
//
//  Created by Artem Vishniakov on 16.01.2024.
//

import UIKit

struct CatalogueModuleFactory {
    let makeESIAAuthModule: (() -> UIViewController)
    let makeSubcategoriesModule: (_ categoryId: Int?, _ title: String) -> UIViewController
    let makeSubsidyDetailModule: (
        _ subsidyId: Int,
        _ canApplySubsidy: Bool,
        _ isPushedFromDeeplink: Bool
    ) -> UIViewController
    let makeCategoriesModule: () -> UIViewController
    let makeCategoriesSearchModule: (_ tag: GrantsFilterOptionModel) -> UIViewController
}

class CatalogueTableViewController: TableProviderViewController {
    private enum Constants {
        static let listElementViewModelCount: Int = 14
    }
    
    struct Appearance: Grid {
        let shadowOffset = CGSize(width: .zero, height: 4)
        let shadowOpacity: Float = 0.1
        let shadowRadius: CGFloat = 27
    }
    
    // MARK: Instance Properties

    private let presenter: CataloguePresenter
    private let modulesFactory: CatalogueModuleFactory
    private let tableAdapter: CatalogueTableAdapter
    private let keychainService: KeychainService = dependencyContainer.services.keychainService
    private var activePressingEffectView: UIView?
    private var deeplinkPushType: DeeplinkPushType = .none

    private var bottomView = CatalogueBottomView.loadFromNib()
    private let appearance = Appearance()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
        
    init(presenter: CataloguePresenter,
         modulesFactory: CatalogueModuleFactory,
         tableAdapter: CatalogueTableAdapter,
         deeplinkPushType: DeeplinkPushType) {
        self.presenter = presenter
        self.modulesFactory = modulesFactory
        self.tableAdapter = tableAdapter
        self.deeplinkPushType = deeplinkPushType
        super.init(style: .grouped)
        self.tableAdapter.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.delegate = self
        setupTableView()
        setupBottomView()
        presenter.attachView(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        update(TableContentModel(getSkeletonGrants()))

        setupNavigationBar()
        presenter.loadSubsidies()
        
        self.bottomView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch deeplinkPushType {
        case .catalog:
            return
        case let .subsidyDetail(grantId):
            let detailSubsidyModule = modulesFactory.makeSubsidyDetailModule(grantId, true, true)
            navigationController?.pushViewController(detailSubsidyModule, animated: true)
            deeplinkPushType = .none
            dependencyContainer.modules.setDeeplinkPushType(.none)
        case .none:
            return
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(bottomView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if navigationController?.viewControllers.count ?? 0 < 2 {
            
            UIView.animate(withDuration: 0.5) {
                self.bottomView.transform = CGAffineTransform(translationX: 0, y: 150)
            }
            
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.7) { [weak self] in
                self?.bottomView.removeFromSuperview()
            }
        }
    }
    
    private func setupTableView() {
        tableView.isSkeletonable = true
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: .leastNormalMagnitude))
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
    }
    
    private func setupBottomView() {
        bottomView.layer.shadowColor = UIColor.black.cgColor
        bottomView.layer.shadowOpacity = appearance.shadowOpacity
        bottomView.layer.shadowOffset = appearance.shadowOffset
        bottomView.layer.shadowRadius = appearance.shadowRadius
        
        bottomView.setupData(types: [.resume], descriptionText: "123")
        
        self.navigationController?.view.addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview()
        }
    }

    func setupNavigationBar() {
        navigationController?.setTransparentNavigationBar()
        navigationController?.removeNavigationBarShadow()
        navigationController?.setCustomBackButtonImage(Assets.Images.arrowBottomBlack.image)
        removeBackButtonTitle()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .never
    }

    func updateData() {
        presenter.loadSubsidies()
    }
    
    override func handleRefresh() {
        super.handleRefresh()
        presenter.loadSubsidies()
    }
}

extension CatalogueTableViewController: CatalogueView {
  
    func show(info: CatalogueInfoHeaderViewModel,
              popular: [SubsidyPopularViewModel],
              openDate: [SubsidyWithOpenDateViewModel],
              categories: [ListElementViewModel]) {
        if let activePressingEffectView = self.activePressingEffectView {
            activePressingEffectView.removeFromSuperview()
            self.activePressingEffectView = nil
        }
        var sections = [TableSectionModel]()

        sections.append(tableAdapter.createTopSection(false, viewModel: info))        
        sections.append(tableAdapter.createPopularSection(false, popular: popular))
        sections.append(tableAdapter.createOpenDateSection(false, openDate: openDate))
        sections.append(tableAdapter.createCategoriesSection(false, categories: categories))

        update(TableContentModel(sections))
    }

    func showDynamicForm(for requestId: Int) {
//        let dynamicFormModule = modulesFactory.makeDynamicFormModule(requestId)
//        navigationController?.pushViewController(dynamicFormModule, animated: true)
    }
}

extension CatalogueTableViewController: CatalogueTableAdapterDelegate {
    
    func popularSelected(_ viewModel: SubsidyPopularViewModel) {
        let detailSubsidyModule = modulesFactory.makeSubsidyDetailModule(
            viewModel.subsidyId,
            true,
            false
        )
        navigationController?.pushViewController(detailSubsidyModule, animated: true)
    }
    
    func openDateSelected(_ viewModel: SubsidyWithOpenDateViewModel) {
        let detailSubsidyModule = modulesFactory.makeSubsidyDetailModule(
            viewModel.subsidyId,
            true,
            false
        )
        navigationController?.pushViewController(detailSubsidyModule, animated: true)
    }
    
    func categorySelected(_ viewModel: ListElementViewModel) {
        let subcategoriesModule = modulesFactory.makeSubcategoriesModule(viewModel.id, viewModel.name)
        navigationController?.pushViewController(subcategoriesModule, animated: true)
    }
    
    func categoriesAllTapped() {
        let categoriesModule = modulesFactory.makeCategoriesModule()
        navigationController?.pushViewController(categoriesModule, animated: true)
    }
    
    func categoryTagSelected(_ tag: GrantsFilterOptionModel) {
        let categoriesSearchModule = modulesFactory.makeCategoriesSearchModule(tag)
        navigationController?.pushViewController(categoriesSearchModule, animated: true)
    }

    func viewTouchesBeganAction(_ view: UIView?) {
        activePressingEffectView = view
    }
}

extension CatalogueTableViewController {
    func getSkeletonGrants() -> [TableSectionModel] {
        return [
            tableAdapter.createTopSection(
                true,
                viewModel: SkeletonMockGenerator.createCatalogueTopSectionMock()
            ),
            tableAdapter.createPopularSection(
                true,
                popular: SkeletonMockGenerator.createPopularSectionMock(count: 3)),
            tableAdapter.createOpenDateSection(
                true,
                openDate: SkeletonMockGenerator.createOpenDateSectionMock(count: 3))]
    }
}

extension CatalogueTableViewController: CatalogueBottomViewDelegate {
    
    func loginButtonTapped() {
        let esiaModule = self.modulesFactory.makeESIAAuthModule()
        self.navigationController?.pushViewController(esiaModule,
                                                      animated: true)
        self.bottomView.isHidden = true
    }
}
