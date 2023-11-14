/*

 XSequence
 
 Version : 3.1.2
 Author  : Deijin27
 Licence : MIT
 Website : https://github.com/deijin27/wren-xsequence

 */

#doc = "A utility class for working with XML namespaces. You will probably never need this"
class XNamespace {
    #doc = "The xmlns namespace value 'https://www.w3.org/2000/xmlns/'. It's easier to use XAttribute.xmlns"
    static xmlns { "https://www.w3.org/2000/xmlns/" }
    #doc = "The xml namespace value 'http://www.w3.org/XML/1998/namespace'. It's easier to use XAttribute.xml"
    static xml { "http://www.w3.org/XML/1998/namespace" }
}

#internal
class NamespaceStack {
    construct new() {
        _current = 0
        _stack = [{"xmlns": XNamespace.xmlns, "xml": XNamespace.xml}]
        _autoNsIncrement = -1
    }

    push() {
        _current = _current + 1
        if (_stack.count <= _current) {
            _stack.add({})
        }
    }

    pop() {
        // reuse the dictionaries rather than creating new ones each time
        _stack[_current].clear()
        _current = _current - 1
    }

    getValue(prefix) {
        for (i in _current..0) {
            var value = _stack[i][prefix]
            if (value != null) {
                return value
            }
        }
        Fiber.abort("Use of undefined namespace prefix '%(prefix)'")
    }

    tryGetValue(prefix) {
        for (i in _current..0) {
            var value = _stack[i][prefix]
            if (value != null) {
                return value
            }
        }
        return null
    }

    getPrefix(value) {
        for (i in _current..0) {
            var dict = _stack[i]
            for (kvp in dict) {
                if (kvp.value == value) {
                    var prefix = kvp.key
                    // make sure this is the latest defined one
                    // since the prefix could have been redefined
                    var valueBack = getValue(prefix)
                    if (valueBack == value) {
                        return prefix
                    }
                }
            }
        }
        Fiber.abort("Use of undefined namespace '%(value)'")
    }

    // gets a prefix corresponding to a namespace, else creates a new one
    // this specifically excludes the default namespace, which can't be used for attributes
    getNonDefaultPrefix(value) {
        for (i in _current..0) {
            var dict = _stack[i]
            for (kvp in dict) {
                if (kvp.value == value) {
                    var prefix = kvp.key
                    // make sure this isn't null
                    if (prefix == null) {
                        continue
                    }
                    // make sure this is the latest defined one
                    // since the prefix could have been redefined
                    var valueBack = getValue(prefix)
                    if (valueBack == value) {
                        return prefix
                    }
                }
            }
        }
        Fiber.abort("Use of undefined namespace '%(value)' in attribute which require explicit prefix")
        return prefix
    }

    setPrefixValue(prefix, value) {
        _stack[_current][prefix] = value
    }
}

#doc = "A utility class for working with XML names and namespaces"
class XName {
    #doc = "Split a string of format '{namespace}localName' into an XName which has properties to access it's namespace and local name"
    #arg(name=name)
    static split(name) {
        if (name[0] != "{") {
            // does not have namespace
            return XName.new_(null, name)
        } else {
            // has namespace
            var idx = name.indexOf("}")
            return XName.new_(name[1...idx], name[(idx + 1)..-1])
        }
    }

    #doc = "Build a name string from it's components"
    #arg(name=namespace)
    #arg(name=localName)
    static build(namespace, localName) {
        return "{%(namespace)}%(localName)"
    }

    construct new_(namespace, localName) {
        _localName = localName
        _namespace = namespace
    }

    #doc = "The namespace of this XML name"
    namespace { _namespace }
    #doc = "The local name of this XML name"
    localName { _localName }
    #doc = "Convert to string"
    toString {
        if (_namespace == null) {
            return _localName
        }
        return XName.build(_namespace, _localName)
    }

    static splitFast(name) {
        // name is "{blue}bird"
        if (name[0] != "{") {
            // does not have namespace
            return null
        } else {
            // has namespace
            var idx = name.indexOf("}")
            return XName.new_(name[1...idx], name[(idx + 1)..-1])
        }
    }

    static splitPrefixFast(name) {
        // name is "b:bird"
        var colonPos = name.indexOf(":")
        if (colonPos == -1) {
            return null
        } else {
            return XName.new_(name[0...colonPos], name[(colonPos+1)..-1])
        }
    }
}

#internal
class XWriter {

    construct new(writerCallable) {
        _writerCallable = writerCallable
        _namespaceStack = NamespaceStack.new()
        __xmlnsWrapped = "{%(XNamespace.xmlns)}"
    }

    construct new(namespaceStack, writerCallable) {
        _writerCallable = writerCallable
        _namespaceStack = namespaceStack
        __xmlnsWrapped = "{%(XNamespace.xmlns)}"
    }

