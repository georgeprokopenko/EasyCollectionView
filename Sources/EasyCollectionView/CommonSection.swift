import Foundation

struct CommonSection {

    let id: String
    var rows: [CommonRowViewModelProtocol]
    let header: CommonRowViewModelProtocol?

    init(id: String, rows: [CommonRowViewModelProtocol], header: CommonRowViewModelProtocol? = nil) {
        self.id = id
        self.rows = rows
        self.header = header
    }

    mutating func replaceRows(with newRows: [CommonRowViewModelProtocol], reuseExisting: Bool) {
        guard reuseExisting else {
            rows = newRows
            return
        }

        let existingRows: [String: CommonRowViewModelProtocol] = rows.mapToDict { ($0.rowId, $0) }
        rows = newRows.map { existingRows[$0.rowId] ?? $0 }
    }
}

extension CommonSection: Collection {

    typealias Index = Int
    typealias Element = CommonRowViewModelProtocol

    subscript(position: Index) -> Element {
        return rows[position]
    }

    func index(after i: Index) -> Index {
        return rows.index(after: i)
    }

    var startIndex: Index {
        return rows.startIndex
    }

    var endIndex: Index {
        return rows.endIndex
    }
}
