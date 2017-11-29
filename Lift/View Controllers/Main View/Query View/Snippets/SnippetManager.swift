//
//  SnippetManager.swift
//  Lift
//
//  Created by Carl Wieland on 11/11/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class SnippetManager {

    static let shared = SnippetManager()

    private init() {
        load()
    }

    public private(set) var snippets = [Snippet]()

    public var numberOfSnippets: Int {
        return snippets.count
    }

    func addNewSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
        save()
    }

    func removeSnippet(at index: Int) {
        snippets.remove(at: index)
        save()
    }

    func replace(at index: Int, with snippet: Snippet) {
        snippets[index] = snippet
        save()
    }

    private func save() {
        guard let fileURL = snippetFileURL else {
            print("No snippet URL!")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(snippets)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save snippets:\(error)")
        }

    }

    private func load() {
        guard let fileURL = snippetFileURL else {
            print("No snippet URL!")
            return
        }

        if let data = try? Data(contentsOf: fileURL, options: Data.ReadingOptions.mappedIfSafe) {

            let decoder = JSONDecoder()
            do {
                snippets = try decoder.decode([Snippet].self, from: data)
            } catch {
                print("Failed to decode snippets:\(error)")
            }
        }

    }

    var supportDirectory: URL? {
        return try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    var snippetFileURL: URL? {
        return supportDirectory?.appendingPathComponent("snippets.json")
    }

}
