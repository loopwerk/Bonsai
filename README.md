# Bonsai

An HTML minifier in pure Swift.

Zero dependencies, comprehensive test suite (149 tests ported from html-minifier-next), replicates the output of [html-minifier-next](https://github.com/j9t/html-minifier-next) with the following options:

| html-minifier-next option | Notes |
|---|---|
| `caseSensitive: true` | Preserves tag and attribute name case |
| `collapseBooleanAttributes: true` | Also handles `draggable`, `crossorigin`, `contenteditable` |
| `collapseWhitespace: true` | Inline/block-aware smart collapsing |
| `removeComments: true` | Keeps `<!--! -->` bang comments and conditional comments |
| `removeEmptyAttributes: true` | `class`, `id`, `style`, `title`, `lang`, `dir`, `value`, event handlers |
| `removeRedundantAttributes: true` | Default values, script `language`/`charset`, `a[name]` matching `id` |
| `removeScriptTypeAttributes: true` | Removes `type="text/javascript"` and variants |
| `removeStyleLinkTypeAttributes: true` | Removes `type="text/css"` from `<style>` and `<link>` |
| `useShortDoctype: true` | All doctypes become `<!doctype html>` |

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
| Bonsai (Swift) | 0.9 ms | 1,149 ops/sec |

The speed difference between Bonsai and html-minifier-next only becomes noticeable at scale; for individual pages, both finish under a millisecond.

To run the benchmark yourself:

```bash
# Swift (release mode)
swift run -c release BonsaiBenchmark
```
