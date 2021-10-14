//
//  NodeAPI.swift
//  NodeAPI
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

public extension napi_env {
    func makeObject() throws -> napi_value? {
        try call { napi_create_object(self, &$0) }
    }
    
    func makeString(_ string: String) throws -> napi_value? {
        try call { napi_create_string_utf8(self, string, string.count, &$0) }
    }
    
    func call<T>(initial: T, closure: (inout T) -> napi_status) throws -> T {
        var result = initial
        try check(closure(&result))
        return result
    }
    
    func call<T>(closure: (inout T?) -> napi_status) throws -> T? {
        try call(initial: nil, closure: closure)
    }
    
    func set(object: napi_value, name: String, value: napi_value) throws {
        try check(napi_set_named_property(self, object, name, value))
    }
    
    func type(of value: napi_value) throws -> napi_valuetype {
        try call(initial: napi_number) { napi_typeof(self, value, &$0) }
    }
    
    func isArray(_ object: napi_value) throws -> Bool {
        try call(initial: false) { napi_is_array(self, object, &$0) }
    }
    
    func bool(_ value: napi_value) throws -> Bool {
        try call(initial: false) { napi_get_value_bool(self, value, &$0) }
    }
    
    func double(_ value: napi_value) throws -> Double {
        try call(initial: 0) { napi_get_value_double(self, value, &$0) }
    }
    
    func int(_ value: napi_value) throws -> Int {
        Int(try call(initial: 0) { napi_get_value_int64(self, value, &$0) })
    }
    
    func string(_ value: napi_value) throws -> String? {
        var result = try call(initial: 0) { napi_get_value_string_utf8(self, value, nil, 0, &$0) } + 1
        var buf = [CChar](repeating: 0, count: result)
        result = try call(initial: 0) { napi_get_value_string_utf8(self, value, &buf, result, &$0) }
        return String(utf8String: &buf)
    }
    
    func getPropertyNames(object: napi_value, mode: napi_key_collection_mode = napi_key_own_only, filter: napi_key_filter = napi_key_all_properties, conversion: napi_key_conversion = napi_key_keep_numbers) throws -> napi_value? {
        try call { napi_get_all_property_names(self, object, mode, filter, conversion, &$0) }
    }
    
    func count(_ value: napi_value) throws -> Int {
        Int(try call(initial: UInt32(0)) { napi_get_array_length(self, value, &$0) })
    }
    
    func element(object: napi_value, index: Int) throws -> napi_value? {
        try call { napi_get_element(self, object, UInt32(index), &$0) }
    }
    
    func property(object: napi_value, key: napi_value) throws -> napi_value? {
        try call { napi_get_property(self, object, key, &$0) }
    }
}

extension napi_valuetype: CustomStringConvertible {
    public var description: String {
        switch self {
        case napi_undefined:
            return "undefined"
        case napi_null:
            return "null"
        case napi_boolean:
            return "boolean"
        case napi_number:
            return "number"
        case napi_string:
            return "string"
        case napi_symbol:
            return "symbol"
        case napi_object:
            return "object"
        case napi_function:
            return "function"
        case napi_external:
            return "external"
        case napi_bigint:
            return "bigint"
        default:
            return "unknown type \(self)"
        }
    }
}

public func check(_ status: napi_status) throws {
    guard status != napi_ok else { return }
    throw status
}

extension napi_status: Error {}