    static escape(str) {
        return str
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }

    // Namespace-Aware Writers

    writeComment(comment) {
        _writerCallable.call("<!--")
        // comments only disallow "--"
        _writerCallable.call(comment.value.replace("--", "- - "))
        _writerCallable.call("-->")
    }

    writeText(text) {
        var value = XWriter.escape(text.value)
        _writerCallable.call(value)
    }

    writeCData(cdata) {
        _writerCallable.call("<![CDATA[")
        // escape what could be misinterpreted as the closing tag
        _writerCallable.call(cdata.value.replace("]]>", "] ]>"))
        _writerCallable.call("]]>")
    }

    writeAttribute(attribute) {
        var value = XWriter.escape(attribute.value)
        // handle namespace
        var name = resolveAttributeName(attribute)
        _writerCallable.call("%(name)=\"%(value)\"")
    }

    writeElement(element) {
        writeElement(element, "")
    }

    loadNamespacesFromAttributes(element) {
        for (attribute in element.attributes) {
            if (attribute.name == "xmlns") {
                _namespaceStack.setPrefixValue(null, attribute.value) 
            } else if (attribute.name.startsWith(__xmlnsWrapped)) {
                _namespaceStack.setPrefixValue(attribute.name[__xmlnsWrapped.count..-1], attribute.value)
            }
        }
    }

    resolveAttributeName(attribute) {
        var name = attribute.name
        var split = XName.splitFast(attribute.name)
        if (split != null) {
            var prefix = _namespaceStack.getNonDefaultPrefix(split.namespace)
            name = "%(prefix):%(split.localName)"
        }
        return name
    }

    resolveElementName(element) {
        var name = element.name
        var elementNameSplit = XName.splitFast(element.name)
        if (elementNameSplit != null) {
            var prefix = _namespaceStack.getPrefix(elementNameSplit.namespace)
            // if the prefix is xmlns, which may have been defined above when parsing the attributes
            // then that is the default namespace, and can be omitted
            if (prefix != null) {
                name = "%(prefix):%(elementNameSplit.localName)"
            } else {
                name = elementNameSplit.localName
            }
        }
        return name
    }

    writeElement(element, indent) {
        // begin a new namespace scope for each element
        _namespaceStack.push()

        // load namespaces from attributes
        loadNamespacesFromAttributes(element)

        // get the element's name, applying namespace prefix if necessary
        var name = resolveElementName(element)

        // write element opening tag
        _writerCallable.call("<%(name)")
        
        // write attributes
        for (attribute in element.attributes) {
            _writerCallable.call(" ")
            writeAttribute(attribute)
        }

        if (element.nodes.count > 0) {
            _writerCallable.call(">")
            if (indent == null || element.nodes.any {|x| x is XText }) {
                // because there are xtext nodes we cannot have fancy 
                // whitespace because it's text / mixed content
                for (node in element.nodes) {
                    node.writeWith(this, null)
                }
                _writerCallable.call("</%(name)>")
            } else {
                // write content nodes that are not xtext
                // here we can have fancy whitespace
                var newIndent = indent + "  "
                for (node in element.nodes) {
                    _writerCallable.call("\n" + newIndent)
                    node.writeWith(this, newIndent)
                }
                _writerCallable.call("\n%(indent)</%(name)>")
            }
        } else {
            // element has no value, write short closing tag
            _writerCallable.call("/>")
        }

        // end the namespace scope when element has been written
        _namespaceStack.pop()
    }

    writeDocument(document) {
        _writerCallable.call("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
        var indent = ""
        for (node in document.nodes) {
            _writerCallable.call("\n")
            node.writeWith(this, indent)
        }
    }
}

#internal
class Code {
    static EOF           { -2   } // end of file (not using -1 because it's a common default so sometimes bugs can lead to false positives for EOF)
    
    static NEWLINE       { 0x0A } // \n
    static TAB           { 0x09 } // \t
    static CARRIAGE_RETURN { 0x0D } // \r
    

