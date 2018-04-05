//
//  Writer.swift
//  Yield
//
//  Created by Carl Wieland on 5/12/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

protocol Writer {
    func write(_ data: Data)
    func write(_ string: String)
    func close()
    func open()
}

extension FileHandle: Writer {
    func write(_ string: String) {
        let raw = string.utf8CString
        raw.withUnsafeBytes({ ptr in
            let rawPtr = UnsafeMutableRawPointer(mutating: ptr.baseAddress!)
            // chop off the null byte
            //
            let data = Data(bytesNoCopy: rawPtr, count: raw.count - 1, deallocator: .none)
            write(data)

        })
    }

    func close() {
        closeFile()
    }
    func open() {

    }
}

extension OutputStream: Writer {
    func write(_ data: Data) {
        let written = data.withUnsafeBytes {
            write($0, maxLength: data.count)
        }

        assert(written == data.count)
    }

    @nonobjc func write(_ string: String) {
        let ptr = OpaquePointer(string)
        let strPt = UnsafePointer<UInt8>(ptr)
        _ = write(strPt, maxLength: Int(strlen(UnsafePointer<Int8>(ptr))))

    }
}
