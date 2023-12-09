/*

This is an example of code to generate a collada file from some materials.

Based on the spec detailed here: https://www.khronos.org/files/collada_spec_1_4.pdf

It's an example of using namespaces when generating a document, but the real benefits
of the api come not when generating, where it's relatively simple to manage what you
have chosen to use as prefixes or default namespaces even without a namespace-managing
api, but in parsing where you're parser must manage any valid xml it is given.

This code is licenced under MIT

*/

import "../../xsequence" for XDocument, XElement, XAttribute, XConverter

class Color {
    r { _r }
    g { _g }
    b { _b }
    a { _a }

    construct rgba(r, g, b, a) {
        _r = r
        _g = g
        _b = b
        _a = a
    }
    construct rgb(r, g, b) {
        _r = r
        _g = g
        _b = b
        _a = 1
    }
    static gray(v) { Color.rgb(v, v, v) }
    static white { __white }
    static black { __black }

    toString { "Color(%(r), %(g), %(b), %(a))"}

    static init_() {
        __white = Color.rgb(1, 1, 1)
        __black = Color.rgb(0, 0, 0)
    }
}

Color.init_()

class ColorConverter is XConverter {
    construct new() {}
    description { "Value must be color, stored as space separated numbers r g b and optionally a at the end" }
    toString(value) {
        var result = "%(value.r) %(value.g) %(value.b)"
        if (value.a != 1) {
            result = result + " %(value.a)"
        }
        return result
    }
    fromString(value) {
        var split = value.split(" ")
        if (split.count < 3 || split.count > 4) {
            return null
        }
        var r = Num.fromString(split[0])
        var g = Num.fromString(split[1])
        var b = Num.fromString(split[2])
        if (r == null || g == null || b == null) {
            return null
        }
        if (split.count == 3) {
            return Color.rgb(r, g, b)
        }
        var a = Num.fromString(split[3])
        if (a == null) {
            return null
        }
        return Color.rgba(r, g, b, a)
    }
}
XConverter.register(Color, ColorConverter.new())

class Material {
    name { _name }
    name=(v) { _name = v }

    emission { _emission }
    emission=(color) { _emission = color }

    ambient { _ambient }
    ambient=(color) { _ambient = color }

    diffuse { _diffuse }
    diffuse=(color) { _diffuse = color }

    specular { _specular }
    specular=(color) { _specular = color }
    
    construct new() {
        _emission = Color.black
        _ambient = Color.black
        _diffuse = Color.white
        _specular = Color.black
    }
}

class Collada is XElement {
    static ns { "{http://www.collada.org/2005/11/COLLADASchema}" }

    // Here I use the technique of adding the namespace to the localName to make the name string
    // There are some other approaches you might take:
    //   1. Create a set of methods with additional for each arity for generating your elements 
    //      static myElement(name, content) { XElement.new(ns + name, content) }
    //   2. Generate the document with regular names, and afterwards recurse through and
    //      apply the namespace prefix to all the elements.
    //   3. Technically in cases where all elements use the same namespace, you can just not
    //      apply the namespace, as both elements with the currently defined default
    //      namespace, and those with no namespace will be written without a prefix. 
    //      Although in parsing you cannot abuse this as the namespaces will be applied to 
    //      all the elements when loaded
    static generate(materials) {
        var libraryEffects = XElement.new(ns + "library_effects")
        var libraryMaterials = XElement.new(ns + "library_materials")
        for (i in 0...materials.count) {
            var m = materials[i]
            var effectElement = generateEffect(m)
            var effectId = "effect%(i)"
            effectElement.add(XAttribute.new("id", effectId))
            libraryEffects.add(effectElement)

            var materialElement = XElement.new(ns + "material",
                XAttribute.new("id", "material%(i)"),
                XAttribute.new("name", m.name),
                XElement.new(ns + "instance_effect", XAttribute.new("url", "#%(effectId)"))
            )
            libraryMaterials.add(materialElement)
        }

        // You're responsible for declaring the namespaces at the right scope
        var collada = XElement.new(ns + "COLLADA",
            XAttribute.xmlns("http://www.collada.org/2005/11/COLLADASchema"),
            XAttribute.new("version", "1.4.1")
            )
        collada.add(libraryMaterials)
        collada.add(libraryEffects)

        return XDocument.new(collada)
    }

    static generateEffect(material) {
        return XElement.new(ns + "effect",
            XAttribute.new("name", material.name),
            XElement.new(ns + "profile_COMMON",
                XElement.new(ns + "technique",
                    XAttribute.new("sid", "common"),
                    XElement.new(ns + "phong",
                        XElement.new(ns + "emission", XElement.new(ns + "color", material.emission)),
                        XElement.new(ns + "ambient", XElement.new(ns + "color", material.ambient)),
                        XElement.new(ns + "diffuse", XElement.new(ns + "color", material.diffuse)),
                        XElement.new(ns + "specular", XElement.new(ns + "color", material.specular))
                    )
                )
            )
        )
    }
}

var m0 = Material.new()
m0.name = "map03_00_01"
m0.ambient = Color.gray(0.29032257)
m0.diffuse = Color.gray(0.7096774)

var m1 = Material.new()
m1.name = "map03_00_01a"

var m2 = Material.new()
m2.name = "map03_00_02"
m2.ambient = Color.gray(0.29032257)
m2.diffuse = Color.gray(0.7096774)

var materials = [m0, m1, m2]

var doc = Collada.generate(materials)

doc.write {|x| System.write(x) }

