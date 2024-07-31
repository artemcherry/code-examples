//
//  CatalogueTableAdapter.swift
//  MySubsidies-Prod
//
//  Created by Artem Vishniakov on 16.01.2024.
//

import UIKit

protocol CatalogueTableAdapterDelegate: AnyObject {
   
    func popularSelected(_ viewModel: SubsidyPopularViewModel)
    func openDateSelected( _ viewModel: SubsidyWithOpenDateViewModel)
    func categorySelected(_ viewModel: ListElementViewModel)
    func categoriesAllTapped()
    func categoryTagSelected(_ tag: GrantsFilterOptionModel)
    func viewTouchesBeganAction(_ view: UIView?)
}

protocol CatalogueTableAdapter: AnyObject {
    var delegate: CatalogueTableAdapterDelegate? { get set }

    func createTopSection(_ isSkeletonable: Bool, viewModel: CatalogueInfoHeaderViewModel) -> TableSectionModel
    func createPopularSection(_ isSkeletonable: Bool, popular: [SubsidyPopularViewModel]) -> TableSectionModel
    func createOpenDateSection( _ isSkeletonable: Bool, openDate: [SubsidyWithOpenDateViewModel]) -> TableSectionModel
    func createCategoriesSection(_ isSkeletonable: Bool, categories: [ListElementViewModel]) -> TableSectionModel
}

class CatalogueTableAdapterDefault: CatalogueTableAdapter {
        
    // MARK: Constants

    private enum Constants {
        static let taskCellHeight: CGFloat = 106
        static let taskCellWidth: CGFloat = 345
        static let cellWidth: CGFloat = 220
        static let cellHeight: CGFloat = 236
        static let applicationsCellHeight: CGFloat = 118
        static let headerHeight: CGFloat = 60
        static let cornerRadius: CGFloat = 8
        static let sideInset: CGFloat = 20
        static let applicationsAccessibilityID = "applicationsSectionButton"
        static let favoriteAccessibilityID = "favoriteSectionButton"
        static let recommendationsAccessibilityID = "recommendationsSectionButton"
        static let categoriesAccessibilityID = "categoriesSectionButton"
    }

    weak var delegate: CatalogueTableAdapterDelegate?

    func createTopSection(_ isSkeletonable: Bool, viewModel: CatalogueInfoHeaderViewModel) -> TableSectionModel {
        let topHeader = TableHeaderFooterModel { (header: CatalogueInfoHeaderView, tableView, section) in
            header.configure(with: viewModel, isSkeletonable: isSkeletonable)
            header.isUserInteractionEnabled = isSkeletonable == false
        }
        .set(height: 38)

        return TableSectionModel(header: topHeader, rows: [])
    }

    func createPopularSection(_ isSkeletonable: Bool, popular: [SubsidyPopularViewModel]) -> TableSectionModel {
        let popularSection = TableHeaderFooterModel { (header: MainHeaderView, tableView, section) in
            
            header.configure(isSkeletonable: isSkeletonable,
                             MainHeaderViewModel(title: Text.Catalogue.Section.popularSubsidy,
                                                 actionName: "",
                                                 accessibilityIdentifier: "")) {}
        }
            .set(height: Constants.headerHeight)
        
        let popularRow = TableRowModel { [weak self] (cell: CatalogueCollectionTableViewCell<SubsidyPopularView>, tableView, indexPath) in
            cell.configure(with: popular, isSkeletonable: isSkeletonable ,categoryChipSelectedAction: { [weak self] tags in
                guard let tag = tags.first else {
                    return
                }
                self?.delegate?.categoryTagSelected(tag)
            }, viewTouchesBeganAction: { view in
                self?.delegate?.viewTouchesBeganAction(view)
            })
            cell.itemSize = CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
            cell.itemSelected = { item in
                self?.delegate?.popularSelected(item)
            }
            cell.isUserInteractionEnabled = isSkeletonable == false
        }
        .set(height: Constants.cellHeight)
        .set(fromNib: false)
        
        return TableSectionModel(header: popularSection, rows: [popularRow])
    }
    
    func createOpenDateSection(_ isSkeletonable: Bool, openDate: [SubsidyWithOpenDateViewModel]) -> TableSectionModel {
        let openDateSection = TableHeaderFooterModel { (header: MainHeaderView, tableView, section) in
            
            header.configure(isSkeletonable: isSkeletonable,
                             MainHeaderViewModel(title: Text.Catalogue.Section.openDataSubsidy,
                                                 actionName: "",
                                                 accessibilityIdentifier: "")) {}
        }
            .set(height: Constants.headerHeight)
        
        let openDateRow = TableRowModel { [weak self] (cell: CatalogueCollectionTableViewCell<SubsidyWithOpenDateView>, tableView, indexPath) in
            cell.configure(with: openDate, isSkeletonable: isSkeletonable ,categoryChipSelectedAction: { [weak self] tags in
                guard let tag = tags.first else {
                    return
                }
                self?.delegate?.categoryTagSelected(tag)
            }, viewTouchesBeganAction: { view in
                self?.delegate?.viewTouchesBeganAction(view)
            })
            cell.itemSize = CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
            cell.itemSelected = { item in
                self?.delegate?.openDateSelected(item)
            }
            cell.isUserInteractionEnabled = isSkeletonable == false
        }
        .set(height: Constants.cellHeight)
        .set(fromNib: false)
        
        return TableSectionModel(header: openDateSection, rows: [openDateRow])
    }
    
    func createCategoriesSection(_ isSkeletonable: Bool, categories: [ListElementViewModel]) -> TableSectionModel {
        let categoriesHeader = TableHeaderFooterModel { (header: MainHeaderView, tableView, section) in
            header.configure(
                isSkeletonable: isSkeletonable,
                MainHeaderViewModel(
                    title: Text.Categories.title,
                    actionName: Text.Default.all,
                    accessibilityIdentifier: Constants.categoriesAccessibilityID
                ),
                action: { [weak self] in
                    self?.delegate?.categoriesAllTapped()
                }
            )
            header.isUserInteractionEnabled = isSkeletonable == false
        }
        .set(height: Constants.headerHeight)

        let categoriesRows = categories.map { model in
            TableRowModel { (cell: ListElementTableViewCell, tableView, indexPath) in
                cell.configure(isSkeletonable: false, viewModel: model)
            }
            .onSelect { [weak self] cell, tableView, indexPath in
                if isSkeletonable == false {
                    tableView.deselectRow(at: indexPath, animated: true)
                    self?.delegate?.categorySelected(model)
                }
            }
            .set(height: 44)
        }

        return TableSectionModel(header: categoriesHeader, rows: categoriesRows)
    }
}
