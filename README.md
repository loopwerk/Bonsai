# Bonsai

An HTML minifier in pure Swift.

Zero dependencies, comprehensive test suite (183 tests), inspired by [html-minifier-next](https://github.com/j9t/html-minifier-next).

- Collapses whitespace runs to a single space
- Preserves line breaks at text node boundaries
- Removes comments (keeps bang comments and conditional comments)
- Processes conditional comment content (recursively minifies)
- Collapses boolean attributes (preserving original case)
- Removes redundant attributes (default values, script language/charset, etc.)
- Removes empty attributes (class, id, style, event handlers, etc.)
- Collapses whitespace in attribute values
- Removes redundant script/style/link type attributes
- Shortens doctype to `<!doctype html>`
- Preserves tag and attribute name case
- Preserves content inside `<pre>` and `<textarea>` elements

## Usage
Include `Bonsai` in your Package.swift:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/loopwerk/Bonsai", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "MyProject",
      dependencies: ["Bonsai"]),
  ]
)
```

Using it is a simple import and function call:

```swift
import Bonsai

let result = Bonsai.minifyHTML("<html>")
```

There are no options or settings to configure.

## Performance

Benchmarked on a ~143 KB HTML page (1000 iterations, release build), using a M1 Max Macbook Pro:

| Tool | Avg time per operation | Throughput |
|---|---|---|
| [html-minifier](https://github.com/kangax/html-minifier) (Node.js) | 12.1 ms | 83 ops/sec |
| [html-minifier-terser](https://github.com/terser/html-minifier-terser) (Node.js) | 14.3 ms | 70 ops/sec |
| html-minifier-next (Node.js) | 0.6 ms | 1,817 ops/sec |
| Bonsai (Swift) | 0.8 ms | 1,270 ops/sec |

The speed difference between Bonsai and html-minifier-next only becomes noticeable at scale; for individual pages, both finish under a millisecond.

To run the benchmark yourself:

```bash
# Swift (release mode)
swift run -c release BonsaiBenchmark
```
