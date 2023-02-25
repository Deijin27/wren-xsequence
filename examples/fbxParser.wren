/*
This is a very basic foundation of how one might start to write an FBX parser
It is not actually function, nor is it intended to be.
It's simply an example to help people understand how to use the XSequence library
*/

import "./xsequence.wren" for XDocument, XElement, XNamespace

// This class is an idea for creating the FBX elements without 
// needing to write as much boilerplate
class Fbx {
    static fbxNamespace {
        if (__fbxNamespace == null) {
            __fbxNamespace = XNamespace.new()
        }
    }
    static element(name) {
        return XElement.new(__fbxNamespace + name)
    }
}

Fbx.element(item, item, item)

XElement.new(__fbxNamespace, item, item, item)