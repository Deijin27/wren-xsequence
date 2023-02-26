/*

This is an example of a parser for RSS format 2.0

Based on the spec detailed here: https://validator.w3.org/feed/docs/rss2.html

This code is licenced under MIT

*/

class RssGuid {
    // The guid value
    value { _value }
    // If false, the guid may not be assumed to be a url, or a url to anything in particular.
    isPermaLink { _isPermaLink }

    construct parse(element) {
        _value = element.value
        var plAttr = element.attribute("isPermaLink")
        _isPermaLink = plAttr == null || plAttr.value != "false"
    }
}

class RssCategory {
    // Forward-slash-separated string that identifies a hierarchic location in the indicated taxonomy
    value { _value }
    // An optional string that identifies a categorization taxonomy
    domain { _isPermaLink }

    construct parse(element) {
        _value = element.value
        _domain = element.attributeValue("domain")
    }
}

class RssEnclosure {
    // http url where the enclosure is located
    url { _url }
    // how big it is in bytes
    length { _length }
    // what its type is, a standard MIME type (named to avoid conflict with Object.type)
    mimeType { _mimeType }

    construct parse(element) {
        _url = element.attributeValue("url")
        _length = element.attributeValue("length")
        _mimeType = element.attributeValue("type")
        if (_url == null || _length == null || _mimeType == null) {
            Fiber.abort("RssEnclosure missing required attribute. Must have url, length, and type")
        }
    }
}

class RssSource {
    // The name of the RSS channel that the item came from
    name { _name }
    // url which links to the XMLization of the source
    url { _url }

    construct parse(element) {
        _name = element.value
        _url = element.attributeValue("url")
        if (_url == null) {
            Fiber.abort("RssSource missing required attribute 'url'")
        }
    }
}

class RssItem {
    // The title of the item.
    title { _title }
    // The URL of the item.
    link { _link }
    // The item synopsis.
    description { _description }
    // Email address of the author of the item
    author { _author }
    // List of categories of the item
    categories { _category }
    // URL of a page for comments relating to the item.
    comments { _comments }
    // Describes a media object that is attached to the item.
    enclosure { _enclosure }
    // A string that uniquely identifies the item.
    guid { _guid }
    // Indicates when the item was published.
    pubDate { _pubDate }
    // The RSS channel that the item came from.
    source { _source }

    construct parse(element) {
        _title = element.elementValue("title")
        _link = element.elementValue("link")
        _description = element.elementValue("description")
        _author = element.elementValue("author")
        _category = element.elements("category").map {|e| RssCategory.parse(e) }.toList
        _comments = element.elementValue("comments")
        _enclosure = element.elementValue("enclosure")
        _guid = element.elementValue("guid")
        _pubDate = element.elementValue("pubDate")
        _source = element.elementValue("source")
        if (_title == null && _description == null) {
            Fiber.abort("Rss Item must have at least one of title or description")
        }
    }
}

class RssTextInput {
    // The label of the Submit button in the text input area.
    title { _title }
    // Explains the text input area.
    description { _description }
    // The name of the text object in the text input area.
    name { _name }
    // The URL of the CGI script that processes text input requests.
    link { _link }

    construct parse(element) {
        _title = element.elementValue("title")
        _description = element.elementValue("description")
        _name = element.elementValue("name")
        _link = element.elementValue("link")
        if (_title == null || _description == null || _name == null || _link == null) {
            Fiber.abort("RssTextInput missing required sub element. Must have all 4 of title, description, name, and link")
        }
    }
}

class RssCloud {
    domain { _domain }
    port { _port }
    path { _path }
    registerProcedure { _registerProcedure }
    protocol { _protocol }

    construct parse(element) {
        _domain = element.elementValue("domain")
        _port = element.elementValue("port")
        _path = element.elementValue("path")
        _registerProcedure = element.elementValue("registerProcedure")
        _protocol = element.elementValue("protocol")
    }
}

class RssImage {
    // the URL of a GIF, JPEG or PNG image that represents the channel.
    url { _url }
    // describes the image, it's used in the ALT attribute of the HTML <img> tag when the channel is rendered in HTML.
    title { _title }
    // the URL of the site, when the channel is rendered, the image is a link to the site.
    link { _link }
    // width of the image in pixels
    width { _width }
    // height of the image in pixels
    height { _height }
    // text that is included in the TITLE attribute of the link formed around the image in the HTML rendering.
    description { _description }

    construct parse(element) {
        _url = element.attributeValue("url")
        _title = element.elementValue("title")
        _link = element.elementValue("link")
        if (_url == null || _title == null || _link == null) {
            Fiber.abort("RssImage missing required attribute. Requires all 3 of url, title, and link")
        }
        _width = 88
        var widthAttr = element.attribute("width")
        if (widthAttr != null) {
            _width = Num.fromString(widthAttr.value)
        }
        _height = 31
        var heightAttr = element.attribute("height")
        if (heightAttr != null) {
            _height = Num.fromString(heightAttr.value)
        }
    }
}

