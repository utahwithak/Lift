//
//  TablePredicateViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/14/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TablePredicateViewController: LiftViewController {

    @IBOutlet weak var predicateEditor: NSPredicateEditor!

    private var rowTemplate: NSPredicateEditorRowTemplate!

    @IBOutlet var columnNameController: NSArrayController!

    override var selectedTable: DataProvider? {
        didSet {
            updateEditor()
        }
    }

    @objc dynamic public private(set) var queryString: String?

    @objc dynamic private var predicate: NSPredicate? {
        didSet {
            if let pred = predicate {
                queryString = convert(pred)
            } else {
                queryString = nil
            }

        }
    }
    private func convert(_ regular: NSPredicate?) -> String? {
        guard let predicate = regular else {
            return nil
        }
        switch predicate {
        case let compound as NSCompoundPredicate:
            return convert(compound)
        case let regular as NSComparisonPredicate:
            return convert(regular)
        default:
            print("Unknown:\(type(of: predicate))")
            return nil
        }

    }

    private func convert( _ comparisonPredicate: NSComparisonPredicate) -> String {
        let constantValue = comparisonPredicate.rightExpression.constantValue ?? ""

        var query = comparisonPredicate.leftExpression.description.querySafeString()

        switch comparisonPredicate.predicateOperatorType {
        case .endsWith:
            return query + " LIKE '%%\(constantValue)'"
        case .contains:
            return query + " LIKE '%\(constantValue)%'"
        case .beginsWith:
            return query + " LIKE '\(constantValue)%%'"
        case .equalTo:
            query += " = "
        case .lessThan:
            query += " < "
        case .lessThanOrEqualTo:
            query += " <= "
        case .greaterThan:
            query += " > "
        case .greaterThanOrEqualTo:
            query += " >= "
        case .notEqualTo:
            query += " != "
        default:
            return comparisonPredicate.description
        }

        if let strVal = constantValue as? String {
            if let intVal = Int(strVal) {
                return query + "\(intVal)"
            } else if let doubVal = Double(strVal) {
                return query + "\(doubVal)"
            }
        }
        return query + comparisonPredicate.rightExpression.description
    }

    private func convert(_ compoundPredicate: NSCompoundPredicate) -> String? {
        guard let subs = compoundPredicate.subpredicates as? [NSPredicate] else {
            return nil
        }

        let subQueries = subs.compactMap { convert($0) }

        guard !subQueries.isEmpty else {
            return nil
        }

        let separator = compoundPredicate.compoundPredicateType == .and ? " AND " : " OR "
        return "(" + subQueries.joined(separator: separator) + ")"

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        predicateEditor.bind(NSBindingName.value, to: self, withKeyPath: #keyPath(TablePredicateViewController.predicate), options: nil)
    }

    private func updateEditor() {
        predicateEditor.objectValue = nil
        predicateEditor.rowTemplates = []

        guard let columnNames = selectedTable?.columns.map({ $0.name }) else {
            return
        }

        let compoundTypes = [NSCompoundPredicate.LogicalType.and, NSCompoundPredicate.LogicalType.or].map { NSNumber(value: $0.rawValue)}
        let compoundPredicate = NSPredicateEditorRowTemplate(compoundTypes: compoundTypes)

        let expressions = columnNames.map { NSExpression(forKeyPath: $0.querySafeString()) }
        var formattingDict = [String: String]()
        let subStr = "%[is less than, is less than or equal to, is greater than, is greater than or equal to, is, is not, contains, begins with, ends with]@"

        for name in columnNames {
            formattingDict["%[\(name.querySafeString())]@ \(subStr) %@"] = "%[\(name)]@ \(subStr) %@"
        }

        let attributeTypes: [NSComparisonPredicate.Operator] = [.lessThan, .lessThanOrEqualTo, .greaterThan, .greaterThanOrEqualTo, .equalTo, .notEqualTo, .contains, .beginsWith, .endsWith]
        rowTemplate = NSPredicateEditorRowTemplate(leftExpressions: expressions, rightExpressionAttributeType: .stringAttributeType, modifier: NSComparisonPredicate.Modifier.direct, operators: attributeTypes.map { NSNumber(value: $0.rawValue)}, options: 0)
        predicateEditor.rowTemplates = [compoundPredicate, rowTemplate]
        predicateEditor.objectValue = NSCompoundPredicate(andPredicateWithSubpredicates: [])
        predicateEditor.reloadPredicate()
        predicateEditor.formattingDictionary = formattingDict

    }

    @IBAction func addSimpleRow(_ sender: Any) {
        guard selectedTable != nil else {
            return
        }

        predicateEditor.addRow(nil)
        predicateEditor.needsDisplay = true
    }

    @IBAction func addCompound(_ sender: Any) {
        guard predicate != nil else {
            predicateEditor.addRow(nil)
            return
        }

        guard let objectValue = predicateEditor.objectValue as? NSCompoundPredicate, var newSubs = objectValue.subpredicates as? [NSPredicate] else {
            return
        }

        newSubs.append(NSCompoundPredicate(andPredicateWithSubpredicates: [rowTemplate.predicate(withSubpredicates: nil)]))

        predicateEditor.objectValue = NSCompoundPredicate(type: objectValue.compoundPredicateType, subpredicates: newSubs)
        predicateEditor.needsDisplay = true
    }

    @IBAction func goToSQLView(_ sender: Any) {
        guard let table = selectedTable, let queryString = queryString else {
            NSSound.beep()
            return
        }

        windowController?.showQueryView(with: "SELECT * FROM \(table.qualifiedNameForQuery) WHERE \(queryString)")
    }

    @IBAction func clearPredicate(_ sender: Any) {
         predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [])
    }

}
