# XSequence Documentation

## XDocument

An XML document

### construct new(content)

Creates a document with content. Content can be XElement, XComment, or Sequence of them

### construct new()

Creates an empty document

### add(child)

Add a child node to the document. This can be an XComment or an XElement, or a Sequence of them.

### comments

Sequence of the child comments

### elements

Sequence of the child elements

### element(name)

Gets the first element of this name, or null if no element of the name exists

### elements(name)

Gets all elements of the given name. An empty sequence if no elements are found

### nodes

Sequence of the child nodes

### remove(child)

Remove a child XComment or XElement

### root

The first and only node in this document that is an XElement. null if there is no XElement in the document.

### static parse(text)

Create from parsing a string

### toString

Convert to string representation

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

## XElement

An XML element

### construct new(name)

Creates empty element

### construct new(name, content)

Creates element. Content can be text content, or XAttribute, XElement, XComment, or Sequence.

Anything else is converted with toString. Keep in mind that a Sequence will not be converted with toString,
but rather, it is iterated over.

### attributes

Sequence of the attributes of this element

### add(child)

Add a child node to the document. This can be an XAttribute, XComment or an XElement, or a Sequence of them.

### attribute(name)

Gets the attribute of this name, or null if no attribute of the name exists

### comments

Sequence of the child comments

### element(name)

Gets the first element of this name, or null if no element of the name exists

### elements(name)

Gets all elements of the given name. An empty sequence if no elements are found

### elements

Sequence of the child elements

### nodes

Sequence of the child nodes

### name=(value)

Set the name of this element. This must be a string.

### name

Get the name of this element

### remove(child)

Remove a child XAttribute or XElement

### setAttributeValue(name, value)

Sets value of existing attribute, or creates new attribute. null value removes the attribute

### static parse(text)

Create from string

### toString

Convert to string representation

### value

Get string content. If content is not a String, returns empty string

### value=(value)

Set string content. . If it's not a string, it is converted with toString

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

## XAttribute

An XML attribute

### construct new(name, value)

Create a new attribute with the given name and value. If the provided value isn't a string, it will be converted with toString

### name

Get the name of this attribute. The name cannot be changed

### static parse(text)

Create from string

### toString

Convert to string representation

### value=(value)

Set the string value of the attribute. If the provided value isn't a string, it will be converted with toString

### value

Get the string value of the attribute

### write(writerCallable)

Convert to string in parts and pass to a function. Allows more efficient writing to file streams where avaliable

