import Bonsai
import Foundation

let path = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .appendingPathComponent("fixture.html")
  .path
let html = try String(contentsOfFile: path, encoding: .utf8)
print("Loaded \(html.count) characters from \(path)")

let iterations = 1000

// Warm up
for _ in 0 ..< 10 {
  _ = Bonsai.minifyHTML(html)
}

let start = DispatchTime.now()
for _ in 0 ..< iterations {
  _ = Bonsai.minifyHTML(html)
}

let end = DispatchTime.now()

let nanoseconds = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
let totalSeconds = nanoseconds / 1_000_000_000
let opsPerSec = Double(iterations) / totalSeconds
let avgMs = (totalSeconds / Double(iterations)) * 1000

print(String(format: "Iterations: %d", iterations))
print(String(format: "Total time: %.3f s", totalSeconds))
print(String(format: "Average:    %.3f ms/op", avgMs))
print(String(format: "Throughput: %.1f ops/sec", opsPerSec))
