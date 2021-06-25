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

      let flattened = { (entries: [Strings.Entry]) -> NamesSpace in
          let tree = structure(entries)
          flattenKeys(tree)
          return tree
      }

    let tables = self.tables
      .sorted { $0.key.lowercased() < $1.key.lowercased() }
      .map { name, entries in
        [
          "name": name,
          "levels": flattened(entries).toDict(name: "")
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

func flattenKeys(_ parent: NamesSpace) {
    for (name, node) in parent.children {
        flattenKeys(node)

        if let (childName, onlyChild) = node.children.first,
           node.children.count == 1
        {
            let newChild = parent.getOrAddChild(name + "_" + childName)
            newChild.children = onlyChild.children
            newChild.strings = onlyChild.strings
            parent.children.removeValue(forKey: name)
        }
    }
}
