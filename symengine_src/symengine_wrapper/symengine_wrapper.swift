//
//  symengine.swift
//  cppios_v4
//
//  Created by SnapOps on 2025-09-13.
//

//func evaluateExpression(_ input: String, forceDouble: Bool = true, precision: Int = 10) -> String {
//    guard let cfResultUnmanaged = evaluate_expression_wrapper(input, forceDouble, Int32(precision)) else {
//        return "Error: null result"
//    }
//    return cfResultUnmanaged.takeRetainedValue() as String
//}

import Foundation

func evaluateExpression(_ input: String, forceDouble: Bool = true, precision: Int = 10) -> String {
    print("received: " + input)
    // Get required buffer size
    let requiredSize = evaluate_expression_size(input, forceDouble, Int32(precision))
    guard requiredSize > 0 else {
        print("Error: could not evaluate expression '\(input)', requiredSize = \(requiredSize)")
        return "Error"
    }

    // Create buffer
    var buffer = [CChar](repeating: 0, count: Int(requiredSize))

    // Wrap everything in the closure to keep pointer valid
    let result: String = buffer.withUnsafeMutableBufferPointer { ptr in
        let written = evaluate_expression(input, forceDouble, Int32(precision), ptr.baseAddress, Int(requiredSize))

        // Check for errors returned by C function
        guard written >= 0 else {
            print("Error: buffer too small or evaluation failed for '\(input)' (written = \(written))")
            return "Error"
        }

        let validLength = min(Int(written), ptr.count)

        // Safely convert to String using only valid bytes
        let stringResult = String(
            bytes: ptr.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: validLength) { rawPtr in
                UnsafeBufferPointer(start: rawPtr, count: validLength)
            },
            encoding: .utf8
        )

        if let stringResult {
            print("returning: " + stringResult)
            return stringResult
        } else {
            print("Error: invalid UTF-8 in buffer for expression '\(input)'")
            return "Error"
        }
    }

    return result
}