    static SPACE         { 0x20 } //  
    static EXCLAMATION   { 0x21 } // !
    static QUOTATION     { 0x22 } // "
    static HASH          { 0x23 } // #
    static DOLLAR        { 0x24 } // $
    static PERCENT       { 0x25 } // %
    static AMPERSAND     { 0x26 } // &
    static APOSTROPHE    { 0x27 } // '
    static LEFT_BRACKET  { 0x28 } // (
    static RIGHT_BRACKET { 0x29 } // )
    static ASTERISK      { 0x2A } // *
    static PLUS          { 0x2B } // +
    static COMMA         { 0x2C } // ,
    static DASH          { 0x2D } // -
    static FULL_STOP     { 0x2E } // .
    static SLASH         { 0x2F } // /
    static ZERO          { 0x30 } // 0
    static ONE           { 0x31 } // 1
    static TWO           { 0x32 } // 2
    static THREE         { 0x33 } // 3
    static FOUR          { 0x34 } // 4
    static FIVE          { 0x35 } // 5
    static SIX           { 0x36 } // 6
    static SEVEN         { 0x37 } // 7
    static EIGHT         { 0x38 } // 8
    static NINE          { 0x39 } // 9
    static COLON         { 0x3A } // :
    static SEMICOLON     { 0x3B } // ;
    static LESS_THAN     { 0x3C } // <
    static EQUAL         { 0x3D } // =
    static GREATER_THAN  { 0x3E } // >
    static QUESTION      { 0x3F } // ?
    static AT            { 0x40 } // @
    static A_UPPER       { 0x41 } // A
    static B_UPPER       { 0x42 } // B
    static C_UPPER       { 0x43 } // C
    static D_UPPER       { 0x44 } // D
    static E_UPPER       { 0x45 } // E
    static F_UPPER       { 0x46 } // F
    static G_UPPER       { 0x47 } // G
    static H_UPPER       { 0x48 } // H
    static I_UPPER       { 0x49 } // I
    static J_UPPER       { 0x4A } // J
    static K_UPPER       { 0x4B } // K
    static L_UPPER       { 0x4C } // L
    static M_UPPER       { 0x4D } // M
    static N_UPPER       { 0x4E } // N
    static O_UPPER       { 0x4F } // O
    static P_UPPER       { 0x50 } // P
    static Q_UPPER       { 0x51 } // Q
    static R_UPPER       { 0x52 } // R 
    static S_UPPER       { 0x53 } // S
    static T_UPPER       { 0x54 } // T
    static U_UPPER       { 0x55 } // U
    static V_UPPER       { 0x56 } // V
    static W_UPPER       { 0x57 } // W
    static X_UPPER       { 0x58 } // X
    static Y_UPPER       { 0x59 } // Y
    static Z_UPPER       { 0x5A } // Z
    static LEFT_SQUARE   { 0x5B } // [
    static BACKSLASH     { 0x5C } // \
    static RIGHT_SQUARE  { 0x5D } // ]
    static CIRCUMFLEX    { 0x5E } // ^
    static UNDERSCORE    { 0x5F } // _
    static GRAVE         { 0x60 } // `
    static A_LOWER       { 0x61 } // a
    static B_LOWER       { 0x62 } // b
    static C_LOWER       { 0x63 } // c
    static D_LOWER       { 0x64 } // d
    static E_LOWER       { 0x65 } // e
    static F_LOWER       { 0x66 } // f
    static G_LOWER       { 0x67 } // g
    static H_LOWER       { 0x68 } // h
    static I_LOWER       { 0x69 } // i
    static J_LOWER       { 0x6A } // j
    static K_LOWER       { 0x6B } // k
    static L_LOWER       { 0x6C } // l
    static M_LOWER       { 0x6D } // m
    static N_LOWER       { 0x6E } // n
    static O_LOWER       { 0x6F } // o
    static P_LOWER       { 0x70 } // p
    static Q_LOWER       { 0x71 } // q
    static R_LOWER       { 0x72 } // r
    static S_LOWER       { 0x73 } // s
    static T_LOWER       { 0x74 } // t
    static U_LOWER       { 0x75 } // u
    static V_LOWER       { 0x76 } // v
    static W_LOWER       { 0x77 } // w
    static X_LOWER       { 0x78 } // x
    static Y_LOWER       { 0x79 } // y
    static Z_LOWER       { 0x7F } // z
    static LEFT_BRACE    { 0x7B } // {
    static VERTICAL_LINE { 0x7C } // |
    static RIGHT_BRACE   { 0x7D } // }
    static TILDE         { 0x7E } // ~
}

#internal
class XParser {
    construct new(source) {
        _namespaceStack = NamespaceStack.new()
        source = source.replace("\r", "")

        _cur = -1

        // indexing code points directly doesn't work because the indexes are 
        // to byte positions, not code point positions, so it you miss the start
        // of a multi-byte point, you end up with -1
        // we generate a list first in order to safely iterate through code points
        // https://wren.io/modules/core/string.html#codepoints
        _points = []
        for (p in source.codePoints) {
            _points.add(p)
        }
        _end = _points.count

        // skip utf-8 bom
        if (_points[0] == 65279) {
            _cur = _cur + 1
        }
        _line = 0
        _col = 0
    }

    peek() { peek(1) }
    peek(n) {
        var idx = _cur + n
        if (idx >= _end) return Code.EOF
        return _points[idx]
    }

    next() {
        advance()
        if (_cur >= _end) return Code.EOF
        return _points[_cur]
    }

    advance() {
        if (_points[_cur] == Code.NEWLINE) {
            _line = _line + 1
            _col = 0
        } else {
            _col = _col + 1
        }
        _cur = _cur + 1
    }