extension napi_status: CustomStringConvertible {
    public var description: String {
        switch self {
        case napi_ok:
            return "napi_ok"
        case napi_invalid_arg:
            return "napi_invalid_arg"
        case napi_object_expected:
            return "napi_object_expected"
        case napi_string_expected:
            return "napi_string_expected"
        case napi_name_expected:
            return "napi_name_expected"
        case napi_function_expected:
            return "napi_function_expected"
        case napi_number_expected:
            return "napi_number_expected"
        case napi_boolean_expected:
            return "napi_boolean_expected"
        case napi_array_expected:
            return "napi_array_expected"
        case napi_generic_failure:
            return "napi_generic_failure"
        case napi_pending_exception:
            return "napi_pending_exception"
        case napi_cancelled:
            return "napi_cancelled"
        case napi_escape_called_twice:
            return "napi_escape_called_twice"
        case napi_handle_scope_mismatch:
            return "napi_handle_scope_mismatch"
        case napi_callback_scope_mismatch:
            return "napi_callback_scope_mismatch"
        case napi_queue_full:
            return "napi_queue_full"
        case napi_closing:
            return "napi_closing"
        case napi_bigint_expected:
            return "napi_bigint_expected"
        case napi_date_expected:
            return "napi_date_expected"
        case napi_arraybuffer_expected:
            return "napi_arraybuffer_expected"
        case napi_detachable_arraybuffer_expected:
            return "napi_detachable_arraybuffer_expected"
        default:
            return "\(self)"
        }
    }
}

public struct Value {
    let env: napi_env
    
    let value: napi_value
    
    public var type: ValueType? {
        ValueType(rawValue: Int(try! env.type(of: value).rawValue))
    }
    
    public init(env: napi_env, value: napi_value) {
        self.env = env
        self.value = value
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        guard let type = type else { fatalError() }
        do {
            switch type {
            case .undefined:
                return type.description
            case .null:
                return type.description
            case .boolean:
                return String(try! env.bool(value))
            case .number:
                return String(try! env.double(value))
            case .string:
                return "\"\(try env.string(value)!)\""
            case .symbol:
                return type.description
            case .object:
                return objectDescription(indentLevel: 0)
            case .function:
                return type.description
            case .external:
                fatalError()
//                return type.description
            case .bigint:
                fatalError()
//                return type.description
            }
        } catch {
            fatalError()
        }
    }
    
    func objectDescription(indentLevel: Int) -> String {
        guard indentLevel < 10 else { return "skipping nested objects beyond level \(indentLevel)" }
        let isArray = try! env.isArray(value)
        guard !isArray else { return arrayDescription(indentLevel: indentLevel) }
        
        let keys = try! env.getPropertyNames(object: value)!
        let count = try! env.count(keys)
        guard count > 0 else { return "{}" }
        let maxElementCount = 100
        var elements = (0..<min(count, maxElementCount))
            .map { try! env.element(object: keys, index: $0)! }
            .map { (Value(env: env, value: $0),
                    Value(env: env, value: try! env.property(object: value, key: $0)!)) }
            .map { tuple -> String in
                tuple.0.description + ": " + (tuple.1.type == .object
                                              ? tuple.1.objectDescription(indentLevel: indentLevel + 1)
                                              : tuple.1.description) }
        if count >= maxElementCount {
            elements.append("\(count - maxElementCount) not shown")
        }
        let indentSize = 2
        let indent = String(repeating: " ", count: indentLevel * indentSize)
        let innerIndent = indent + String(repeating: " ", count: indentSize)
        return "{\n" + innerIndent + elements.joined(separator: ",\n" + innerIndent) + "\n" + indent + "}"
    }
    
    func arrayDescription(indentLevel: Int) -> String {
        let count = try! env.count(value)
        guard count > 0 else { return "[]" }
        let elements = (0..<count)
            .map { try! env.element(object: value, index: $0) }
            .map { Value(env: env, value: $0!) }
            .map { $0.type == .object ? $0.objectDescription(indentLevel: indentLevel + 1) : $0.description }
        let indentSize = 2
        let indent = String(repeating: " ", count: indentLevel * indentSize)
        let innerIndent = indent + String(repeating: " ", count: indentSize)
        return "[\n" + innerIndent + elements.joined(separator: ",\n" + innerIndent) + "\n" + indent + "]"
    }
}

public enum ValueType: Int {
    case undefined
    case null
    case boolean
    case number
    case string
    case symbol
    case object
    case function
    case external
    case bigint
}

extension ValueType: CustomStringConvertible {
    public var description: String {
        napi_valuetype(rawValue: UInt32(rawValue)).description
    }
}
