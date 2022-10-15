/*

 XSequence
 
 Version : 1.2.0
 Author  : Mia Boulter (Deijin27)
 Licence : MIT
 Website : https://github.com/deijin27/wren-xsequence

 */

class XWriter {
    static write(obj, writerCallable) {
        if (obj is XDocument) {
            writeDocument(obj, writerCallable)
        } else if (obj is XElement) {
            writeElement(obj, writerCallable)
        } else if (obj is XAttribute) {
            writeAttribute(obj, writerCallable)
        } else if (obj == null) {
            Fiber.abort("XWriter cannot write null")
        } else {
            Fiber.abort("XWriter cannot write type '%(obj.type)'")
        }
    }

    static writeDocument(document, writerCallable) {
        writerCallable.call("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
        if (document.root != null) {
            writerCallable.call("\n")
            writeElement(document.root, writerCallable)
        }
    }

    static writeElement(element, writerCallable) {
        writeElement(element, "", writerCallable)
    }

    static writeElement(element, indent, writerCallable) {
        writerCallable.call("<%(element.name)")
        for (attribute in element.attributes) {
            writerCallable.call(" ")
            writeAttribute(attribute, writerCallable)
        }
        if (element.elements.count > 0) {
            var newIndent = indent + "  "
            writerCallable.call(">")
            for (childElement in element.elements) {
                writerCallable.call("\n")
                writerCallable.call(newIndent)
                writeElement(childElement, newIndent, writerCallable)
            }
            writerCallable.call("\n%(indent)</%(element.name)>")

        } else if (element.value != null && element.value != "") {
            var elementVal = escape(element.value)
            writerCallable.call(">%(elementVal)</%(element.name)>")
        } else {
            writerCallable.call("/>")
        }
    }

    static escape(str) {
        return str
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }

    static writeAttribute(attribute, writerCallable) {
        var value = escape(attribute.value)
        return writerCallable.call("%(attribute.name)=\"%(value)\"")
    }
}

class Code {
    static EOF           { -1   } // end of file
    
    static NEWLINE       { 0x0A } // \n
    static TAB           { 0x09 } // \t
    

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

class XParser {
    construct new(source) {
        source = source.replace("\r\n", "\n")

        _cur = -1
        _end = source.count

        // skip utf-8 bom
        if (source.startsWith("\xEF\xBB\xBF")) {
            _cur = _cur + 3
            _end = _end + 3
        }

        _line = 0
        _col = 0
        _points = source.codePoints
        _in_comment = 0
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
            unexpected(c)
        }
        advance()
    }

    expect(pointOption1, pointOption2) {
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
        } else if (point == Code.SPACE) {
            err = "space"
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
        while (true) {
            skipOptionalWhitespace()
            if (peek() != Code.LESS_THAN) {
                unexpected(peek())
            }
            var p = peek(2)
            if (p == Code.EXCLAMATION) {
                parseComment()
            }  else if (p == Code.QUESTION) {
                parseDeclaration()
            } else if (p == Code.EOF) {
                return null
            } else {
                return XDocument.new(parseElement())
            }
        }
    }

    parseComment() {
        expect(Code.LESS_THAN)
        expect(Code.EXCLAMATION)
        expect(Code.DASH)
        expect(Code.DASH)

        while (true) {
            var n = next()
            if (n == Code.EOF) {
                unexpected(Code.EOF)
            }
            if (n == Code.DASH && peek() == Code.DASH && peek(2) == Code.GREATER_THAN) {
                advance()
                advance()
                break
            }
        }
    }

    parseDeclaration() {
        expect(Code.LESS_THAN)
        expect(Code.QUESTION)
        expect(Code.X_UPPER, Code.X_LOWER)
        expect(Code.M_UPPER, Code.M_LOWER)
        expect(Code.L_UPPER, Code.L_LOWER)

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
        expect(Code.LESS_THAN)

        var name = parseElementName()

        var element = XElement.new(name)

        while (true) {

            var p = peek()

            if (p == Code.SLASH) {
                // no-content closing tag
                advance()
                expect(Code.GREATER_THAN)
                break

            } else if (p == Code.GREATER_THAN) {
                // parse element content
                advance()
                var content = parseElementContent()
                if (content is String) {
                    element.value = content
                } else if (content is Sequence) {
                    for (item in content) {
                        element.add(item)
                    }
                } else {
                    element.add(content)
                }
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
                element.add(attr)
            }
        }
        
        return element
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
            } else if (p == Code.EOF || isWhitespace(p)) {
                unexpected(p)
            }
            name = name + String.fromCodePoint(p)
        }

        // at this point we are immediately after the equals sign

        var val = parseAttributeValue()