    expect(point) {
        var c = peek()
        if (c != point) {
            unexpected(c, "Expected %(String.fromCodePoint(point))")
        }
        advance()
    }

    expect2(pointOption1, pointOption2) {
        var c = peek()
        if (c != pointOption1 && c != pointOption2) {
            unexpected(c)
        }
        advance()
    }

    unexpected(point) {
        unexpected(point, null)
    }

    unexpected(point, message) {
        var err = ""
        if (point == Code.EOF) {
            err = "end of file"
        } else if (point == Code.NEWLINE) {
            err = "newline"
        } else if (point == Code.TAB) {
            err = "tab"
        } else if (point == Code.SPACE) {
            err = "space"
        } else if (point == Code.CARRIAGE_RETURN) {
            err = "carriage return"
        } else {
            err = String.fromCodePoint(point)
        }
        advance()
        var errorMessage = "unexpected '%(err)' at line %(_line):%(_col)"
        if (message != null) {
            errorMessage = errorMessage + " (%(message))"
        }
        Fiber.abort(errorMessage)
    } 

    skipOptionalWhitespace() {
        while (isWhitespace(peek())) {
            advance()
        }
    }

    skipRequiredWhitespace() {
        var c = next()
        if (!isWhitespace(c)) {
            unexpected(c)
        }
        skipOptionalWhitespace()
    }

    isWhitespace(code) {
        return code == Code.SPACE || code == Code.NEWLINE || code == Code.TAB
    }

    parseDocument() {
        var doc = XDocument.new()
        while (true) {
            skipOptionalWhitespace()
            var p1 = peek()
            if (p1 == Code.EOF) {
                break
            } else if (p1 != Code.LESS_THAN) {
                unexpected(p1, "Expect < at start of node in document")
            }
            var p = peek(2)
            if (p == Code.EXCLAMATION) {
                doc.addComment(parseComment())
            } else if (p == Code.QUESTION) {
                parseDeclaration()
            } else {
                doc.addElement(parseElement())
            }
        }
        return doc
    }

    parseComment() {
        expect(Code.LESS_THAN)
        expect(Code.EXCLAMATION)
        expect(Code.DASH)
        expect(Code.DASH)

        var value = ""

        while (true) {
            var n = next()
            if (n == Code.EOF) {
                unexpected(Code.EOF)
            } else if (n == Code.DASH && peek() == Code.DASH && peek(2) == Code.GREATER_THAN) {
                advance()
                advance()
                break
            } else {
                value = value + String.fromCodePoint(n)
            }
        }

        return XComment.new(value)
    }

    parseCData() {
        expect(Code.LESS_THAN)
        expect(Code.EXCLAMATION)
        expect(Code.LEFT_SQUARE)
        expect(Code.C_UPPER)
        expect(Code.D_UPPER)
        expect(Code.A_UPPER)
        expect(Code.T_UPPER)
        expect(Code.A_UPPER)
        expect(Code.LEFT_SQUARE)

        var value = ""

        while (true) {
            var n = next()
            if (n == Code.EOF) {
                unexpected(Code.EOF)
            } else if (n == Code.RIGHT_SQUARE && peek() == Code.RIGHT_SQUARE && peek(2) == Code.GREATER_THAN) {
                advance()
                advance()
                break
            } else {
                value = value + String.fromCodePoint(n)
            }
        }

        return XCData.new(value)
    }

    parseDeclaration() {
        expect(Code.LESS_THAN)
        expect(Code.QUESTION)
        expect2(Code.X_UPPER, Code.X_LOWER)
        expect2(Code.M_UPPER, Code.M_LOWER)
        expect2(Code.L_UPPER, Code.L_LOWER)

        while (true) {
            var n = next()
            if (n == Code.EOF) {
                unexpected(n)
            }
            if (n == Code.QUESTION && peek() == Code.GREATER_THAN) {
                advance()
                break
            }
        }
    }

    parseElement() {
        // begin a new namespace scope for each element
        _namespaceStack.push()

        expect(Code.LESS_THAN)

        var name = parseElementName()

        var element = XElement.new(name)

        while (true) {

            var p = peek()

            if (p == Code.SLASH) {
                processElementNamespaces(element)
                // no-content closing tag
                advance()
                expect(Code.GREATER_THAN)
                break

            } else if (p == Code.GREATER_THAN) {
                // parse element content
                processElementNamespaces(element)
                advance()
                parseElementContentNodes(element)
                // post-content closing tag
                expect(Code.LESS_THAN)
                expect(Code.SLASH)
                for (c in name.codePoints) {
                    expect(c)
                }
                expect(Code.GREATER_THAN)
                break

            } else if (isWhitespace(p)) {
                // skip whitespace between attributes etc.
                skipOptionalWhitespace()

            } else if (p == Code.EOF) {
                unexpected(p)
            } else {
                var attr = parseAttribute()
                element.addAttribute(attr)
            }
        }
        
        // end namespace scope at end of element
        _namespaceStack.pop()
        return element
    }

