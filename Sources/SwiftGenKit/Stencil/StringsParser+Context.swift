//
// SwiftGenKit
// Copyright © 2020 SwiftGen
// MIT Licence
//

import Foundation

private extension String {
  var newlineEscaped: String {
    self
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\r")
  }
}

//
// See the documentation file for a full description of this context's structure:
// Documentation/SwiftGenKit Contexts/strings.md
//

extension Strings.Parser {
  public func stencilContext() -> [String: Any] {
    let tables = self.tables
      .sorted { $0.key.lowercased() < $1.key.lowercased() }
      .map { name, entries in
        [
          "name": name,
          "levels": structure(entries).toDict(name: "")
        ]
      }

    return [
      "tables": tables
    ]
  }
}

extension Strings.Entry {
    var dict: [String: Any] {
        [
            "name": keyStructure.last ?? "",
            "key": key.newlineEscaped,
            "translation": translation.newlineEscaped,
            "types": types.map { $0.rawValue }
        ]
    }
}

class NamesSpace {
    var strings: [Strings.Entry]    = []
    var children: [String : NamesSpace]  = [:]

    func toDict(name: String) -> [String: Any] {
        return [
            "name":     name,
            "strings":
                strings
                    .sorted {
                        ($0.keyStructure.last?.lowercased() ?? "") <
                        ($1.keyStructure.last?.lowercased() ?? "")
                    }
                    .map  {
                        $0.dict
                    },

            "children":
                children
                    .sorted { $0.key < $1.key}
                    .map { $0.value.toDict(name: $0.key) },
        ]
    }

    func getOrAddChild(_ name: String) -> NamesSpace {
        let child = children[name, default: NamesSpace()]
        children[name] = child
        return child
    }

    func getOrAddChild(atPath path: [String]) -> NamesSpace {
        return path.reduce(self) { node, keyFragment in
            node.getOrAddChild(keyFragment)
        }
    }
}

func structure(_ entries: [Strings.Entry]) -> NamesSpace {
    return entries.reduce(NamesSpace()) { tree, entry in
        let node = tree.getOrAddChild(atPath: entry.keyStructure.dropLast())
        node.strings.append(entry)
        return tree
    }
}
