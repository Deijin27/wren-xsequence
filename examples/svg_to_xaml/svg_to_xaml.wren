
/*

This as a script that takes a really simple SVG file of a single-color path geometry
and converts it to a XAML PathGeometry item

*/

import "../../xsequence" for XDocument, XElement, XAttribute
import "io" for File

// namespaces we will need
var svg = "{http://www.w3.org/2000/svg}"
var sodipodi = "{http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd}"
var xaml = "http://schemas.microsoft.com/winfx/2006/xaml/presentation"
var x = "http://schemas.microsoft.com/winfx/2006/xaml"

// load the svg document
var txt = File.read("examples/svg_to_xaml/svg_sample.svg")
var doc = XDocument.parse(txt)

// extract values from the svg
var root = doc.element(svg + "svg")
var figures = root.element(svg + "path").attribute("d").value
var key = root.attribute(sodipodi + "docname").value

// generate the xaml
// <PathGeometry x:Key="UpArrowGeometry" Figures="M 0 4.5 l 4.5 -4.5 4.5 4.5"/>
var pg = XElement.new("{%(xaml)}PathGeometry",
  XAttribute.new("{%(x)}Key", key),
  XAttribute.new("Figures", figures),
  XAttribute.xmlns(xaml),
  XAttribute.xmlns("x", x)
)

System.print(pg)