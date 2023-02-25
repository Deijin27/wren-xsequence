/*
This is a very basic foundation of how one might start to write an COLLADA parser
It is not actually function, nor is it intended to be.
It's simply an example to help people understand how to use the XSequence library
*/

import "./xsequence.wren" for XDocument

class Color {
    construct rgba(r, g, b, a) {
        _r = r
        _g = g
        _b = b
        _a = a
    }
    r { _r }
    g { _g }
    b { _b }
    a { _a }
}

class Material {

}

class Collada {

    static ns { "{http://www.collada.org/2005/11/COLLADASchema}" }

    version { _version }
    effects { _effects }
    materials { _materials }

    construct parse(text) {
        var doc = XDocument.parse(text)

        _effects = {}
        _materials = {}

        var root = doc.element(ns + "COLLADA")
        if (root == null) {
            Fiber.abort("Missing expected root element '%(ns)COLLADA'")
        }

        _version = root.attributeValue("version")

        var libEffectsElement = root.element(ns + "library_effects")
        if (libEffects != null) {
            parseLibEffects_(libEffectsElement)
        }
    }

    parseLibEffects_(libEffectsElement) {
        for (effectElement in libEffectsElement.elements(ns + "effect")) {
            var id = effect.attributeValue("id")
            var name = effect.attributeValue("name")
            
        }
    }
}

Fbx.element(item, item, item)

XElement.new(__fbxNamespace, item, item, item)