    processElementNamespaces(element) {
        // load namespaces from attributes
        for (attribute in element.attributes) {
            if (attribute.name == "xmlns") {
                _namespaceStack.setPrefixValue(null, attribute.value) 
            } else if (attribute.name.startsWith("xmlns:")) {
                _namespaceStack.setPrefixValue(attribute.name[6..-1], attribute.value)
            }
        }

        // apply namespaces to elements
        var elementNameSplit = XName.splitPrefixFast(element.name)
        if (elementNameSplit != null) {
            var value = _namespaceStack.getValue(elementNameSplit.namespace)
            // if the prefix is xmlns, which may have been defined above when parsing the attributes
            // then that is the default namespace, and can be omitted
            if (value != null) {
                element.name = "{%(value)}%(elementNameSplit.localName)"
            } else {
                element.name = elementNameSplit.localName
            }
        } else {
            // if no prefix, and a default namespace is defined, apply that
            var defaultNs = _namespaceStack.tryGetValue(null)
            if (defaultNs != null) {
                element.name = "{%(defaultNs)}%(element.name)"
            }
        }

        // apply namespaces to attributes
        for (attribute in element.attributes) {
            var name = attribute.name
            var split = XName.splitPrefixFast(attribute.name)
            if (split != null) {
                var value = _namespaceStack.getValue(split.namespace)
                attribute.name = "{%(value)}%(split.localName)"
            }
        }
    }

    parseElementName() {
        var name = ""
        while (true) {
            var p = peek()
            if (isWhitespace(p) || p == Code.GREATER_THAN || p == Code.SLASH) {
                break
            } else if (p == Code.EOF) {
                unexpected(p)
            }
            name = name + String.fromCodePoint(p)
            advance()
        }
        return name
    }

    parseAttribute() {
        var name = ""
        while (true) {
            var p = next()
            
            if (p == Code.EQUAL) {
                break
            } else if (isWhitespace(p)) {
                skipOptionalWhitespace()
                expect(Code.EQUAL)
                break
            } else if (p == Code.EOF) {
                unexpected(p)
            }
            name = name + String.fromCodePoint(p)
        }

        // at this point we are immediately after the equals sign
        skipOptionalWhitespace()
        var val = parseAttributeValue()

        return XAttribute.new(name, val)
    }

    // parse an XText
    parseText() {
        var value = ""
        while (true) {
            var p = peek()
            if (p == Code.LESS_THAN) {
                // begin of node tag, xtext complete
                break
            } else if (p == Code.AMPERSAND) {
                // escape sequence
                value = value + parseEscapeSequence()
            } else if (p == Code.EOF) {
                unexpected(p)
            } else {
                // simple character
                value = value + String.fromCodePoint(p)
                advance()
            }
        }
        return XText.new(value)
    }

    // "element" is the element to add the parsed nodes to
    parseElementContentNodes(element) {
        while (true) {
            // remember the start in case it's xtext, and so we need to 
            // include the whitespace in its value
            var start = _cur
            skipOptionalWhitespace()
            var p1 = peek()
            if (p1 == Code.LESS_THAN) {

                // some kind of tag -> not xtext
                var p2 = peek(2)
                if (p2 == Code.SLASH) {
                    // closing tag: this is the end of the element's content
                    break
                } else if (p2 == Code.EXCLAMATION) {

                    // cdata or comment
                    var p3 = peek(3)
                    if (p3 == Code.LEFT_SQUARE) {
                        // cdata
                        element.addCData(parseCData())
                    } else {
                        // comment
                        element.addComment(parseComment())
                    }

                } else if (p2 == Code.EOF) {
                    unexpected(Code.EOF)
                } else {
                    element.addElement(parseElement())
                }

            } else if (p1 == Code.EOF) {
                unexpected(Code.EOF)
            } else {
                // xtext, so we go back and include the whitespace in its value
                _cur = start
                element.addText(parseText())
            }
        }
    }

    parseAttributeValue() {
        expect2(Code.QUOTATION, Code.APOSTROPHE)
        var value = ""
        while (true) {
            var p = peek()
            if (p == Code.QUOTATION || p == Code.APOSTROPHE) {
                // closing quote, attribute value complete
                advance()
                break
            } else if (p == Code.AMPERSAND) {
                // escape sequence
                value = value + parseEscapeSequence()
            } else {
                // simple character
                value = value + String.fromCodePoint(p)
                advance()
            }
        }
        return value
    }

