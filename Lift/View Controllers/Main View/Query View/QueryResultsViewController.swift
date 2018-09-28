//
//  QueryResultsViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class QueryResultsViewController: LiftViewController {

    @IBOutlet weak var tabControl: TabControl!
    @IBOutlet weak var holder: NSTabView!

    lazy var overviewViewController: ResultsOverviewViewController = {
        let overView =  storyboard?.instantiateController(withIdentifier: "resultsOverviewViewController") as? ResultsOverviewViewController
        overView?.title = "Results"
        overView?.delegate = self
        return overView!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabControl.datasource = self
        clearContent()
    }

    func clearContent() {
        overviewViewController.results.removeAll(keepingCapacity: true)
        holder.removeAllItems()
        tabControl.reloadData()
    }

    func startQueries() {
        clearContent()
        overviewViewController.stillLoading = true

        holder.addTabViewItem(NSTabViewItem(viewController: overviewViewController))
        tabControl.reloadData()
    }

    func addResult(_ result: ExecuteQueryResult) {

        overviewViewController.results.append(result)

        if !result.rows.isEmpty, let resultsView = storyboard?.instantiateController(withIdentifier: "ResultsTableViewController") as? ResultsTableViewController {
            resultsView.results = result
            resultsView.title = String(format: NSLocalizedString("Result Set %i", comment: "Title for results from a query"), overviewViewController.results.count)
            holder.addTabViewItem(NSTabViewItem(viewController: resultsView))
            tabControl.reloadData()
        }

    }

    func didFinish() {
        overviewViewController.stillLoading = false
    }
}
extension QueryResultsViewController: ResultsOverviewDelegate {
    func shouldSelect(identifier: String) {
        for case let resultsVC as ResultsTableViewController in holder.tabViewItems.compactMap({ $0.viewController }) {
            if identifier == resultsVC.results.identifier, let index = holder.tabViewItems.index(where: { $0.viewController === resultsVC }) {
                tabControl.selectedItem = holder.tabViewItems[index]
            }
        }
    }
}

extension QueryResultsViewController: TabControlDatasource {
    func numberOfTabsFor(_ control: TabControl) -> Int {
        return holder.numberOfTabViewItems
    }

    func tabControl(_ control: TabControl, itemAt index: Int) -> Any {
        return holder.tabViewItem(at: index)
    }

    func tabControl(_ control: TabControl, titleKeyPathFor item: Any) -> String {
        return "viewController.title"
    }

    func tabControl(_ control: TabControl, canReorder item: Any) -> Bool {
        return true
    }

    func tabControl(_ control: TabControl, didReorderItems items: [Any]) -> Bool {
        guard let newItems = items as? [NSTabViewItem] else {
            return false
        }

        holder.removeAllItems()
        for item in newItems {
            holder.addTabViewItem(item)
        }

        return true
    }

    func tabControl(_ control: TabControl, menuFor item: Any) -> NSMenu? {
        return nil
    }

    func tabControl(_ control: TabControl, didSelect item: Any) {
        guard let tabItem = item as? NSTabViewItem else {
            fatalError("Not getting what I expect back!")
        }
        holder.selectTabViewItem(tabItem)
    }

    func tabControl(_ control: TabControl, canEdit item: Any) -> Bool {
        return false
    }

    func tabControl(_ control: TabControl, setTitle title: String, for item: Any) {

    }
}
