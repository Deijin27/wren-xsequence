
import "./xsequence" for XDocument, XElement, XAttribute, XComment, XParser, XWriter, XName, NamespaceStack, XCData, XText
import "./wren-assert" for Assert
import "io" for File

var DEBUG = false // set true to view the full callstack from a failed test

var PASSED_TEST_COUNT = 0
var FAILED_TEST_COUNT = 0

class Test {
    static run(name, callable) {
        if (DEBUG) {
            System.print("Running test '%(name)'")
            callable.call()
            PASSED_TEST_COUNT = PASSED_TEST_COUNT + 1
            return
        }
        var testFiber = Fiber.new { callable.call() }
        var error = testFiber.try()
        if (error == null) {
            PASSED_TEST_COUNT = PASSED_TEST_COUNT + 1
            System.print("+ Passed test '%(name)'")
        } else {
            FAILED_TEST_COUNT = FAILED_TEST_COUNT + 1
            System.print("- Failed test '%(name)': %(error)")
        }
    }
}

class AssertCustom {
    static attributeIdentical(actual, expected) {
        Assert.typeOf(actual, XAttribute)
        Assert.typeOf(expected, XAttribute)
        Assert.equal(actual.name, expected.name)
        Assert.equal(actual.value, expected.value)
    }

    static elementIdentical(actual, expected) {
        Assert.typeOf(actual, XElement)
        Assert.typeOf(expected, XElement)
        Assert.equal(actual.name, expected.name)
        Assert.countOf(actual.attributes, expected.attributes.count)
        for (i in 0...actual.attributes.count) {
            AssertCustom.attributeIdentical(actual.attributes[i], expected.attributes[i])
        }
        Assert.countOf(actual.nodes, expected.nodes.count)
        for (i in 0...actual.nodes.count) {
            AssertCustom.nodeIdentical(actual.nodes[i], expected.nodes[i])
        }
    }

    static documentIdentical(actual, expected) {
        Assert.typeOf(actual, XDocument)
        Assert.typeOf(expected, XDocument)
        Assert.countOf(actual.nodes, expected.nodes.count)
        for (i in 0...actual.nodes.count) {
            AssertCustom.nodeIdentical(actual.nodes[i], expected.nodes[i])
        }
    }

    static commentIdentical(actual, expected) {
        Assert.typeOf(actual, XComment)
        Assert.typeOf(expected, XComment)
        Assert.equal(actual.value, expected.value)
    }

    static textIdentical(actual, expected) {
        Assert.typeOf(actual, XText)
        Assert.typeOf(expected, XText)
        Assert.equal(actual.value, expected.value)
    }

    static cdataIdentical(actual, expected) {
        Assert.typeOf(actual, XCData)
        Assert.typeOf(expected, XCData)
        Assert.equal(actual.value, expected.value)
    }

