
import "./xsequence" for XDocument, XElement, XAttribute, XComment, XParser
import "./wren-assert" for Assert

var DEBUG = false // set true to view the full callstack from a failed test

var PASSED_TEST_COUNT = 0
var FAILED_TEST_COUNT = 0

class Test {
    static run(name, callable) {
        if (DEBUG) {
            System.print("Running test '%(name)'")
            callable.call()
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
        Assert.equal(actual.value, expected.value)
        Assert.countOf(actual.attributes, expected.attributes.count)
        for (i in 0...actual.attributes.count) {
            AssertCustom.attributeIdentical(actual.attributes[i], expected.attributes[i])
        }
        Assert.countOf(actual.nodes, expected.nodes.count)
        for (i in 0...actual.elements.count) {
            AssertCustom.nodeIdentical(actual.nodes[i], expected.nodes[i])
        }
    }

    static documentIdentical(actual, expected) {
        Assert.typeOf(actual, XDocument)
        Assert.typeOf(expected, XDocument)
        Assert.countOf(actual.nodes, expected.nodes.count)
        for (i in 0...actual.elements.count) {
            AssertCustom.nodeIdentical(actual.nodes[i], expected.nodes[i])
        }
    }

    static commentIdentical(actual, expected) {
        Assert.typeOf(actual, XComment)
        Assert.typeOf(expected, XComment)
        Assert.equal(actual.value, expected.value)
    }

    static nodeIdentical(actual, expected) {
        if (expected is XComment) {
            commentIdentical(actual, expected)
        } else if (expected is XElement) {
            elementIdentical(actual, expected)
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
// TEST SYNTAX /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Attribute: Set value converted to string") {
    var a = XAttribute.new("name", 69)
    Assert.equal(a.value, "69")
    a.value = 4
    Assert.equal(a.value, "4")
}

Test.run("Element: Set value converted to string") {
    var e = XElement.new("name", 69)
    Assert.equal(e.value, "69")
    e.value = 2
    Assert.equal(e.value, "2")
}

Test.run("Comment: Set value converted to string") {
    var c = XComment.new(69)
    Assert.equal(c.value, "69")
    c.value = 0
    Assert.equal(c.value, "0")
}

Test.run("Element: Add element") {
    var parent = XElement.new("parent")
    var child = XElement.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)
}

Test.run("Element: Add comment") {
    var parent = XElement.new("parent")
    var child = XComment.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)
}

Test.run("Element: Add attribute") {
    var parent = XElement.new("parent")
    var child = XAttribute.new("child", "attribute content")
    parent.add(child)
    Assert.countOf(parent.attributes, 1)
    var c = parent.attributes[0]
    Assert.equal(c, child)
}

Test.run("Element: Duplicate attributes should abort fiber") {
    var parent = XElement.new("parent")
    var child1 = XAttribute.new("child", "attribute content")
    var child2 = XAttribute.new("child", "other attribute content")
    parent.add(child1)
    Assert.aborts(Fn.new { parent.add(child2) })
}

Test.run("Element: Add string aborts fiber") {
    var element = XElement.new("name")
    Assert.aborts(Fn.new { element.add("string value") })
}

Test.run("Document: Add string aborts fiber") {
    var doc = XDocument.new()
    Assert.aborts(Fn.new { doc.add("string value") })
}

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

Test.run("Element: Construct with string value and attribute") {
    var e1 = XElement.new("name", XAttribute.new("name", "attrValue"), "elementValue")
    Assert.equal(e1.value, "elementValue")
    Assert.countOf(e1.attributes, 1)
}

Test.run("Element: Construct with non-string value and attribute") {
    var e2 = XElement.new("name", XAttribute.new("name", "attrValue"), 2)
    Assert.equal(e2.value, "2")
    Assert.countOf(e2.attributes, 1)
}

Test.run("Document: Add element") {
    var parent = XDocument.new()
    var child = XElement.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)
}

Test.run("Document: Add comment") {
    var parent = XDocument.new()
    var child = XComment.new("child")
    parent.add(child)
    Assert.countOf(parent.nodes, 1)
    var c = parent.nodes[0]
    Assert.equal(c, child)
}

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

////////////////////////////////////////////////////////////////////////////////
// TEST STRINGIFY //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Test.run("Stringify attribute") {
    var attribute = XAttribute.new("fish", "swi&m")
    var actual = attribute.toString
    var expected = "fish=\"swi&amp;m\""
    Assert.equal(actual, expected)
}

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
                XAttribute.new("color", "pink")
            ]),
            XElement.new("danio", "val>ue")
        ])

    var expected = """
<fishies amount="2">
  <danio name="zebra" color="red"/>
  <!--TheComment-->
  <danio name="pea&lt;rl" color="pink"/>
  <danio>val&gt;ue</danio>
</fishies>
""".trim().replace("\r\n", "\n")

    var actual = element.toString
    Assert.equal(actual, expected)
}

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

Test.run("Stringify comment") {
    var comment = XComment.new("hell&o")
    var actual = comment.toString
    var expected = "<!--hell&o-->"
    Assert.equal(actual, expected)
}

Test.run("Stringify comment with escape") {
    var comment = XComment.new("hello<!---->")
    var actual = comment.toString
    var expected = "<!--hello<!- - - - >-->"
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

Test.run("Parse attribute shortcut") {
    var attributeString = "attrName=\"the attribute value\""
    var attribute = XAttribute.parse(attributeString)
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

Test.run("Parse attribute apostrophe") {
    var attributeString = "attrName='the attribute value'"
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "the attribute value")
    AssertCustom.attributeIdentical(attribute, expected)
}

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

Test.run("Parse attribute with escape") {
    var attributeString = "attrName=\"&lt;the attribute&amp; value &gt;&gt;\""
    var parser = XParser.new(attributeString)
    var attribute = parser.parseAttribute()
    var expected = XAttribute.new("attrName", "<the attribute& value >>")
    AssertCustom.attributeIdentical(attribute, expected)
}

Test.run("Parse element no-content no attributes") {
    var elementString = "<Elem/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element no-content no attributes shortcut") {
    var elementString = "<Elem/>"
    var result = XElement.parse(elementString)
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element no-content one attribute") {
    var elementString = "<Elem attr=\"val\"/>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val")])
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element no-content two attributes") {
    var elementString = "<Elem attr=\"val\" another=\"anotherval\" />"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val"), XAttribute.new("another", "anotherval")])
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element empty-content no attributes") {
    var elementString = "<Elem></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element empty-content one attribute") {
    var elementString = "<Elem attr=\"val\"></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XAttribute.new("attr", "val")])
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with text content") {
    var elementString = "<Elem>hello</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", "hello")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with text content with surrounding whitespace") {
    var elementString = "<Elem> hello  </Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", " hello  ")
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with single element content") {
    var elementString = "<Elem><Child/></Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", XElement.new("Child"))
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with single element content with surrounding whitespace") {
    var elementString = "<Elem>\n  <Child/>\n</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", XElement.new("Child"))
    AssertCustom.elementIdentical(result, expected)
}

Test.run("Parse element with multiple elements") {
    var elementString = "<Elem>\n  <Child1/>\n  <Child2/>\n</Elem>"
    var parser = XParser.new(elementString)
    var result = parser.parseElement()
    var expected = XElement.new("Elem", [XElement.new("Child1"), XElement.new("Child2")])
    AssertCustom.elementIdentical(result, expected)
}

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
// END TESTS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

System.print("\n-- TESTING COMPLETE --\n")

System.print("PASSED: %(PASSED_TEST_COUNT)/%(PASSED_TEST_COUNT + FAILED_TEST_COUNT)")