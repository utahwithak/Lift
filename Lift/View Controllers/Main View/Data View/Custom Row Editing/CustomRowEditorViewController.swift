//
//  CustomRowEditorViewController.swift
//  Lift
//
//  Created by Carl Wieland on 3/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CustomRowEditorViewController: LiftViewController {

    static let storyboardIdentifier = NSStoryboard.SceneIdentifier("editRowViewController")

    var row: RowData!
    var columnNames: [String]!
    var sortCount: Int = 0
    var creatingRow = false
    
    @IBOutlet var editValuesArrayController: NSArrayController!

    override func viewDidLoad() {
        super.viewDidLoad()
        for (index, name) in columnNames.enumerated() where index > (sortCount - 1) {
            editRows.append(EditRowData(data: row.data[index], column: name))
        }
    }

    var selectedObject: EditRowData? {
        return editValuesArrayController.selectedObjects.first as? EditRowData
    }

    @IBAction func chooseFileForItem(_ sender: Any) {

    }

    @objc dynamic var editRows = [EditRowData]()
}