    static nodeIdentical(actual, expected) {
        if (expected is XComment) {
            commentIdentical(actual, expected)
        } else if (expected is XElement) {
            elementIdentical(actual, expected)
        } else if (expected is XCData) {
            cdataIdentical(actual, expected)
        } else if (expected is XText) {
            textIdentical(actual, expected)
        } else {
            Fiber.abort("AssertCustom.nodeIdentical: Object is not an XElement or XComment")
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// BEGIN TESTS /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

if (DEBUG) {
    System.print("\n-- TESTING STARTED DEBUG --\n")
} else {
    System.print("\n-- TESTING STARTED --\n")
}

////////////////////////////////////////////////////////////////////////////////
// TEST INTERNAL ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Namespace Stack: resolves correctly") {
    var s = NamespaceStack.new()
    s.push()
    Assert.aborts { s.getValue("b") }
    s.setPrefixValue("b", "blue")
    Assert.equal(s.getValue("b"), "blue")
    Assert.equal(s.getPrefix("blue"), "b")
    s.push()
    Assert.equal(s.getValue("b"), "blue")
    Assert.equal(s.getPrefix("blue"), "b")
    s.setPrefixValue("b", "notBlue")
    Assert.equal(s.getValue("b"), "notBlue")
    Assert.equal(s.getPrefix("notBlue"), "b")
    Assert.aborts { s.getValue("a") }
    s.setPrefixValue(null, "hellothere")
    Assert.equal(s.getValue(null), "hellothere")
}

////////////////////////////////////////////////////////////////////////////////
// TEST UTILITIES //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("XName: builds name correctly") {
    var name = XName.build("blue", "bird")
    Assert.equal(name, "{blue}bird")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("XName: splits name correctly") {
    var name = null

    name = XName.split("{blue}bird")
    Assert.typeOf(name, XName)
    Assert.equal(name.namespace, "blue")
    Assert.equal(name.localName, "bird")

    name = XName.split("bird")
    Assert.typeOf(name, XName)
    Assert.equal(name.namespace, null)
    Assert.equal(name.localName, "bird")

    name = XName.splitFast("{blue}bird")
    Assert.typeOf(name, XName)
    Assert.equal(name.namespace, "blue")
    Assert.equal(name.localName, "bird")

    name = XName.splitFast("bird")
    Assert.notExists(name)

    name = XName.splitPrefixFast("b:bird")
    Assert.typeOf(name, XName)
    Assert.equal(name.namespace, "b")
    Assert.equal(name.localName, "bird")

    name = XName.splitPrefixFast("bird")
    Assert.notExists(name)
}

////////////////////////////////////////////////////////////////////////////////
// TEST SYNTAX /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: Set value num converted to string") {
    var a = XAttribute.new("name", 69)
    Assert.equal(a.value, "69")
    a.value = 4
    Assert.equal(a.value, "4")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: Set value bool converted to string") {
    var a = XAttribute.new("name", true)
    Assert.equal(a.value, "true")
    a.value = false
    Assert.equal(a.value, "false")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: Set value null converted to empty") {
    var a = XAttribute.new("name", null)
    Assert.equal(a.value, "")
    a.value = "bee"
    Assert.equal(a.value, "bee")
    a.value = null
    Assert.equal(a.value, "")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("XText: Set value converted to string") {
    var c = XText.new(69)
    Assert.equal(c.value, "69")
    c.value = 0
    Assert.equal(c.value, "0")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("XCData: Set value converted to string") {
    var c = XCData.new(69)
    Assert.equal(c.value, "69")
    c.value = 0
    Assert.equal(c.value, "0")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Set value num converted to string") {
    var e = XElement.new("name", 69)
    Assert.equal(e.value, "69")
    e.value = 2
    Assert.equal(e.value, "2")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Set value null converted to empty") {
    var a = XElement.new("name", null)
    Assert.equal(a.value, "")
    a.value = "bee"
    Assert.equal(a.value, "bee")
    a.value = null
    Assert.equal(a.value, "")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Set value bool converted to string") {
    var e = XElement.new("name", true)
    Assert.equal(e.value, "true")
    e.value = false
    Assert.equal(e.value, "false")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Comment: Set value converted to string") {
    var c = XComment.new(69)
    Assert.equal(c.value, "69")
    c.value = 0
    Assert.equal(c.value, "0")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add and remove element") {
    var parent = XElement.new("parent")
    var child = XElement.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add and remove comment") {
    var parent = XElement.new("parent")
    var child = XComment.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add and remove XText") {
    var parent = XElement.new("parent")
    var child = XText.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add and remove CData") {
    var parent = XElement.new("parent")
    var child = XCData.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add String") {
    var parent = XElement.new("parent")
    var child = "child"
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.typeOf(c, XText)
    Assert.equal(c.value, child)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add multiple strings interpreted as one merged value") {
    var parent = XElement.new("parent")
    parent.add("String")
    parent.add(XText.new("TextNode"))
    parent.add(XCData.new("CDataNode"))
    Assert.equal(parent.value, "StringTextNodeCDataNode")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add and remove attribute") {
    var parent = XElement.new("parent")
    var child = XAttribute.new("child", "attribute content")
    parent.add(child)
    Assert.countOf(parent.attributes, 1)
    var c = parent.attributes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.attributes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Duplicate attributes should abort fiber") {
    var parent = XElement.new("parent")
    var child1 = XAttribute.new("child", "attribute content")
    var child2 = XAttribute.new("child", "other attribute content")
    parent.add(child1)
    Assert.aborts(Fn.new { parent.add(child2) })
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Document: Add string aborts fiber") {
    var doc = XDocument.new()
    Assert.aborts(Fn.new { doc.add("string value") })
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Add sequence") {
    var parent = XElement.new("parent")
    var childElement = XElement.new("child")
    var childAttribute = XAttribute.new("child", "attribute content")
    var children = [childElement, childAttribute]
    parent.add(children)
    Assert.countOf(parent.attributes, 1)
    Assert.countOf(parent.nodes, 1)
    var cElem = parent.nodes[0]
    var cAttr = parent.attributes[0]
    Assert.equal(cElem, childElement)
    Assert.equal(cAttr, childAttribute)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Constructor syntax without square brackets") {
    var expected = 
        XElement.new("fishies", [
            XAttribute.new("amount", 2),
            XElement.new("danio", [
                XAttribute.new("name", "zebra"),
                XAttribute.new("color", "red")
            ]),
            XComment.new("TheComment"),
            XElement.new("danio", [
                XAttribute.new("name", "pea<rl"),
                XAttribute.new("color", "pink")
            ]),
            XElement.new("danio", "val>ue")
        ])
    
    var actual = 
        XElement.new("fishies",
            XAttribute.new("amount", 2),
            XElement.new("danio",
                XAttribute.new("name", "zebra"),
                XAttribute.new("color", "red")
            ),
            XComment.new("TheComment"),
            XElement.new("danio",
                XAttribute.new("name", "pea<rl"),
                XAttribute.new("color", "pink")
            ),
            XElement.new("danio", "val>ue")
        )

    AssertCustom.elementIdentical(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Construct with string value and attribute") {
    var e1 = XElement.new("name", XAttribute.new("name", "attrValue"), "elementValue")
    Assert.equal(e1.value, "elementValue")
    Assert.countOf(e1.attributes, 1)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: Construct with non-string value and attribute") {
    var e2 = XElement.new("name", XAttribute.new("name", "attrValue"), 2)
    Assert.equal(e2.value, "2")
    Assert.countOf(e2.attributes, 1)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Document: Add and remove element") {
    var parent = XDocument.new()
    var child = XElement.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Document: Add and remove comment") {
    var parent = XDocument.new()
    var child = XComment.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)

    parent.remove(child)
    Assert.countOf(parent.nodes, 0)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Document: Add sequence") {
    var parent = XDocument.new()
    var childElement = XElement.new("child")
    var childComment = XComment.new("child")
    var children = [childElement, childComment]
    parent.add(children)
    Assert.countOf(parent.nodes, 2)
    Assert.countOf(parent.elements, 1)
    Assert.countOf(parent.comments, 1)
    var cElem = parent.nodes[0]
    var cComm = parent.nodes[1]
    Assert.equal(cElem, childElement)
    Assert.equal(cComm, childComment)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Document: Constructor syntax without square brackets") {
    var expected = 
        XDocument.new([
            XComment.new("TheFirstComment"),
            XElement.new("danio", [
                XAttribute.new("name", "zebra"),
                XAttribute.new("color", "red")
            ]),
            XComment.new("TheComment")
        ])
    
    var actual = 
        XDocument.new(
            XComment.new("TheFirstComment"),
            XElement.new("danio",
                XAttribute.new("name", "zebra"),
                XAttribute.new("color", "red")
            ),
            XComment.new("TheComment")
        )

    AssertCustom.documentIdentical(actual, expected)
}

Test.run("Element: attributeOrAbort") {
    var a = XAttribute.new("hello", "there")
    var e = XElement.new("name", a)

    Assert.aborts(Fn.new { a.attributeOrAbort("hi") })
    Assert.equal(e.attributeOrAbort("hello"), a)
}

Test.run("Element: elementOrAbort") {
    var a = XElement.new("hello")
    var e = XElement.new("name", a)

    Assert.aborts(Fn.new { a.elementOrAbort("hi") })
    Assert.equal(e.elementOrAbort("hello"), a)
}

Test.run("Document: elementOrAbort") {
    var a = XElement.new("hello")
    var e = XDocument.new(a)

    Assert.aborts(Fn.new { a.elementOrAbort("hi") })
    Assert.equal(e.elementOrAbort("hello"), a)
}

////////////////////////////////////////////////////////////////////////////////
// TEST CONVERTERS /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: value converts to num") {
    var a = XAttribute.new("name", "24")
    var b = XAttribute.new("name", "hello")

    Assert.equal(a.value(Num), 24)
    Assert.aborts(Fn.new { b.value(Num) })
    Assert.equal(a.value(Num, 5), 24)
    Assert.equal(b.value(Num, 5), 5)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: value converts to bool") {
    var a = XAttribute.new("name", "true")
    var b = XAttribute.new("name", "hello")

    Assert.equal(a.value(Bool), true)
    Assert.aborts(Fn.new { b.value(Bool) })
    Assert.equal(a.value(Bool, false), true)
    Assert.equal(b.value(Bool, false), false)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: value converts to string") {
    var a = XAttribute.new("name", "true")
    var b = XAttribute.new("name", "hello")

    Assert.equal(a.value(String), "true")
    Assert.equal(a.value(String, "aloha"), "true")
    Assert.equal(b.value(String, "wahoo"), "hello")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: value converts to num") {
    var a = XElement.new("name", "24")
    var b = XElement.new("name", "hello")

    Assert.equal(a.value(Num), 24)
    Assert.aborts(Fn.new { b.value(Num) })
    Assert.equal(a.value(Num, 5), 24)
    Assert.equal(b.value(Num, 5), 5)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: value converts to bool") {
    var a = XElement.new("name", "true")
    var b = XElement.new("name", "hello")

    Assert.equal(a.value(Bool), true)
    Assert.aborts(Fn.new { b.value(Bool) })
    Assert.equal(a.value(Bool, false), true)
    Assert.equal(b.value(Bool, false), false)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: value converts to string") {
    var a = XElement.new("name", "true")
    var b = XElement.new("name", "hello")

    Assert.equal(a.value(String), "true")
    Assert.equal(a.value(String, "aloha"), "true")
    Assert.equal(b.value(String, "wahoo"), "hello")
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: attribute value is null if missing") {
    var a = XElement.new("name", XAttribute.new("hello", "24"))

    Assert.equal(a.attributeValue("hello"), "24")
    Assert.notExists(a.attributeValue("hi"))
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: attribute value converts to num") {
    var a = XElement.new("name", XAttribute.new("hello", "24"))

    Assert.equal(a.attributeValue("hello", Num), 24)
    Assert.aborts(Fn.new { a.attributeValue("hi", Num) })
    Assert.equal(a.attributeValue("hello", Num, 6), 24)
    Assert.equal(a.attributeValue("hi", Num, 6), 6)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: element value converts to num") {
    var a = XElement.new("name", XElement.new("hello", "24"))

    Assert.equal(a.elementValue("hello", Num), 24)
    Assert.aborts(Fn.new { a.attributeValue("hi", Num) })
    Assert.equal(a.elementValue("hello", Num, 6), 24)
    Assert.equal(a.elementValue("hi", Num, 6), 6)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Element: element value is null if missing") {
    var a = XElement.new("name", XElement.new("hello", "24"))

    Assert.equal(a.elementValue("hello"), "24")
    Assert.notExists(a.elementValue("hi"))
}

////////////////////////////////////////////////////////////////////////////////
// TEST STRINGIFY //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify attribute") {
    var attribute = XAttribute.new("fish", "swi&m")
    var actual = attribute.toString
    var expected = "fish=\"swi&amp;m\""
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify comment") {
    var comment = XComment.new("hell&o")
    var actual = comment.toString
    var expected = "<!--hell&o-->"
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify comment with escape") {
    var comment = XComment.new("hello<!---->")
    var actual = comment.toString
    var expected = "<!--hello<!- - - - >-->"
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify xtext") {
    var text = XText.new(" hel&lo\n")
    var actual = text.toString
    var expected = " hel&amp;lo\n"
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify cdata") {
    var cdata = XCData.new(" hel&lo<node></node>]]>\n")
    var actual = cdata.toString
    var expected = "<![CDATA[ hel&lo<node></node>] ]>\n]]>"
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify element") {
    var element = 
        XElement.new("fishies", [
            XAttribute.new("amount", 2),
            XElement.new("danio", [
                XAttribute.new("name", "zebra"),
                XAttribute.new("color", "red")
            ]),
            XComment.new("TheComment"),
            XElement.new("danio", [
                XAttribute.new("name", "pea<rl"),
                XAttribute.new("color", "pink"),
                XElement.new("danio")
            ]),
            XElement.new("danio", "val>ue"),
            XElement.new("danio", XCData.new("<fishyfish/>"))
        ])

    var expected = """
<fishies amount="2">
  <danio name="zebra" color="red"/>
  <!--TheComment-->
  <danio name="pea&lt;rl" color="pink">
    <danio/>
  </danio>
  <danio>val&gt;ue</danio>
  <danio><![CDATA[<fishyfish/>]]></danio>
</fishies>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

Test.run("Stringify element with mixed content") {
    var element = 
        XElement.new("fishies", [
            "a danio ",
            XElement.new("is"),
            XText.new(" a fish "),
            XAttribute.new("amount", 2),
            XElement.new("which", XElement.new("swims")),
        ])

    var expected = """<fishies amount="2">a danio <is/> a fish <which><swims/></which></fishies>"""

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify document") {
    var doc = XDocument.new(
        XElement.new("Root", 
            XAttribute.new("attribute", "of root")
        ),
        XComment.new("A Comment")
    )

    var expected = """
<?xml version="1.0" encoding="utf-8"?>
<Root attribute="of root"/>
<!--A Comment-->
""".trim().replace("\r\n", "\n")

    var actual = doc.toString
    Assert.equal(actual, expected)

}

////////////////////////////////////////////////////////////////////////////////
// TEST STRINGIFY WITH NAMESPACES //////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify attribute with namespace") {
    var attribute = XAttribute.new("{ocean}fish", "swim")
    var ns = NamespaceStack.new()
    ns.push()
    ns.setPrefixValue("o", "ocean")
    var actual = ""
    var writer = XWriter.new(ns) {|x| actual = actual + x }
    writer.writeAttribute(attribute)
    var expected = "o:fish=\"swim\""
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify single element with attribute namespace") {
    var element = 
        XElement.new("danio", [
                XAttribute.new(XName.build("https://www.fish.com", "name"), "zebra"),
                XAttribute.xmlns("fish", "https://www.fish.com")
            ])

    var expected = """
<danio fish:name="zebra" xmlns:fish="https://www.fish.com"/>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify single element with element namespace and closing tag") {
    var element = 
        XElement.new(XName.build("https://www.fish.com", "danio"), [
                XAttribute.new("name", "zebra"),
                XAttribute.xmlns("fish", "https://www.fish.com"),
                "fishy wishy"
            ])

    var expected = """
<fish:danio name="zebra" xmlns:fish="https://www.fish.com">fishy wishy</fish:danio>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify single element with default element namespace") {
    var element = 
        XElement.new(XName.build("https://www.fish.com", "danio"), [
                XAttribute.new("name", "zebra"),
                XAttribute.xmlns("https://www.fish.com")
            ])

    var expected = """
<danio name="zebra" xmlns="https://www.fish.com"/>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify advanced namespace element") {
    var w = "{http://schemas.microsoft.com/winfx/2006/xaml/presentation}"
    var x = "{http://schemas.microsoft.com/winfx/2006/xaml}"
    var controls = "{clr-namespace:RanseiLink.Controls}"
    var element = 
        XElement.new(w + "UserControl",
            XAttribute.new(x + "Class", "RanseiLink.Controls.ModInfoControl"),
            XAttribute.xmlns("http://schemas.microsoft.com/winfx/2006/xaml/presentation"),
            XAttribute.xmlns("x", "http://schemas.microsoft.com/winfx/2006/xaml"),
            XAttribute.xmlns("controls", "clr-namespace:RanseiLink.Controls"),
            XElement.new(w + "StackPanel",
                XElement.new(w + "TextBlock", XAttribute.new(x + "Name", "NameTextBlock"), XAttribute.new("Text", "Mod Name")),
                XElement.new(controls + "ModInfoControl", XAttribute.new("ModInfo", "{Binding Mod}"))
            )
        )

    var expected = """
<UserControl x:Class="RanseiLink.Controls.ModInfoControl" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:controls="clr-namespace:RanseiLink.Controls">
  <StackPanel>
    <TextBlock x:Name="NameTextBlock" Text="Mod Name"/>
    <controls:ModInfoControl ModInfo="{Binding Mod}"/>
  </StackPanel>
</UserControl>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify single element attribute uses explicit namespace") {
    var ns = "https://www.fish.com"
    var nw = "{https://www.fish.com}"
    var element = 
        XElement.new("fishies",
            XAttribute.xmlns("fish", ns),
            XElement.new(nw + "danio",
                XAttribute.new(nw + "name", "zebra"),
                XAttribute.xmlns(ns)
            )
        )

    var expected = """
<fishies xmlns:fish="https://www.fish.com">
  <danio fish:name="zebra" xmlns="https://www.fish.com"/>
</fishies>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

////////////////////////////////////////////////////////////////////////////////
// TEST PARSING ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Parse attribute") {
    var attributeString = "attrName=\"the attribute value\""
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse attribute shortcut") {
    var attributeString = "attrName=\"the attribute value\""
    var attribute = XAttribute.parse(attributeString)
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse attribute apostrophe") {
    var attributeString = "attrName='the attribute value'"
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse attribute extra spaces") {
    var attributeString = "attrName = \"the attribute value\""
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

////////////////////////////////////////////////////////////////////////////////

var escapeTestCases = [
    ["&amp;", "&"],
    ["&quot;", "\""],
    ["&lt;", "<"],
    ["&gt;", ">"],
    ["&apos;", "'"],
    ["&#x00C9;", "\u00c9"],
    ["&#201;", "\u00c9"]
]
for (case in escapeTestCases) {
    Test.run("Parse escape %(case[0])") {
        var escapeString = case[0]
        var parser = XParser.new(escapeString)
        var escape = parser.parseEscapeSequence()
        Assert.typeOf(escape, String)
        Assert.equal(escape, case[1])
    }
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse attribute with escape") {
    var attributeString = "attrName=\"&lt;the attribute&amp; value &gt;&gt;\""
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "<the attribute& value >>")
    AssertCustom.attributeIdentical(attribute, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse cdata") {
    var cdataString = "<![CDATA[some <stuff>]]>"
    var parser = XParser.new(cdataString)
    var result = parser.parseCData()
    var expected = XCData.new("some <stuff>")
    AssertCustom.cdataIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element no-content no attributes") {
    var elementString = "<Elem/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element no-content no attributes shortcut") {
    var elementString = "<Elem/>"
    var result = XElement.parse(elementString)
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element no-content one attribute") {
    var elementString = "<Elem attr=\"val\"/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val")])
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element no-content two attributes") {
    var elementString = "<Elem attr=\"val\" another=\"anotherval\" />"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val"), XAttribute.new("another", "anotherval")])
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element empty-content no attributes") {
    var elementString = "<Elem></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element empty-content one attribute") {
    var elementString = "<Elem attr=\"val\"></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val")])
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with text content") {
    var elementString = "<Elem>hello</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", "hello")
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with text content with surrounding whitespace") {
    var elementString = "<Elem> hello  </Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", " hello  ")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with multi-byte code points") {
    var elementString = "<name>Pokémon</name>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("name", "Pokémon")
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with single element content") {
    var elementString = "<Elem><Child/></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", XElement.new("Child"))
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with single element content with surrounding whitespace") {
    var elementString = "<Elem>\n  <Child/>\n</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", XElement.new("Child"))
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with multiple elements") {
    var elementString = "<Elem>\n  <Child1/>\n  <Child2/>\n</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XElement.new("Child1"), XElement.new("Child2")])
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with multiple single nested") {
    var elementString = """<Elem>
                             <Child1>
                               <GrandChild1/>
                               <GrandChild2/>
                             </Child1>
                             <Child2>grandchild</Child2>
                           </Elem>
                        """
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [
        XElement.new("Child1", [
            XElement.new("GrandChild1"),
            XElement.new("GrandChild2")
        ]),
        XElement.new("Child2", "grandchild")
    ])
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with comments") {
    var elementString = """<Elem>
                             <!-- Comment -->
                             <Child/>
                             <!-- Another Comment -->
                           </Elem>
                        """
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", 
        XComment.new(" Comment "), 
        XElement.new("Child"), 
        XComment.new(" Another Comment ")
        )
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse element with escape value") {
    var elementString = """<description>Sky watchers in Europe, Asia, and parts of Alaska and Canada will experience a &lt;a href="http://science.nasa.gov/headlines/y2003/30may_solareclipse.htm"&gt;partial eclipse of the Sun&lt;/a&gt; on Saturday, May 31st.</description>"""
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("description", 
        """Sky watchers in Europe, Asia, and parts of Alaska and Canada will experience a <a href="http://science.nasa.gov/headlines/y2003/30may_solareclipse.htm">partial eclipse of the Sun</a> on Saturday, May 31st."""
        )
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse document") {
    var documentString = """
<?xml version="1.0" encoding="utf-8"?>
<Root attribute="of root"/>
"""

    var expected = XDocument.new(
        XElement.new("Root", 
            XAttribute.new("attribute", "of root")
        )
    )

    var parser = XParser.new(documentString)
    var result = parser.parseDocument()

    AssertCustom.documentIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse document shortcut") {
    var documentString = """
<?xml version="1.0" encoding="utf-8"?>
<Root attribute="of root"/>
"""

    var expected = XDocument.new(
        XElement.new("Root", 
            XAttribute.new("attribute", "of root")
        )
    )

    var result = XDocument.parse(documentString)

    AssertCustom.documentIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse document with comments") {
    var documentString = """
<!-- comment 1 -->
<!-- comment 2 -->
<Root attribute="of root"/>
"""

    var expected = XDocument.new(
        XComment.new(" comment 1 "),
        XComment.new(" comment 2 "),
        XElement.new("Root", 
            XAttribute.new("attribute", "of root")
        )
    )

    var parser = XParser.new(documentString)
    var result = parser.parseDocument()

    AssertCustom.documentIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////
