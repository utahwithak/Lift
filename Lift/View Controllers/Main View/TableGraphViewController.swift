//
//  TableGraphView.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableGraphViewController: LiftMainViewController {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var container: GraphViewsContainer!

    override func viewDidLoad() {
        super.viewDidLoad()

        container.delegate = self
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.lightGray.cgColor
        scrollView.documentView = container
        scrollView.allowsMagnification = true
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true

        NotificationCenter.default.addObserver(self, selector: #selector(databaseRefreshed), name: .DatabaseReloaded, object: nil)

        if document?.database != nil {
            reloadView()
        }
    }
    override var representedObject: Any? {
        didSet {
            reloadView()
        }
    }

    @objc func databaseRefreshed(_ noti: Notification) {
        if let database = noti.object as? Database, document?.database.allDatabases.contains(where: { database  === $0 }) ?? false {
            reloadView()
        }
    }
    @IBAction func zoomChange(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1:
            scrollView.animator().magnification = scrollView.magnification + 0.05

        default:
            scrollView.animator().magnification = scrollView.magnification - 0.05
        }

    }

    func reloadView() {
        var frameMap = [String: CGRect]()
        for childController in children {

            if let graphView = childController as? GraphTableView {
                frameMap[graphView.table.qualifiedNameForQuery] = graphView.view.frame
            }
        }

        for view in container.subviews {
            view.removeFromSuperview()
        }
        children.removeAll(keepingCapacity: true)

        container.arrowViews.removeAll(keepingCapacity: true)

        guard let db = document?.database else {
            return
        }

        var maxHeight: CGFloat = 0

        for database in db.allDatabases {

            for table in database.tables {
                guard let cell = storyboard?.instantiateController(withIdentifier: "graphTableViewCell") as? GraphTableView else {
                    fatalError("Need to create graph table view cell!")
                }
                cell.table = table

                cell.view.translatesAutoresizingMaskIntoConstraints = false

                container.addSubview(cell.view)
                children.append(cell)

                if cell.view.frame.height > maxHeight {
                    maxHeight = cell.view.frame.height
                }

            }

        }

        let viewNum = container.subviews.count
        let width = Int(ceil(sqrt(Double(viewNum))))

        var x: CGFloat = 0
        var y: CGFloat = 0
        for view in container.subviews {
            view.frame.origin = CGPoint(x: x * 260 + CGFloat(width) * 200, y: y * (maxHeight + 200) + CGFloat(width) * 200)
            x += 1
            if Int(x) == width {
                x = 0
                y += 1
            }

        }

        for childController in children {
            if let graphView = childController as? GraphTableView, let pastRect = frameMap[graphView.table.qualifiedNameForQuery] {
                graphView.view.frame = pastRect
            }
        }

        container.frame = CGRect(x: 0, y: 0, width: viewNum * 400, height: viewNum * 400)

        //Foreign key hookup
        for database in db.allDatabases {

            for table in database.tables {
                guard let fromViewController = children.first(where: { ($0 as? GraphTableView)?.table === table }) as? GraphTableView else {
                    continue
                }

                for connection in table.foreignKeys {
                    let fromPoint = ArrowPoint(view: fromViewController, columns: connection.fromColumns)
                    guard let toViewController = children.first(where: { ($0 as? GraphTableView)?.table.name == connection.toTable }) as? GraphTableView else {
                        continue
                    }

                    let toPoint = ArrowPoint(view: toViewController, columns: connection.toColumns)
                    container.arrowViews.append(ArrowView(from: fromPoint, to: toPoint))
                }
            }
        }
    }
}

extension TableGraphViewController: GraphContainerViewDelegate {
    func containerView(_ containerView: GraphViewsContainer, didSelect view: NSView?) {
        if let view = view {
            if let vcIndex = children.index(where: { $0.view == view}), let graphView = children[vcIndex] as? GraphTableView {
                windowController?.selectedTable = graphView.table
            }
        } else {
            windowController?.selectedTable = nil
        }
    }
}
