
import "./xsequence" for XDocument, XElement, XAttribute, XParser
import "./wren-assert" for Assert

var DEBUG = false // set true to view the full callstack from a failed test

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
            System.print("+ Passed test '%(name)'")
        } else {
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
        Assert.countOf(actual.elements, expected.elements.count)
        for (i in 0...actual.elements.count) {
            AssertCustom.elementIdentical(actual.elements[i], expected.elements[i])
        }
    }

    static documentIdentical(actual, expected) {
        Assert.typeOf(actual, XDocument)
        Assert.typeOf(expected, XDocument)
        elementIdentical(actual.root, expected.root)
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
            XElement.new("danio", [
                XAttribute.new("name", "pea<rl"),
                XAttribute.new("color", "pink")
            ]),
            XElement.new("danio", "val>ue")
        ])

    var expected = """
<fishies amount="2">
  <danio name="zebra" color="red"/>
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
        )
    )

    var expected = """
<?xml version="1.0" encoding="utf-8"?>
<Root attribute="of root"/>
""".trim().replace("\r\n", "\n")

    var actual = doc.toString
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
    ["&apos;", "'"]
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
    var expected = XElement.new("Elem", XElement.new("Child"))
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

Test.run("Parse document with comments") {
    var documentString = """
<!-- comment 1 -->
<!-- comment 2 -->
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
// END TESTS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

System.print("\n-- TESTING COMPLETE --\n")