// TEST PARSING WITH NAMESPACES ////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Parse single element with attribute namespace") {
    var elementString = "<Elem b:attr=\"val\" xmlns:b=\"bird\"/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", 
        XAttribute.new("{bird}attr", "val"),
        XAttribute.xmlns("b", "bird")
        )
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse single element with explicit element namespace") {
    var elementString = "<b:Elem attr=\"val\" xmlns:b=\"bird\"/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("{bird}Elem", 
        XAttribute.new("attr", "val"),
        XAttribute.xmlns("b", "bird")
        )
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse single element with implicit element namespace") {
    var elementString = "<Elem attr=\"val\" xmlns=\"bird\"/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("{bird}Elem", 
        XAttribute.new("attr", "val"),
        XAttribute.xmlns("bird")
        )
    AssertCustom.elementIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse advanced namespace element") {
    var w = "{http://schemas.microsoft.com/winfx/2006/xaml/presentation}"
    var x = "{http://schemas.microsoft.com/winfx/2006/xaml}"
    var controls = "{clr-namespace:RanseiLink.Controls}"
    var expected = XDocument.new(
        XElement.new(w + "UserControl",
            XAttribute.new(x + "Class", "RanseiLink.Controls.ModInfoControl"),
            XAttribute.xmlns("http://schemas.microsoft.com/winfx/2006/xaml/presentation"),
            XAttribute.xmlns("x", "http://schemas.microsoft.com/winfx/2006/xaml"),
            XAttribute.xmlns("controls", "clr-namespace:RanseiLink.Controls"),
            XElement.new(w + "StackPanel",
                XElement.new(w + "TextBlock", XAttribute.new(x + "Name", "NameTextBlock"), XAttribute.new("Text", "Mod Name")),
                XElement.new(controls + "ModInfoControl", XAttribute.new("ModInfo", "{Binding Mod}"))
            )
        )
    )

    var documentString = """
<UserControl x:Class="RanseiLink.Controls.ModInfoControl" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:controls="clr-namespace:RanseiLink.Controls">
  <StackPanel>
    <TextBlock x:Name="NameTextBlock" Text="Mod Name"/>
    <controls:ModInfoControl ModInfo="{Binding Mod}"/>
  </StackPanel>
</UserControl>
"""

    var parser = XParser.new(documentString)
    var result = parser.parseDocument()

    AssertCustom.documentIdentical(result, expected)
}