    parseEscapeSequence() {
        expect(Code.AMPERSAND)

        var c = next()

        if (c == Code.HASH) {
            // $#x00e9;
            var n = next()
            var numString
            if (n == Code.X_LOWER) {
                numString = "0x"
                n = next()
            } else {
                numString = ""
            }

            while (n != Code.SEMICOLON) {
                numString = numString + String.fromCodePoint(n)
                n = next()
            }
            var num = Num.fromString(numString)
            if (num == null) {
                Fiber.abort("Failed to parse unicode escape at line %(_line):%(_col)")
            }
            return String.fromCodePoint(num)

        } else if (c == Code.Q_LOWER) {
            // &quot;
            expect(Code.U_LOWER)
            expect(Code.O_LOWER)
            expect(Code.T_LOWER)
            expect(Code.SEMICOLON)
            return "\""

        } else if (c == Code.L_LOWER) {
            // &lt;
            expect(Code.T_LOWER)
            expect(Code.SEMICOLON)
            return "<"

        } else if (c == Code.G_LOWER) {
            // &gt;
            expect(Code.T_LOWER)
            expect(Code.SEMICOLON)
            return ">"

        } else if (c == Code.A_LOWER) {
            var secondC = next()

            if (secondC == Code.M_LOWER) {
                // &amp;
                expect(Code.P_LOWER)
                expect(Code.SEMICOLON)
                return "&"

            } else if (secondC == Code.P_LOWER) {
                // &apos;
                expect(Code.O_LOWER)
                expect(Code.S_LOWER)
                expect(Code.SEMICOLON)
                return "'"

            } else {
                unexpected(secondC, "Invalid escape sequence")
            }

        } else {
            unexpected(c, "Invalid escape sequence")
        }
    }
}

#abstract
class XObject {
    #doc = "Convert to string representation"
    toString {
        var result = ""
        write() {|x|
            result = result + x
        }
        return result
    }

    #doc = "Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable"
    #arg(name=writerCallable)
    write(writerCallable) {
        Fiber.abort("write method must be implemented on abstract class XObject")
    }
}

#doc = "An XML attribute"
class XAttribute is XObject {
    #doc = "Create from string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseAttribute()
    }
    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeAttribute(this)
    }

    #doc = "Create a new attribute with the given name and value. If the provided value isn't a string, it will be converted with toString"
    #arg(name=name)
    #arg(name=value)
    construct new(name, value) {
        if (!(name is String)) Fiber.abort("Attribute name must be string")
        _name = name
        this.value = value
    }

    #doc = "Create a new attribute defining the default namespace xmlns='value'"
    #arg(name=value)
    static xmlns(value) {
        return XAttribute.new("xmlns", value)
    }

    #doc = "Create a new attribute defining an namespace xmlns:prefix='value'"
    #arg(name=prefix)
    #arg(name=value)
    static xmlns(prefix, value) {
        return XAttribute.new("{%(XNamespace.xmlns)}%(prefix)", value)
    }

    #doc = "Create a new attribute with the xml prefix xml:prefix='value'"
    #arg(name=prefix)
    #arg(name=value)
    static xml(prefix, value) {
        return XAttribute.new("{%(XNamespace.xml)}%(prefix)", value)
    }

    #doc = "Get the name of this attribute. The name cannot be changed"
    name { _name }

    #doc = "Set the name of this attribute. This must be a string."
    #arg(name=value)
    name=(value) {
        if (!(value is String)) Fiber.abort("Element name must be string")
        _name = value
    }

    #doc = "Get the string value of the attribute"
    value { _value }

    #doc = "Set the string value of the attribute. If the provided value isn't a string, it will be converted with toString"
    #arg(name=value)
    value=(value) {
        if (value == null) {
            _value = ""
        } else if (value is String) {
            _value = value
        } else {
            _value = value.toString 
        }
    }

    #internal
    addTo(parent) {
        parent.addAttribute(this)
    }
    #internal
    removeFrom(parent) {
        parent.removeAttribute(this)
    }

}

#doc = "An XML text node"
class XText is XObject {
    #doc = "Create from string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseText()
    }
    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeText(this)
    }

    #internal
    writeWith(writer, indent) {
        writer.writeText(this)
    }

    #doc = "Create a new XText node with the given string content"
    #arg(name=value)
    construct new(value) {
        this.value = value
    }

    #doc = "Get the string content"
    value { _value }

    #doc = "Set the string content. If it's not a string, it is converted with toString"
    #arg(name=value)
    value=(value) {
        if (value == null) {
            _value = ""
        } else if (value is String) {
            _value = value
        } else {
            _value = value.toString 
        }
    }

    #internal
    addTo(parent) {
        parent.addText(this)
    }
    #internal
    removeFrom(parent) {
        parent.removeText(this)
    }
}

#doc = "An XML CDATA node"
class XCData is XText {
    #doc = "Create from string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseCData()
    }
    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeCData(this)
    }

    #internal
    writeWith(writer, indent) {
        writer.writeCData(this)
    }

    #doc = "Create a new CData node with the given string content"
    #arg(name=value)
    construct new(value) {
        super(value)
    }

    #internal
    addTo(parent) {
        parent.addCData(this)
    }
    #internal
    removeFrom(parent) {
        parent.removeCData(this)
    }
}

