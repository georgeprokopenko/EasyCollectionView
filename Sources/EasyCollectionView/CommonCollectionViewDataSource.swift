import Foundation
import UIKit

final public class CommonCollectionViewDataSource: NSObject, UICollectionViewDataSource {

    private var registeredCellNibNames = Set<String>()
    private var registeredClassNames = Set<String>()

    init(fillEmptySection: Bool = false) {
        super.init()

        if fillEmptySection {
            rows = []
        }
    }

    var sections = [CommonSection]()

    var rows: [CommonRowViewModelProtocol] {
        get {
            sections.first?.rows ?? []
        }
        set {
            sections = [CommonSection(id: "0", rows: newValue)]
        }
    }

    private var registeredSupplementaryCellNibNames = Set<String>()
    private var registeredSupplementaryClassNames = Set<String>()

    struct SupplementaryRowKey: Hashable {
        var kind: String
        var indexPath: IndexPath

        init(kind: String, indexPath: IndexPath) {
            self.kind = kind
            self.indexPath = indexPath
        }
    }

    var supplementaryRows = [SupplementaryRowKey: CommonRowViewModelProtocol]()

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        if let nibName = row.nibName, !registeredCellNibNames.contains(nibName) {
            let nib = UINib(nibName: nibName, bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: nibName)
            registeredCellNibNames.insert(nibName)

        } else if let cellClass = row.cellClass, !registeredClassNames.contains(NSStringFromClass(cellClass)) {
            collectionView.register(cellClass, forCellWithReuseIdentifier: NSStringFromClass(cellClass))
            registeredClassNames.insert(NSStringFromClass(cellClass))
        }

        let identifier: String
        if let nibName = row.nibName {
            identifier = nibName
        } else if let cellClass = row.cellClass {
            identifier = NSStringFromClass(cellClass)
        } else {
            fatalError()
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        row.configure(cell)

        return cell
    }

    func rebindVisibleCellsIfNeeded(for collectionView: UICollectionView) {
        collectionView.indexPathsForVisibleItems
            .compactMap { indexPath in collectionView.cellForItem(at: indexPath).flatMap { (indexPath, $0) } }
            .forEach {
                itemForIndexPath($0.0)?.rebind?($0.1)
            }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let key = SupplementaryRowKey(kind: kind, indexPath: indexPath)
        guard let row = supplementaryRows[key] else {
            fatalError()
        }

        if let nibName = row.nibName, !registeredSupplementaryCellNibNames.contains(nibName) {
            let nib = UINib(nibName: nibName, bundle: nil)
            collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: nibName)
            registeredSupplementaryCellNibNames.insert(nibName)

        } else if let cellClass = row.cellClass, !registeredSupplementaryClassNames.contains(NSStringFromClass(cellClass)) {
            collectionView.register(cellClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: NSStringFromClass(cellClass))
            registeredSupplementaryClassNames.insert(NSStringFromClass(cellClass))
        }

        let identifier: String
        if let nibName = row.nibName {
            identifier = nibName
        } else if let cellClass = row.cellClass {
            identifier = NSStringFromClass(cellClass)
        } else {
            fatalError()
        }

        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
        row.configure(cell)

        return cell
    }

    func itemForIndexPath(_ indexPath: IndexPath) -> CommonRowViewModelProtocol? {
        sections[safe: indexPath.section]?.rows[safe: indexPath.item]
    }

    subscript(indexPath: IndexPath) -> CommonRowViewModelProtocol {
        sections[indexPath.section][indexPath.row]
    }
}
