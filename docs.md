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

### value(converterId)

Get the value of the attribute, using the converter registered by the provided id. Aborts fiber if no such converter is found, or it fails to convert the value

### value(converterId, default)

Gets the value of the attribute using the converter registered by the provided id. If no such converter is found, or it fails to convert, the provided default is returned

### value=(value)

Set the string value of the attribute, coverting to string where necessary using a converter registered under an id matching the type of the object. If no converter is found, falls back to .toString

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

## XConverter

Manages converters which convert values to and from the string forms stored in the xml document. Also serves as a base class for custom converters

### static get(id)

Gets a converter with the given id. Aborts fiber if no match is found

### static register(id, converter)

Register a converters with the given id

### static toStringInferred(value)

Gets a converter with the id matching the type of the provided value, or if none is found falls back to .toString

### static tryGet(id)

Gets a converter with the given id, or null if no match is found

### description

The description included in error messages. Overwrite this in custom converters

### fromString(value)

Convert from string to the output value. Overwrite this in custom converters.

### toString(value)

Convert from value to string. Optionally overwrite this in custom converters, the default is .toString

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

### elementOrAbort(name)

Get first element of name. If no element with that name is found, aborts fiber.

### elementValue(name)

Gets the String value of the first element of this name. Since an element's value is never null, this will only be null if the element is not found.

### elementValue(name, converterId)

Get the first element of name, and converts using the given converter. If no element of that name is found, or the value fails to be converted, aborts fiber

### elementValue(name, converterId, default)

Get first element of name, and converts using the given converter. If no element of that name is found, or the value fails to be converted, returns default

### elements

Sequence of the child elements, or an empty sequence if there are no elements

### elements(name)

Gets all elements of the given name, or an empty sequence if no matching elements are found

### findElement(predicate)

Gets the first element which fulfils the predicate, or null if no match is found

### findElement(name, predicate)

Gets the first element of this name which also fulfils the predicate, or null if no match is found

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

### attributeOrAbort(name)

Get attribute of name. Aborts fiber if no attribute of that name is found

### attributeValue(name)

Gets the String value of the attribute of this name. Since an attribute's value is never null, this will only be null if the attribute is not found.

### attributeValue(name, converterId)

Get attribute of name, and converts using the given converter. If no attribute of that name is found, or the value fails to be converted, aborts fiber

### attributeValue(name, converterId, default)

Get attribute of name, and converts using the given converter. If no attribute of that name is found, or the value fails to be converted, returns default

### attributes

Sequence of the attributes of this element

### comments

Sequence of the child comments, or an empty sequence if there are no comments

### element(name)

Gets the first element of this name, or null if no element of the name exists

### elementOrAbort(name)

Get first element of name. If no element with that name is found, aborts fiber.

### elementValue(name)

Gets the String value of the first element of this name. Since an element's value is never null, this will only be null if the element is not found.

### elementValue(name, converterId)

Get the first element of name, and converts using the given converter. If no element of that name is found, or the value fails to be converted, aborts fiber

### elementValue(name, converterId, default)

Get first element of name, and converts using the given converter. If no element of that name is found, or the value fails to be converted, returns default

### elements

Sequence of the child elements, or an empty sequence if there are no elements

### elements(name)

Gets all elements of the given name, or an empty sequence if no matching elements are found

### findElement(predicate)

Gets the first element which fulfils the predicate, or null if no match is found

### findElement(name, predicate)

Gets the first element of this name which also fulfils the predicate, or null if no match is found

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

### value(converterId)

Get the value of the element using the converter registered by the provided id. Aborts fiber if no such converter is found, or it fails to convert the value

### value(converterId, default)

Gets the value of the element using the converter registered by the provided id. If no such converter is found, or it fails to convert, the provided default is returned

### value=(value)

Replace all current content with the given string. If it's not a string, it is converted with a converter registered with id matching type of the object, or .toString

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