#doc = "An XML comment"
class XComment is XObject {
    #doc = "Create from string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseComment()
    }
    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeComment(this)
    }

    #internal
    writeWith(writer, indent) {
        writer.writeComment(this)
    }

    #doc = "Create a new comment with the given string content"
    #arg(name=value)
    construct new(value) {
        this.value = value
    }

    #doc = "Get the string content of this comment"
    value { _value }

    #doc = "Set the string content of this comment. If it's not a string, it is converted with toString"
    #arg(name=value)
    value=(value) {
        if (value == null) {
            _value = ""
        } else if (value is String) {
            _value = value
        } else {
            _value = value.toString 
        }
    }

    #internal
    addTo(parent) {
        parent.addComment(this)
    }
    #internal
    removeFrom(parent) {
        parent.removeComment(this)
    }
}

#abstract
class XContainer is XObject {

    init_() {
        _nodes = []
    }

    #doc = "Gets the first element of this name, or null if no element of the name exists"
    #arg(name=name)
    element(name) {
        for (e in elements) {
            if (e.name == name) {
                return e
            }
        }
        return null
    }

    #doc = "Gets the String value of the first element of this name. Since an element's value is never null, this will only be null if the element is not found."
    #arg(name=name)
    elementValue(name) {
        var e = element(name)
        return e != null ? e.value : null
    }

    #doc = "Sequence of the child nodes"
    nodes { _nodes }

    #doc = "Sequence of the child elements, or an empty sequence if there are no elements"
    elements { _nodes.where {|node| node is XElement } }

    #doc = "Gets all elements of the given name, or an empty sequence if no matching elements are found"
    #arg(name=name)
    elements(name) { _nodes.where {|node| node is XElement && node.name == name } }

    #doc = "Sequence of the child comments, or an empty sequence if there are no comments"
    comments { _nodes.where {|node| node is XComment }}

    #internal
    addElement(child) {
        _nodes.add(child)
    }
    #internal
    addComment(child) {
        _nodes.add(child)
    }
    #internal
    removeElement(child) {
      _nodes.remove(child)
    }
    #internal
    removeComment(child) {
      _nodes.remove(child)
    }

    #doc = "Adds each of the items in the sequence to this container"
    #arg(name=sequence)
    addAll(sequence) {
      for (i in sequence) {
        i.addTo(this)
      }
    }
}

#doc = "An XML element"
class XElement is XContainer {