////////////////////////////////////////////////////////////////////////////////

Test.run("Parse namespace priority is respected") {
    var expected = XDocument.new(
        XElement.new("{https://www.shark.com}fishies",
            XAttribute.xmlns("https://www.shark.com"),
            XAttribute.xmlns("r", "bunny"),
            XAttribute.new("{bunny}names", "zebras"),
            XElement.new("{https://www.fish.com}danio",
                XAttribute.new("{rabbit}name", "zebra"),
                XAttribute.xmlns("https://www.fish.com"),
                XAttribute.xmlns("r", "rabbit")
            )
        )
    )

    var documentString = """
<fishies xmlns="https://www.shark.com" xmlns:r="bunny" r:names="zebras">
  <danio r:name="zebra" xmlns="https://www.fish.com" xmlns:r="rabbit"/>
</fishies>
"""

    var parser = XParser.new(documentString)
    var result = parser.parseDocument()

    AssertCustom.documentIdentical(result, expected)
}

///"""////////////////////////////////////////////////////
// TEST PARSING FILES
//////////////////////////////////////////////////////////

Test.run("File with utf8 BOM") {
    var text = File.read("test_data/file_with_bom.xml")
    var doc = XDocument.parse(text) // shouldn't assert
}

Test.run("Invalid file should abort") {
    var text = File.read("test_data/test_image.png")
    Assert.aborts {
        var doc = XDocument.parse(text)
    }
}

////////////////////////////////////////////////////////////////////////////////
// END TESTS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

System.print("\n-- TESTING COMPLETE --\n")

System.print("PASSED: %(PASSED_TEST_COUNT)/%(PASSED_TEST_COUNT + FAILED_TEST_COUNT)")
