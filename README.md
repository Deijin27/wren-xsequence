# XSequence

Xml parser/writer for [Wren](https://wren.io/)

Api similar to [C#'s XLinq](https://docs.microsoft.com/en-us/dotnet/standard/linq/linq-xml-overview)

To use, take the single file `xsequence.wren` and put it into your project

## Quick Examples

To create an xml document like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<fishies amount="2">
  <danio name="zebra" color="red"/>
  <danio name="pearl" color="pink"/>
  <danio>value</danio>
</fishies>
```

You can write code like this to build the tree

```javascript
import "./xsequence" for XDocument, XElement, XAttribute

var doc = XDocument.new(
    XElement.new("fishies", [
        XAttribute.new("amount", 2),
        XElement.new("danio", [
            XAttribute.new("name", "zebra"),
            XAttribute.new("color", "red")
        ]),
        XElement.new("danio", [
            XAttribute.new("name", "pearl"),
            XAttribute.new("color", "pink")
        ]),
        XElement.new("danio", "value")
    ])
)
```

Then to save to a string you can either do 

```javascript
var string = doc.toString
```

Or for better performance if you are able to write directly to a file stream, you can hook in a custom writer function

```javascript
doc.write {|s|
  stream.writeString(s)
}
```

To parse xml document, you first load the xml into a string, then parse it with XDocument. In wren_cli you could do something like this

```javascript
var xmlText = File.read("myDocument.xml")
var doc = XDocument.parse(xmlText)
```

If we have a document loaded which is like the fishies document shown above, you could navigate the color of a danio fish of name "pearl" like this

```javascript
var colorOfFishCalledPearl = doc
    .root
    .elements("danio")
    .where {|e| e.attribute("name").value == "pearl" }
    .toList[0]
    .attribute("color")
    .value
```

## Testing

Using [wren-assert](https://github.com/RobLoach/wren-assert) for generic assertions.

To run tests use [wren cli](https://github.com/wren-lang/wren-cli)

```powershell
> wren_cli.exe test.wren
```

The exceptions are caught by default, which loses the call stack. To view the callstack set at the start of the file the global variable `DEBUG=true`

## Limitations

- Does not support creating comments. Comments are skipped by the parser.