    #doc = "Create from string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseElement()
    }
    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeElement(this)
    }

    #internal
    writeWith(writer, indent) {
        writer.writeElement(this, indent)
    }

    init_(name) {
        this.name = name
        _attributes = []
        init_()
    }

    init_(name, sequence) {
        init_(name)
        // Support setting value and attributes during construction
        for (child in sequence) {
            if (child is XObject) {
                child.addTo(this)
            } else {
                addText(XText.new(child))
            }
        }
    }

    #doc = "Creates empty element"
    #arg(name=name)
    construct new(name) {
        init_(name)
    }

    #doc = """
    Creates element. Content can be string, node, attribute, or Sequence of those things.
    
    Anything else is converted with toString. Keep in mind that a Sequence will not be converted with toString,
    but rather, it is iterated over.
    """
    #arg(name=name)
    #arg(name=content)
    construct new(name, content) {
        // be careful here, a String is a Sequence so this check must come before the Sequence one
        if (content is String) {
            init_(name)
            addText(XText.new(content))
            return
        }
        if (content is Sequence) {
            init_(name, content)
            return
        }
        init_(name)
        if (content is XObject) {
            content.addTo(this)
        } else {
            addText(XText.new(content))
        }
    }

    // The following allows dropping the [] in most circumstances
    // Can't add any more of them because of the 16 parameter limit
    // If wren adds an "args" syntax at some point, this should be replaced with that
    construct new(name, c0, c1) { init_(name, [c0, c1]) }
    construct new(name, c0, c1, c2) { init_(name, [c0, c1, c2]) }
    construct new(name, c0, c1, c2, c3) { init_(name, [c0, c1, c2, c3]) }
    construct new(name, c0, c1, c2, c3, c4) { init_(name, [c0, c1, c2, c3, c4]) }
    construct new(name, c0, c1, c2, c3, c4, c5) { init_(name, [c0, c1, c2, c3, c4, c5]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6) { init_(name, [c0, c1, c2, c3, c4, c5, c6]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13]) }
    construct new(name, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14) { init_(name, [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14]) }

    #doc = "Get the name of this element"
    name { _name }

    #doc = "Set the name of this element. This must be a string."
    #arg(name=value)
    name=(value) {
        if (!(value is String)) Fiber.abort("Element name must be string")
        _name = value
    }

    #doc = "Get string content. If content is not a String, returns empty string"
    value {
        var result = ""
        for (node in nodes) {
            if (node is XText) {
                result = result + node.value
            }
        }
        return result
    }

    #doc = "Replace all current content with the given string. If it's not a string, it is converted with toString"
    #arg(name=value)
    value=(value) {
        nodes.clear()
        if (value == null) {
            return
        }
        addText(XText.new(value))
    }

    #doc = "Gets the attribute of this name, or null if no attribute of the name exists"
    #arg(name=name)
    attribute(name) {
        for (a in attributes) {
            if (a.name == name) {
                return a
            }
        }
        return null
    }

    #doc = "Sequence of the attributes of this element"
    attributes { _attributes }

    #doc = "Add a child attribute/node, or a Sequence of them."
    #arg(name=child)
    add(child) {
        if (child is String) {
            addText(XText.new(child))
        } else if (child is Sequence) {
            addAll(child)
        } else {
            child.addTo(this)
        }
    }

    #doc = "Remove a child attribute or node"
    #arg(name=child)
    remove(child) {
        child.removeFrom(this)
    }

    #internal
    addAttribute(child) {
        if (attribute(child.name) != null){
            Fiber.abort("Duplicate XAttribute of name '%(child.name)'")
        }
        _attributes.add(child)
    }
    #internal
    removeAttribute(child) {
      _attributes.remove(child)
    }
    #internal
    addText(child) {
        nodes.add(child)
    }
    #internal
    removeText(child) {
        nodes.remove(child)
    }
    #internal
    addCData(child) {
        nodes.add(child)
    }
    #internal
    removeCData(child) {
        nodes.remove(child)
    }
    #internal
    addTo(parent) {
        parent.addElement(this)
    }
    #internal
    removeFrom(parent) {
        parent.removeElement(this)
    }

    #doc = "Gets the String value of the attribute of this name. Since an attribute's value is never null, this will only be null if the attribute is not found."
    #arg(name=name)
    attributeValue(name) {
        var attr = attribute(name)
        return attr != null ? attr.value : null
    }

    #doc = "Sets value of existing attribute, or creates new attribute. null value removes the attribute"
    #arg(name=name)
    #arg(name=value)
    setAttributeValue(name, value) {
        if (value == null) {
            _attributes.remove(attribute(name))
            return
        }
        var attr = attribute(name)
        if (attr == null) {
            add(XAttribute.new(name, value))
            return
        }
        attr.value = value
    }
}

#doc = "An XML document"
class XDocument is XContainer {
    #doc = "Create from parsing a string"
    #arg(name=text)
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseDocument()
    }

    write(writerCallable) {
        var writer = XWriter.new(writerCallable)
        writer.writeDocument(this)
    }

    #doc = "Creates an empty document"
    construct new() {
        init_()
    }

    #doc = "Creates a document with content. Content can be XElement, XComment, or Sequence of them"
    #arg(name=content)
    construct new(content) {
        init_()
        if (content == null) {
            Fiber.abort("XDocument content cannot be null")
        } else {
            add(content)
        }
    }

    init_(sequence) {
        init_()
        addAll(sequence)
    }

    // The following allows dropping the [] in most circumstances
    // Can't add any more of them because of the 16 parameter limit
    // If wren adds an "args" syntax at some point, this should be replaced with that
    construct new(c0, c1) { init_([c0, c1]) }
    construct new(c0, c1, c2) { init_([c0, c1, c2]) }
    construct new(c0, c1, c2, c3) { init_([c0, c1, c2, c3]) }
    construct new(c0, c1, c2, c3, c4) { init_([c0, c1, c2, c3, c4]) }
    construct new(c0, c1, c2, c3, c4, c5) { init_([c0, c1, c2, c3, c4, c5]) }
    construct new(c0, c1, c2, c3, c4, c5, c6) { init_([c0, c1, c2, c3, c4, c5, c6]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7) { init_([c0, c1, c2, c3, c4, c5, c6, c7]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14]) }
    construct new(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15) { init_([c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15]) }

    #doc = "The first and only node in this document that is an XElement. null if there is no XElement in the document."
    root {
        for (node in nodes) {
            if (node is XElement) {
                return node
            }
        }
        return null
    }

    #doc = "Add a child node to the document. This can be an XComment or an XElement, or a Sequence of them."
    #arg(name=child)
    add(child) {
        if (child is Sequence) {
            addAll(child)
        } else {
            child.addTo(this)
        }
    }

    #doc = "Remove a child XComment or XElement"
    #arg(name=child)
    remove(child) {
        child.removeFrom(this)
    }

    #internal
    addElement(child) {
      if (root != null) {
          Fiber.abort("Cannot add more than one XElement to document")
      }
      super.addElement(child)
    }
}

