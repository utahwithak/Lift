//
//  TextImportViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol TextImportDelegate: class {
    func textImport(_ textVC: TextImportViewController, processAsSQL text: String)
    func textImport(_ textVC: TextImportViewController, showImportFor CSV: [[String]])
}

class TextImportViewController: NSViewController {

    @objc dynamic var text: NSString = ""
    @objc dynamic var useCustomDelimiter = false
    @objc dynamic var delimiter = ","
    @IBOutlet weak var delimiterField: NSTextField!

    public weak var delegate: TextImportDelegate?

    private var parsedData = [[String]]()
    var currentLine = [String]()
    var error: Error?
    var encoding: String.Encoding = .utf8

    @IBAction func parseAsCSV(_ sender: Any) {
        let storyboard = NSStoryboard(name: .main, bundle: nil)
        guard let waitingVC = storyboard.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }
        guard let data = (text as String).data(using: encoding) else {
            return
        }

        let count = Double(data.count)
        let inputStream = InputStream(data: data)

        let parser = CSVParser(stream: inputStream, delimiter: self.delimiter.first ?? ",", encoding: encoding, options: [.trimsWhitespace, .sanitizesFields, .recognizesBackslashesAsEscapes])
        parser.delegate = self

        waitingVC.cancelHandler = {[weak self] in
            parser.cancelParsing()
            self?.parsedData.removeAll(keepingCapacity: true)
        }

        waitingVC.indeterminate = false
        presentAsSheet(waitingVC)

        DispatchQueue.global(qos: .userInitiated).async {

            let observer = parser.observe(\.totalBytesRead) { (parser, _) in

                let progress = Double(parser.totalBytesRead) / count
                DispatchQueue.main.async {
                    waitingVC.value = progress
                }
            }

            defer {
                observer.invalidate()
            }

            parser.parse()

            if let error = self.error {
                DispatchQueue.main.async {
                    self.dismiss(waitingVC)
                    self.presentError(error)
                }

            } else {
                DispatchQueue.main.async {
                    self.dismiss(waitingVC)
                    if !parser.canceled {
                        self.delegate?.textImport(self, showImportFor: self.parsedData)
                    }
                }

            }
        }
    }

    @IBAction func toggleDelimiter(_ sender: NSButton) {

        switch sender.tag {
        case 1:
            delimiter = ","
            useCustomDelimiter = false
        case 2:
            delimiter = ";"
            useCustomDelimiter = false
        case 3:
            delimiter = "\t"
            useCustomDelimiter = false
        default:
            useCustomDelimiter = true
        }
    }

    @IBAction func runAsSQL(_ sender: Any) {
        delegate?.textImport(self, processAsSQL: text as String)
    }
}

extension TextImportViewController: ParserDelegate {

    func parserDidBeginDocument(_ parser: CSVParser) {
        parsedData.removeAll(keepingCapacity: true)
    }

    func parser(_ parser: CSVParser, didBeginLine line: Int) {
        currentLine = [String]()
    }
    func parser(_ parser: CSVParser, didEndLine line: Int) {
        parsedData.append(currentLine)
    }
    func parser(_ parser: CSVParser, didReadField field: String, at index: Int) {
        currentLine.append(field)
    }
    func parser(_ parser: CSVParser, didFailWithError error: Error) {
        parsedData.removeAll()
        self.error = error
    }
}
