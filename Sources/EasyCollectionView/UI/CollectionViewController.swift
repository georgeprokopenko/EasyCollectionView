import UIKit
import Differ

public protocol CollectionViewControllerProtocol: AnyObject {
    func reloadCollectionView(with rows: [CommonRowViewModelProtocol], animated: Bool)
}

public protocol CollectionViewController: AnyObject {
    var collectionView: UICollectionView! { get }
    var dataSource: CommonCollectionViewDataSource { get }
}

extension CollectionViewController {

    public func reloadCollectionView(with rows: [CommonRowViewModelProtocol], animated: Bool) {
        reloadCollectionView(with: rows, animated: animated, completion: nil)
    }

    public func reloadCollectionView(
        with rows: [CommonRowViewModelProtocol],
        animated: Bool,
        customRowHeightDidChangeHandler: (() -> Void)? = nil, completion: ((Bool) -> Void)?
    ) {
        let resultCompletion: ((Bool) -> Void) = { [weak self] finished in
            if let self, finished {
                self.dataSource.rebindVisibleCellsIfNeeded(for: self.collectionView)
            }
            completion?(finished)
        }

        if animated {
            collectionView.animateItemChanges(
                oldData: dataSource.rows.map { $0.rowId },
                newData: rows.map { $0.rowId },
                updateData: {
                    dataSource.rows = rows
                    registerDataSourceRowsHeightDidChange(customRowHeightDidChangeHandler: customRowHeightDidChangeHandler)
                },
                completion: resultCompletion
            )
        } else {
            dataSource.rows = rows
            registerDataSourceRowsHeightDidChange(customRowHeightDidChangeHandler: customRowHeightDidChangeHandler)
            collectionView.reloadData()
            resultCompletion(true)
        }
    }

    func registerDataSourceRowsHeightDidChange(customRowHeightDidChangeHandler: (() -> Void)?) {
        dataSource.sections.forEach {
            $0.forEach {
                guard let setHandler = $0.setHeightDidUpdateHandler else {
                    return
                }

                setHandler { [weak self] in
                    if let customRowHeightDidChangeHandler = customRowHeightDidChangeHandler {
                        customRowHeightDidChangeHandler()
                    } else {
                        self?.updateCollectionViewRowSizes()
                    }
                }
            }
        }
    }

    func updateCollectionViewRowSizes() {
        collectionView.performBatchUpdates(nil, completion: nil)
    }
}
