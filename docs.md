# XSequence Documentation

## XAttribute

An XML attribute

### construct new(name, value)

Create a new attribute with the given name and value. If the provided value isn't a string, it will be converted with toString

### static parse(text)

Create from string

### static xml(prefix, value)

Create a new attribute with the xml prefix xml:prefix='value'

### static xmlns(value)

Create a new attribute defining the default namespace xmlns='value'

### static xmlns(prefix, value)

Create a new attribute defining an namespace xmlns:prefix='value'

### name

Get the name of this attribute. The name cannot be changed

### name=(value)

Set the name of this attribute. This must be a string.

### toString

Convert to string representation

### value

Get the string value of the attribute

### value=(value)

Set the string value of the attribute. If the provided value isn't a string, it will be converted with toString

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XCData

An XML CDATA node

### construct new(value)

Create a new XText node with the given string content

### static parse(text)

Create from string

### toString

Convert to string representation

### value

Get the string content

### value=(value)

Set the string content. If it's not a string, it is converted with toString

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XComment

An XML comment

### construct new(value)

Create a new comment with the given string content

### static parse(text)

Create from string

### toString

Convert to string representation

### value

Get the string content of this comment

### value=(value)

Set the string content of this comment. If it's not a string, it is converted with toString

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XDocument

An XML document

### construct new()

Creates an empty document

### construct new(content)

Creates a document with content. Content can be XElement, XComment, or Sequence of them

### static parse(text)

Create from parsing a string

### add(child)

Add a child node to the document. This can be an XComment or an XElement, or a Sequence of them.

### addAll(sequence)

Adds each of the items in the sequence to this container

### comments

Sequence of the child comments, or an empty sequence if there are no comments

### element(name)

Gets the first element of this name, or null if no element of the name exists

### elementValue(name)

Gets the String value of the first element of this name. Since an element's value is never null, this will only be null if the element is not found.

### elements

Sequence of the child elements, or an empty sequence if there are no elements

### elements(name)

Gets all elements of the given name, or an empty sequence if no matching elements are found

### nodes

Sequence of the child nodes

### remove(child)

Remove a child XComment or XElement

### root

The first and only node in this document that is an XElement. null if there is no XElement in the document.

### toString

Convert to string representation

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XElement

An XML element

### construct new(name)

Creates empty element

### construct new(name, content)

Creates element. Content can be string, node, attribute, or Sequence of those things.

Anything else is converted with toString. Keep in mind that a Sequence will not be converted with toString,
but rather, it is iterated over.

### static parse(text)

Create from string

### add(child)

Add a child attribute/node, or a Sequence of them.

### addAll(sequence)

Adds each of the items in the sequence to this container

### attribute(name)

Gets the attribute of this name, or null if no attribute of the name exists

### attributeValue(name)

Gets the String value of the attribute of this name. Since an attribute's value is never null, this will only be null if the attribute is not found.

### attributes

Sequence of the attributes of this element

### comments

Sequence of the child comments, or an empty sequence if there are no comments

### element(name)

Gets the first element of this name, or null if no element of the name exists

### elementValue(name)

Gets the String value of the first element of this name. Since an element's value is never null, this will only be null if the element is not found.

### elements

Sequence of the child elements, or an empty sequence if there are no elements

### elements(name)

Gets all elements of the given name, or an empty sequence if no matching elements are found

### name

Get the name of this element

### name=(value)

Set the name of this element. This must be a string.

### nodes

Sequence of the child nodes

### remove(child)

Remove a child attribute or node

### setAttributeValue(name, value)

Sets value of existing attribute, or creates new attribute. null value removes the attribute

### toString

Convert to string representation

### value

Get string content. If content is not a String, returns empty string

### value=(value)

Replace all current content with the given string. If it's not a string, it is converted with toString

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XName

A utility class for working with XML names and namespaces

### static build(namespace, localName)

Build a name string from it's components

### static split(name)

Split a string of format '{namespace}localName' into an XName which has properties to access it's namespace and local name

### localName

The local name of this XML name

### namespace

The namespace of this XML name

### toString

Convert to string

## XNamespace

A utility class for working with XML namespaces. You will probably never need this

### static xml

The xml namespace value 'http://www.w3.org/XML/1998/namespace'. It's easier to use XAttribute.xml

### static xmlns

The xmlns namespace value 'https://www.w3.org/2000/xmlns/'. It's easier to use XAttribute.xmlns

## XText

An XML text node

### construct new(value)

Create a new XText node with the given string content

### static parse(text)

Create from string

### toString

Convert to string representation

### value

Get the string content

### value=(value)

Set the string content. If it's not a string, it is converted with toString

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

