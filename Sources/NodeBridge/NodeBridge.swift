//
//  NodeBridge.swift
//  NodeBridge
//
//  Copyright (c) 2021 Changbeom Ahn
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import node_api

public class Addon: NSObject {
    public static var ready: (() -> Void)? {
        didSet {
            guard tsfn != nil else { return }
            ready?()
        }
    }
    
    public static var handler: ((napi_env, napi_value) -> Void)?
    
    @objc
    public static var tsfn: napi_threadsafe_function? {
        didSet {
            guard tsfn != nil else { return }
            ready?()
        }
    }
    
    static let queue = DispatchQueue(label: "addon")
    
    @objc
    static let group = DispatchGroup()
    
    public static func callJS(dict: [String: String]) {
        guard let tsfn = tsfn else { return }
        
        func call(_ data: UnsafeMutableRawPointer?) {
            group.enter()
            let status = napi_call_threadsafe_function(tsfn, data, napi_tsfn_blocking)
            group.wait()
            assert(status == napi_ok)
        }
        
        queue.async {
            var d = dict
            withUnsafeMutablePointer(to: &d) { data in
                group.enter()
                let status = napi_call_threadsafe_function(tsfn, data, napi_tsfn_blocking)
                group.wait()
                assert(status == napi_ok)
            }
        }
    }
    
    @objc
    public static func convert(data: UnsafeMutableRawPointer, result: UnsafeMutablePointer<napi_value?>, env: napi_env) throws {
        let dict = data.bindMemory(to: [String: String].self, capacity: 1).pointee
        group.leave()
        
        let object = (try env.makeObject())!
        for (key, value) in dict {
            try env.set(object: object, name: key, value: env.makeString(value)!)
        }
        
        result.pointee = object
    }
    
    @objc
    public static func callback(env: napi_env, info: napi_callback_info) -> napi_value? {
        var argc = 1
        var object: napi_value?
        do {
            try check(napi_get_cb_info(env, info, &argc, &object, nil, nil))
            guard let object = object else {
                return nil
            }
            
            handler?(env, object)
        } catch {
            if let status = error as? napi_status {
                var error: UnsafePointer<napi_extended_error_info>?
                let s = napi_get_last_error_info(env, &error)
                guard s == napi_ok else { fatalError() }
                print(#function, status, error!.pointee.error_message ?? "no message?")
            } else {
                print(#function, error)
            }
        }
        return nil
    }
}

public struct NodeBridge {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}