        return XAttribute.new(name, val)
    }

    parseElementContent() {
        // peek past whitespace
        var start = _cur
        skipOptionalWhitespace()
        if (peek() == Code.LESS_THAN && peek(2) != Code.SLASH) {
            // content is nodes
            return parseElementContentNodes()
        } else {
            // content is text
            _cur = start
            return parseElementValue()
        }
    }

    parseElementValue() {
        var value = ""
        while (true) {
            var p = peek()
            if (p == Code.LESS_THAN) {
                // begin of closing tag, element value complete
                break
            } else if (p == Code.AMPERSAND) {
                // escape sequence
                value = value + parseEscapeSequence()
            } else if (p == Code.EOF) {
                unexpected(c)
            } else {
                // simple character
                value = value + String.fromCodePoint(p)
            }
            advance()
        }
        return value
    }

    parseElementContentNodes() {
        var nodes = []
        while (true) {
            if (peek() != Code.LESS_THAN) {
                unexpected(peek())
            }
            var p = peek(2)
            if (p == Code.EXCLAMATION) {
                parseComment()
            } else if (p == Code.EOF) {
                unexpected(p)
            } else {
                nodes.add(parseElement())
            }
            skipOptionalWhitespace()
            if (peek() == Code.LESS_THAN && peek(2) == Code.SLASH) {
                // closing tag
                break
            }
        }
        return nodes
    }

    parseAttributeValue() {
        expect(Code.QUOTATION, Code.APOSTROPHE)
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

class XAttribute {
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseAttribute()
    }
    toString {
        var result = ""
        XWriter.writeAttribute(this) {|x|
            result = result + x
        }
        return result
    }
    write(writerCallable) {
        XWriter.writeAttribute(this, writerCallable)
    }

    construct new(name, value) {
        _name = name
        this.value = value
    }

    name { _name }

    value { _value }
    value=(value) {
        if (value == null) {
            _value = ""
        }
        _value = value.toString 
    }

}

class XElement {

    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseElement()
    }
    toString {
        var result = ""
        XWriter.writeElement(this) {|x|
            result = result + x
        }
        return result
    }
    write(writerCallable) {
        XWriter.writeElement(this, writerCallable)
    }

    init_(name) {
        if (name == null) Fiber.abort("Element name cannot be null")
        if (!(name is String)) Fiber.abort("Element name must be a string")
        _name = name
        _attributes = []
        _elements = []
        _value = ""
    }

    init_(name, content) {
        init_(name)
        if (content == null) {
            Fiber.abort("Element content cannot be null")
        } else if (content is String) {
            _value = content
        } else {
            add(content)
        }
    }

    // additional arguments after name are contents i.e. elements and attributes
    // or alternatively, a single value after name is the "value" of the element
    construct new(name) {
        init_(name)
    }

    construct new(name, content) {
        init_(name, content)
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

    // The name of this element
    name { _name }

    // get string content. If content is not a String, returns empty string
    value { _value }
    value=(v) {
        if (!(v is String)) Fiber.abort("Element value must be string")
        _value = v
    }

    // Gets the attribute of this name, or null if no attribute of the name exists
    attribute(name) {
        for (a in attributes) {
            if (a.name == name) {
                return a
            }
        }
        return null
    }

    // Sequence of the attributes of this element
    attributes { _attributes }

    // Gets the first element of this name, or null if no element of the name exists
    element(name) {
        for (e in elements) {
            if (e.name == name) {
                return e
            }
        }
        return null
    }

    // Sequence of the child elements of this element
    elements { _elements }

    // Gets all elements of the given name. An empty sequence if no elements are found
    elements(name) { elements.where {|e| e.name == name } }

    // returns first attribute or element of name, attributes get priority
    child(name) {
        var result = attribute(name)
        if (attr == null) {
            result = element(name)
        }
        return result
    }

    // add a child XAttribute or XElement, or a Sequence of them
    add(child) {
        if (child is XAttribute) {
            if (attribute(child.name) != null){
                Fiber.abort("Duplicate XAttribute of name '%(child.name)'")
            }
            _attributes.add(child)

        } else if (child is XElement) {
            _elements.add(child)

        } else if (child is Sequence) {
            for (i in child) {
                add(i)
            }
        } else {
            Fiber.abort("Invalid child of XElement '%(child)'")
        }
    }

    // remove a child XAttribute or XElement
    remove(child) {
        if (child is XAttribute) {
            _attributes.remove(child)
        } else if (child is XElement) {
            _elements.remove(child)
        }
    }

    // sets value of existing attribute, or creates new attribute
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

class XDocument {
    static parse(text) {
        var parser = XParser.new(text)
        return parser.parseDocument()
    }
    toString {
        var result = ""
        XWriter.writeDocument(this) {|x|
            result = result + x
        }
        return result
    }
    write(writerCallable) {
        XWriter.writeDocument(this, writerCallable)
    }

    construct new() {
        _root = null
    }
    construct new(rootElement) {
        root = rootElement
    }

    root { _root }
    root=(element) {
        if (element == null) {
            _root = null
            return
        }
        if (!(element is XElement)) {
            Fiber.abort("XDocument root must be XElement")
        }
        _root = element
    }
}
