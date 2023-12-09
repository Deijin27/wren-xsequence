# XSequence

Xml parser/writer for [Wren](https://wren.io/)

Api similar to [C#'s XLinq](https://docs.microsoft.com/en-us/dotnet/standard/linq/linq-xml-overview)

To use, download the [latest release](https://github.com/Deijin27/wren-xsequence/releases/latest) and take the single file `xsequence.wren` and put it into your project

[Documentation](https://github.com/Deijin27/wren-xsequence/blob/master/docs.md)

## Quick Examples

To create an xml document like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<fishies amount="2">
  <!--This is a comment in an element-->
  <danio name="zebra" color="red"/>
  <danio name="pearl" color="pink"/>
  <danio>value</danio>
</fishies>
<!--This is a comment in a document-->
```

You can write code like this to build the tree

```wren
import "./xsequence" for XDocument, XElement, XAttribute, XComment

var doc = XDocument.new(
    XElement.new("fishies",
        XComment.new("This is a comment in an element"),
        XAttribute.new("amount", 2),
        XElement.new("danio",
            XAttribute.new("name", "zebra"),
            XAttribute.new("color", "red")
        ),
        XElement.new("danio",
            XAttribute.new("name", "pearl"),
            XAttribute.new("color", "pink")
        ),
        XElement.new("danio", "value")
    ),
    XComment.new("This is a comment in a document")
)
```

Then to save to a string you can either do 

```wren
var string = doc.toString
```

Or for better performance if you are able to write directly to a file stream, you can hook in a custom writer function

```wren
doc.write {|s|
  stream.writeString(s)
}
```

To parse xml document, you first load the xml into a string, then parse it with XDocument. In wren_cli you could do something like this

```wren
var xmlText = File.read("myDocument.xml")
var doc = XDocument.parse(xmlText)
```

If we have a document loaded which is like the fishies document shown above, you could navigate the names of all fishies which are pink

```wren
var colorOfFishCalledPearl = doc
    .elementOrAbort("fishies")
    .elements("danio")
    .where {|e| e.attributeValue("color") == "pink" }
    .map {|e| e.attributeValue("name") }
    .toList
```

You can get the values converted to number, or boolean too. In the following example we get the fish called pearl,
then get it's size converted to a Num. If there is no "size" attribute, then it uses the default value provided 2.
If you don't provide a default, it throws an exception if there is no such attribute, or the attribute value cannot
be converted. You can also provide Bool to convert something to a Bool, and this converter functionality is extensible
to your own types if needed. There is similar methods for elementValue.

```wren
var pearlTheFish = doc.elementOrAbort("fishies").findElement("danio") {|e| e.attributeValue("name") == "pearl" }
var sizeOfPearl = pearlTheFish.attributeValue("size", Num, 2)
```

The library also supports namespaces like so

```wren
var element = XElement.parse("<p:svg xmlns:p='http://www.w3.org/2000/svg'/>")
// will load into an element identical to
element = XElement.new("{http://www.w3.org/2000/svg}svg", XAttribute.xmlns("p", "http://www.w3.org/2000/svg"))
// the namespace prefix is replaced with the value itself delimited by curly braces
```

## Testing

Using [wren-assert](https://github.com/RobLoach/wren-assert) for generic assertions.

To run tests use [wren cli](https://github.com/wren-lang/wren-cli)

```powershell
> wren_cli.exe test.wren
```

If you're using vscode you can use the automated task

The exceptions are caught by default, which loses the call stack. To view the callstack set at the start of the file the global variable `DEBUG=true`
