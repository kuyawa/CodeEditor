//
//  QuickYaml.swift
//  CodeEditor
//
//  Created by Mac Mini on 1/20/17.
//  Copyright © 2017 Armonia. All rights reserved.
//

import Foundation


class QuickYaml {
    
    func parse(_ text: String) -> Dixy {
        let lines = text.components(separatedBy: "\n")
        var dixy  = Dixy()
        var key   = ""
        var children = Dixy()
        var hasChildren = false
        
        // Lopp dictionary in order or patterns will mess up colorizing
        for line in lines {
            if line.isEmpty { continue /* blank */ }
            if line.hasPrefix("#") { continue /* comment */ }
            if line.hasPrefix(" ") { /* child */
                let pair = split(line)
                children[pair.0] = pair.1
            } else { /* parent */
                if hasChildren { /* previous parent, add before starting new parenthood */
                    dixy[key] = children
                    hasChildren = false
                }
                let pair = split(line)
                key = pair.0
                if pair.1.isEmpty {
                    hasChildren = true
                    children = Dixy()
                } else {
                    dixy[key] = pair.1
                }
            }
        }
        
        if hasChildren { /* abandoned children, provide child support */
            dixy[key] = children
        }
        
        return dixy
    }
    
    func split(_ text: String) -> (String, String) {
        let parts = text.components(separatedBy: ":")
        let key = (parts.first ?? "?").trimmingCharacters(in: .whitespaces)
        var val = (parts.last ?? "").trimmingCharacters(in: .whitespaces)
        
        if parts.count > 2 { /* colons in value? */
            let index = text.firstIndex(of: ":")
            let position = text.index(index!, offsetBy: 1)
            val = text[position...].trimmingCharacters(in: .whitespaces)
            //print("Colons \(parts.count) - position: \(position) - text: \(val)")
        }
        
        return (key, val)
    }

}


// End