class RssChannel {

    // The name of the channel
    title { _title }
    // The URL to the HTML website corresponding to the channel.
    link { _link }
    // Phrase or sentence describing the channel.
    description { _description }

    // The language the channel is written in. e.g. en-us
    language { _language }
    // Copyright notice for content in the channel.
    copyright { _copyright }
    // Email address for person responsible for editorial content.
    managingEditor { _managingEditor }
    // Email address for person responsible for technical issues relating to channel.
    webMaster { _webMaster }
    // The publication date for the content in the channel.
    pubDate { _pubDate }
    // The last time the content of the channel changed.
    lastBuildDate { _lastBuildDate }
    // List of one or more categories that the channel belongs to.
    categories { _categories }
    // A string indicating the program used to generate the channel.
    generator { _generator }
    // A URL that points to the documentation for the format used in the RSS file.
    docs { _docs }
    // Allows processes to register with a cloud to be notified of updates to the channel, implementing a lightweight publish-subscribe protocol for RSS feeds.
    cloud { _cloud }
    // ttl stands for time to live. It's a number of minutes that indicates how long a channel can be cached before refreshing from the source.
    ttl { _ttl }
    // Specifies a GIF, JPEG or PNG image that can be displayed with the channel.
    image { _image }
    // The PICS rating for the channel.
    rating { _rating }
    // Specifies a text input box that can be displayed with the channel. 
    textInput { _textInput }
    // A hint for aggregators telling them which hours they can skip.
    // List containing up to 24 numbers from 0-23
    skipHours { _skipHours }
    // A hint for aggregators telling them which days they can skip.
    // A list of up to 7 day name strings Monday-Sunday
    skipDays { _skipDays }

    // List of any number of items. An item may represent a "story" -- much like a story in a newspaper or magazine
    items { _items }

    construct parse(element) {
        _title = element.elementValue("title")
        _link = element.elementValue("link")
        _description = element.elementValue("description")
        if (_title == null || _link == null || _description == null) {
            Fiber.abort("RssChannel missing required sub-element. Must contain title, link, and decription.")
        }

        _language = element.elementValue("language")
        _copyright = element.elementValue("copyright")
        _managingEditor = element.elementValue("managingEditor")
        _webMaster = element.elementValue("webMaster")
        _pubDate = element.elementValue("pubDate")
        _lastBuildDate = element.elementValue("lastBuildDate")
        _categories = element.elements("category").map {|e| RssCategory.parse(e) }.toList
        _generator = element.elementValue("generator")
        _docs = element.elementValue("docs")

        var cloudElem = element.element("cloud")
        if (cloudElem != null) {
            _cloud = RssCloud.parse(cloudElem)
        }

        var ttlElem = element.element("ttl")
        if (ttlElem != null) {
            _ttl = Num.fromString(ttlElem.value)
        }

        var imageElem = element.element("image")
        if (imageElem != null) {
            _image = RssImage.parse(imageElem)
        }

        _rating = element.elementValue("rating")

        var textInputEl = element.element("textInput")
        if (textInputEl != null) {
            _textInput = RssTextInput.parse(textInputEl)
        }

        _skipHours = []
        var skipHoursEl = element.element("skipHours")
        if (skipHoursEl != null) {
            for (hour in skipHoursEl.elements("hour")) {
                _skipHours.add(Num.fromString(hour.value))
            }
        }
        _skipDays = []
        var skipDaysEl = element.element("skipDays")
        if (skipDaysEl != null) {
            for (day in skipDaysEl.elements("day")) {
                _skipDays.add(day.value)
            }
        }

        _items = element.elements("item").map {|e| RssItem.parse(e) }.toList
    }

}

class Rss {
    channel { _channel }
    construct parse(document) {
        var root = document.element("rss")
        if (root == null) {
            Fiber.abort("Missing required root element 'rss'")
        }
        var channelEl = root.element("channel")
        if (channelEl == null) {
            Fiber.abort("Missing required element 'channel' in Rss")
        }
        _channel = RssChannel.parse(channelEl)
    }
}


// test

import "../../xsequence" for XDocument
import "io" for File

var txt = File.read("examples/rss/rss_sample.xml")
var doc = XDocument.parse(txt)
var rss = Rss.parse(doc)

System.print(rss.channel.title)
for (item in rss.channel.items) {
    System.write("- ")
    if (item.title != null) {
        System.write(item.title + ": ")
    }
    if (item.description != null) {
        System.write(item.description)
    }
    System.print()
    
}
