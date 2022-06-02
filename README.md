# wren-xsequence

Xml parser/writer for [Wren](https://wren.io/)

Api similar to [C#'s XLinq](https://docs.microsoft.com/en-us/dotnet/standard/linq/linq-xml-overview)

To use, take the single file `xsequence.wren` and put it into your project

## Quick Examples

TODO: Examples

## Testing

Using [wren-assert](https://github.com/RobLoach/wren-assert) for generic assertions.

To run tests use [wren cli](https://github.com/wren-lang/wren-cli)

```powershell
> wren_cli.exe test.wren
```

The exceptions are caught by default, which loses the call stack. To view the callstack set at the start of the file the global variable `DEBUG=true`

## Limitations

- Does not support creating comments. Comments are skipped by the parser.

TODO: Other limitations
