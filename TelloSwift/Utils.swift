//
//  Utils.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/23.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation

extension String
{
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
   }
    
    func numeric() -> String {
        return self.filter("-0123456789.".contains)
    }
    
    func toDouble() -> Double {
        return Double(self.numeric()) ?? Double.nan
    }


    /// return if String is "ok"
    func okToBool() -> Bool {
        return self == "ok"
    }
}
