/*

For use with https://wren.io/cli/

Generate documentation files using attributes

This gives a whole new meaning to "hacky"

> wren_cli.exe generate_docs.wren > docs.md

*/

import "io" for Directory, File
import "meta" for Meta

System.print("# XSequence Documentation\n")

var code = File.read("xsequence.wren")

// Hacky way to make attributes not compiled out
code = code
  .replace("#doc", "#!doc")
  .replace("#abstract", "#!abstract")
  .replace("#internal", "#!internal")
  .replace("#arg", "#!arg")

Meta.eval(code)

var moduleVariables = Meta.getModuleVariables("./generate_docs")

for (variable in moduleVariables) {
  if (variable == "Object metaclass") {
    continue
  }

  var v = Meta.compileExpression(variable).call()
  if (!(v is Class)) {
    continue
  }

  if (v.attributes == null) {
    continue
  }
  var classAttr = v.attributes.self[null]
  if (classAttr == null) {
    continue
  }
  // ignore abstract and internal
  if (classAttr["abstract"] != null || classAttr["internal"] != null) {
    continue
  }

  // class attributes
  var doc = classAttr["doc"]
  if (doc != null) {
    System.print("## " + variable + "\n")
    System.print(doc[0] + "\n")
  }

  // look for our method attributes

  // inherit method attributes from supertype
  var methodAttrs = v.attributes.methods
  var superclass = v.supertype
  while (superclass != null) {
    if (superclass.attributes != null) {
      for (kvp in superclass.attributes.methods) {
        methodAttrs[kvp.key] = kvp.value
      }
    }
    superclass = superclass.supertype
  }
  // sort the method signatures
  var signatures = methodAttrs.keys.toList
  signatures.sort {|a, b|
    if (a.startsWith("init") && !b.startsWith("init")) return true
    if (b.startsWith("init") && !a.startsWith("init")) return false
    return a.codePoints[0] < b.codePoints[0]
  }
  // look for our method attributes
  for (signature in signatures) {
    var mAttrAll = methodAttrs[signature]
    var mAttr = mAttrAll[null]
    if (mAttr == null) {
      continue
    }
    var doc = mAttr["doc"]
    if (doc != null) {
      // replace the init with construct in constructor signatures
      signature = signature.replace("init ", "construct ")
      if (!(signature.contains("_"))) {
        System.print("### " + signature + "\n")
      } else {
        var args = mAttrAll["arg"]
        if (args == null) {
          Fiber.abort("Missing necessary arg attribute on %(signature) of %(v)")
        }
        var methodArgNames = args["name"]
        if (methodArgNames == null) {
          Fiber.abort("Missing name child attribute on arg attribute on %(signature) of %(v)")
        }
        // could add arg descriptions in the future too
        //var argDescs = args["desc"]
        var methodName = signature.split("(")[0]
        var methodArgs = methodArgNames.join(", ")
        System.print("### %(methodName)(%(methodArgs))\n")
      }
      
      System.print(doc[0].trim().split("\n").map{|x| x.trim() }.join("\n") + "\n")
    }
  }
}
