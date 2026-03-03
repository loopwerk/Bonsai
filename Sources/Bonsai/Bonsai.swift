public enum Bonsai {
  /// Minify an HTML string.
  ///
  /// - Collapses whitespace intelligently (block vs inline aware)
  /// - Removes whitespace between block elements
  /// - Preserves whitespace between inline elements
  /// - Removes comments (keeps bang comments and conditional comments)
  /// - Processes conditional comment content (recursively minifies)
  /// - Collapses boolean attributes (preserving original case)
  /// - Removes redundant script/style/link type attributes
  /// - Shortens doctype to `<!doctype html>`
  /// - Preserves tag and attribute name case (caseSensitive)
  /// - Preserves content inside `<pre>` and `<textarea>` elements
  public static func minifyHTML(_ html: String) -> String {
    var html = html
    return html.withUTF8 { utf8 in
      _minifyHTML(utf8)
    }
  }

  /// Internal single-pass implementation that works directly on a borrowed UTF-8 buffer.
  /// Inlines all HTML parsing and applies minification rules in one pass.
  private static func _minifyHTML(_ utf8: UnsafeBufferPointer<UInt8>) -> String {
    let bytes = utf8
    let end = bytes.count
    var output: [UInt8] = []
    output.reserveCapacity(end)

    var preserveDepth = 0
    var rawContentDepth = 0
    var foreignContentDepth = 0

    var attrs = [RawAttr]()
    attrs.reserveCapacity(16)

    // Tag context for smart whitespace collapsing
    var prevTagHash: UInt64 = 0
    var prevTagIsClosing = false
    // Track position in output before the last emitted tag (for wbr/nobr walk-back)
    var outputPosBeforeLastTag = 0
    // Whether the last emitted comment was kept (for prevTag=comment handling)
    var prevWasKeptComment = false
    // Track text accumulation state for inline dedup (mirrors html-minifier-next's currentChars)
    var charsEndState: CharsEndState = .empty
    // Track whether current element has emitted any text (for empty inline detection)
    var hasChars = false

    var i = 0

    while i < end {
      if bytes[i] == 0x3C { // <
        let afterLT = i + 1
        if afterLT >= end {
          let next = peekNextTagHash(bytes, end, i)
          appendSmartText(bytes, i, end,
                          prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                          nextTag: next?.hash ?? 0, nextTagIsClosing: next?.isClosing ?? false,
                          prevWasKeptComment: prevWasKeptComment,
                          charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
          break
        }

        // Comment: <!-- ... -->
        if afterLT + 2 < end
          && bytes[afterLT] == 0x21
          && bytes[afterLT + 1] == 0x2D
          && bytes[afterLT + 2] == 0x2D
        {
          let outputBefore = output.count
          i = handleComment(bytes, end, i, &output)
          // If comment was kept, treat as inline for whitespace purposes
          prevWasKeptComment = output.count > outputBefore
          if !prevWasKeptComment {
            // Comment was removed — prevTag stays unchanged
          }
          continue
        }

        // Doctype: <!DOCTYPE ...>
        if bytes[afterLT] == 0x21 {
          if matchesDoctypeCI(bytes, end, afterLT) {
            // Skip to closing >
            var j = afterLT
            while j < end, bytes[j] != 0x3E {
              j += 1
            }
            if j < end {
              output.append(contentsOf: doctypeBytes)
              i = j + 1
            } else {
              let next = peekNextTagHash(bytes, end, i)
              appendSmartText(bytes, i, end,
                              prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                              nextTag: next?.hash ?? 0, nextTagIsClosing: next?.isClosing ?? false,
                              prevWasKeptComment: prevWasKeptComment,
                              charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
              i = end
            }
            prevWasKeptComment = false
            continue
          }
        }

        // CDATA: <![CDATA[ ... ]]>
        if afterLT + 7 < end
          && bytes[afterLT] == 0x21
          && bytes[afterLT + 1] == 0x5B
          && bytes[afterLT + 2] == 0x43
          && bytes[afterLT + 3] == 0x44
          && bytes[afterLT + 4] == 0x41
          && bytes[afterLT + 5] == 0x54
          && bytes[afterLT + 6] == 0x41
          && bytes[afterLT + 7] == 0x5B
        {
          let contentStart = i + 9
          if let pos = findBytesIn(bytes, end, cdataEnd, from: contentStart) {
            if preserveDepth > 0 {
              output.append(contentsOf: bytes[contentStart ..< pos])
            } else if rawContentDepth > 0 {
              appendRawContentText(bytes, contentStart, pos, to: &output)
            } else {
              let next = peekNextTagHash(bytes, end, pos + 3)
              appendSmartText(bytes, contentStart, pos,
                              prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                              nextTag: next?.hash ?? 0, nextTagIsClosing: next?.isClosing ?? false,
                              prevWasKeptComment: prevWasKeptComment,
                              charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
            }
            i = pos + 3
          } else {
            if preserveDepth > 0 {
              output.append(contentsOf: bytes[contentStart ..< end])
            } else if rawContentDepth > 0 {
              appendRawContentText(bytes, contentStart, end, to: &output)
            } else {
              appendSmartText(bytes, contentStart, end,
                              prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                              nextTag: 0, nextTagIsClosing: false,
                              prevWasKeptComment: prevWasKeptComment,
                              charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
            }
            i = end
          }
          prevWasKeptComment = false
          continue
        }

        // End tag: </...>
        if bytes[afterLT] == 0x2F {
          outputPosBeforeLastTag = output.count
          i = handleEndTag(bytes, end, i, &output, &preserveDepth, &rawContentDepth, &foreignContentDepth)
          // Extract tag hash from the end tag we just processed
          let ntStart = afterLT + 1
          var ntEnd = ntStart
          while ntEnd < end, !isWSByte(bytes[ntEnd]), bytes[ntEnd] != 0x3E {
            ntEnd += 1
          }
          if ntEnd > ntStart {
            prevTagHash = fnvHashLowered(bytes, ntStart, ntEnd)
            prevTagIsClosing = true
            // Update charsEndState: block tags reset to .empty, empty inline elements → .other
            if !inlineKeepWSAroundHashes.contains(prevTagHash) {
              charsEndState = .empty
            } else if !hasChars {
              // Empty inline element (e.g., <i></i>) → .other
              charsEndState = .other
            }
          }
          prevWasKeptComment = false
          continue
        }

        // Start tag: letter or _
        if isASCIILetter(bytes[afterLT]) || bytes[afterLT] == 0x5F {
          // Squash trailing WS from previously-emitted text (retroactive trimming)
          if preserveDepth == 0, rawContentDepth == 0 {
            // Peek the tag name to pass to squashTrailingWS
            var peekEnd = afterLT
            while peekEnd < end,
                  !isWSByte(bytes[peekEnd]),
                  bytes[peekEnd] != 0x2F,
                  bytes[peekEnd] != 0x3E
            {
              peekEnd += 1
            }
            if peekEnd > afterLT {
              let peekHash = fnvHashLowered(bytes, afterLT, peekEnd)
              squashTrailingWS(&output, nextTag: peekHash, nextTagIsClosing: false)
            }
          }
          outputPosBeforeLastTag = output.count
          i = handleStartTag(bytes, end, i, &output, &attrs,
                             &preserveDepth, &rawContentDepth, &foreignContentDepth)
          // Extract tag hash from the start tag we just processed
          let ntStart = afterLT
          var ntEnd = ntStart
          while ntEnd < end,
                !isWSByte(bytes[ntEnd]),
                bytes[ntEnd] != 0x2F,
                bytes[ntEnd] != 0x3E
          {
            ntEnd += 1
          }
          if ntEnd > ntStart {
            prevTagHash = fnvHashLowered(bytes, ntStart, ntEnd)
            prevTagIsClosing = false
            // Update charsEndState: non-inline start tags reset to .empty
            if !inlineKeepWSWithinHashes.contains(prevTagHash) {
              charsEndState = .empty
            }
            // Reset hasChars for empty inline element detection
            hasChars = false
          }
          prevWasKeptComment = false
          continue
        }

        // Not a recognized tag — emit as text
        if preserveDepth > 0 {
          output.append(contentsOf: bytes[i ..< afterLT])
        } else if rawContentDepth > 0 {
          appendRawContentText(bytes, i, afterLT, to: &output)
        } else {
          let next = peekNextTagHash(bytes, end, afterLT)
          appendSmartText(bytes, i, afterLT,
                          prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                          nextTag: next?.hash ?? 0, nextTagIsClosing: next?.isClosing ?? false,
                          prevWasKeptComment: prevWasKeptComment,
                          charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
        }
        prevWasKeptComment = false
        i = afterLT
      } else {
        // Accumulate text until next <
        let start = i
        i += 1
        while i < end, bytes[i] != 0x3C {
          i += 1
        }
        if preserveDepth > 0 {
          output.append(contentsOf: bytes[start ..< i])
        } else if rawContentDepth > 0 {
          appendRawContentText(bytes, start, i, to: &output)
        } else {
          let next = i < end ? peekNextTagHash(bytes, end, i) : nil
          // wbr/nobr walk-back: if prevTag is wbr or /nobr and text starts with WS,
          // trim trailing WS from output before the tag
          if start < i, isWSByte(bytes[start]) {
            if (prevTagHash == wbrHash && !prevTagIsClosing)
              || (prevTagHash == nobrHash && prevTagIsClosing)
            {
              let beforeTrim = output.count
              trimTrailingWSBeforeTag(&output, outputPosBeforeLastTag)
              // If whitespace was removed, update charsEndState so inline dedup
              // doesn't incorrectly trim the next text's leading space
              if output.count < beforeTrim {
                charsEndState = .other
              }
            }
          }
          appendSmartText(bytes, start, i,
                          prevTag: prevTagHash, prevTagIsClosing: prevTagIsClosing,
                          nextTag: next?.hash ?? 0, nextTagIsClosing: next?.isClosing ?? false,
                          prevWasKeptComment: prevWasKeptComment,
                          charsEndState: &charsEndState, hasChars: &hasChars, to: &output)
        }
        prevWasKeptComment = false
      }
    }

    // Document-end squash: retroactively trim trailing WS (equivalent to html-minifier-next's
    // synthetic 'br' tag at line 1612, which triggers trimRight=true)
    squashTrailingWS(&output, nextTag: 0, nextTagIsClosing: false)

    return String(decoding: output, as: UTF8.self)
  }
}

// MARK: - CharsEndState

/// Tracks text accumulation state for inline whitespace deduplication.
/// Mirrors html-minifier-next's `currentChars` behavior.
private enum CharsEndState {
  case empty // No text since block boundary (matches regex /^$/)
  case endsWithWS // Last text ended with whitespace
  case other // Last text ended with non-WS or empty inline element seen
}

// MARK: - RawAttr

/// A parsed HTML attribute stored as byte ranges into the parser's buffer.
/// No String allocations — names and values are referenced by position only.
private struct RawAttr {
  var nameStart: Int
  var nameEnd: Int
  var valueStart: Int
  var valueEnd: Int
  var hasValue: Bool
}

// MARK: - Precomputed byte arrays

private let doctypeBytes: [UInt8] = Array("<!doctype html>".utf8)
private let commentOpen: [UInt8] = Array("<!--".utf8)
private let commentClose: [UInt8] = Array("-->".utf8)
private let cdataEnd: [UInt8] = [0x5D, 0x5D, 0x3E] // ]]>
private let trueBytes: [UInt8] = Array("true".utf8)
private let falseBytes: [UInt8] = Array("false".utf8)
private let typeBytesExact: [UInt8] = Array("type".utf8)
private let scriptBytesExact: [UInt8] = Array("script".utf8)
private let styleBytesExact: [UInt8] = Array("style".utf8)
private let linkBytesExact: [UInt8] = Array("link".utf8)

// MARK: - Byte-level helpers

@inline(__always)
private func isWSByte(_ b: UInt8) -> Bool {
  b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09 || b == 0x0C
}

@inline(__always)
private func isNewlineByte(_ b: UInt8) -> Bool {
  b == 0x0A || b == 0x0D
}

@inline(__always)
private func toLowerASCII(_ b: UInt8) -> UInt8 {
  (b >= 0x41 && b <= 0x5A) ? b | 0x20 : b
}

@inline(__always)
private func isASCIILetter(_ b: UInt8) -> Bool {
  (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A)
}

private func containsNewlineInBytes(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> Bool {
  for i in start ..< end {
    if isNewlineByte(bytes[i]) { return true }
  }
  return false
}

/// Check if byte range matches target after lowercasing each byte.
@inline(__always)
private func bytesMatchLowered(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, _ target: [UInt8]) -> Bool {
  guard end - start == target.count else { return false }
  for i in 0 ..< target.count {
    if toLowerASCII(bytes[start + i]) != target[i] { return false }
  }
  return true
}

/// Exact (case-sensitive) byte comparison.
@inline(__always)
private func bytesMatchExact(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, _ target: [UInt8]) -> Bool {
  guard end - start == target.count else { return false }
  for i in 0 ..< target.count {
    if bytes[start + i] != target[i] { return false }
  }
  return true
}

/// Return (trimStart, trimEnd) with leading/trailing ASCII whitespace removed.
private func trimWSRange(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> (Int, Int) {
  var s = start
  while s < end, isWSByte(bytes[s]) {
    s += 1
  }
  var e = end
  while e > s, isWSByte(bytes[e - 1]) {
    e -= 1
  }
  return (s, e)
}

/// Return the end position of content before the first semicolon.
private func splitSemicolonEnd(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> Int {
  for i in start ..< end {
    if bytes[i] == 0x3B { return i }
  }
  return end
}

/// Check if a byte range is entirely ASCII whitespace (or empty).
@inline(__always)
private func isAllWhitespaceByte(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int) -> Bool {
  for i in start ..< end {
    if !isWSByte(bytes[i]) { return false }
  }
  return true
}

/// Peek at the next tag starting at position `pos` (which should point at `<`).
/// Returns the lowered hash of the tag name and whether it's a closing tag.
private func peekNextTagHash(
  _ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ pos: Int
) -> (hash: UInt64, isClosing: Bool)? {
  guard pos < end, bytes[pos] == 0x3C else { return nil }
  let afterLT = pos + 1
  guard afterLT < end else { return nil }

  // Closing tag: </tagname
  if bytes[afterLT] == 0x2F {
    let nameStart = afterLT + 1
    guard nameStart < end else { return nil }
    var nameEnd = nameStart
    while nameEnd < end, !isWSByte(bytes[nameEnd]), bytes[nameEnd] != 0x3E {
      nameEnd += 1
    }
    guard nameEnd > nameStart else { return nil }
    return (fnvHashLowered(bytes, nameStart, nameEnd), true)
  }

  // Opening tag: <tagname
  if isASCIILetter(bytes[afterLT]) || bytes[afterLT] == 0x5F {
    var nameEnd = afterLT
    while nameEnd < end,
          !isWSByte(bytes[nameEnd]),
          bytes[nameEnd] != 0x2F,
          bytes[nameEnd] != 0x3E
    {
      nameEnd += 1
    }
    guard nameEnd > afterLT else { return nil }
    return (fnvHashLowered(bytes, afterLT, nameEnd), false)
  }

  // Comment: <!-- treated as inline for whitespace
  if afterLT + 2 < end,
     bytes[afterLT] == 0x21,
     bytes[afterLT + 1] == 0x2D,
     bytes[afterLT + 2] == 0x2D
  {
    return nil // Comments don't affect trim decisions from the next side
  }

  return nil
}

/// Walk back in the output buffer from `tagStart` and trim trailing ASCII whitespace.
/// Used for wbr/nobr deduplication: when text after <wbr> or </nobr> starts with
/// whitespace, trim trailing whitespace from before the tag in the output.
private func trimTrailingWSBeforeTag(_ output: inout [UInt8], _ tagStart: Int) {
  var pos = tagStart
  while pos > 0, isWSByte(output[pos - 1]) {
    pos -= 1
  }
  if pos < tagStart {
    output.removeSubrange(pos ..< tagStart)
  }
}

/// Retroactively trim trailing whitespace from the output buffer.
/// Walks backward through output, skipping closing tags (but stopping at </pre> or </textarea>).
/// When it finds text content, trims trailing ASCII whitespace if `nextTag` triggers trimRight.
/// Only whitespace bytes are removed — closing tags are preserved.
/// Mirrors html-minifier-next's `squashTrailingWhitespace` (lines 1071-1080).
private func squashTrailingWS(
  _ output: inout [UInt8],
  nextTag: UInt64, nextTagIsClosing: Bool
) {
  // Compute trimRight for this nextTag
  var trimRight = false
  if nextTag == 0 {
    trimRight = true
  } else if !inlineKeepWSAlwaysHashes.contains(nextTag) {
    if nextTagIsClosing {
      trimRight = !inlineKeepWSWithinHashes.contains(nextTag)
    } else {
      trimRight = !inlineKeepWSAroundHashes.contains(nextTag)
    }
  }
  guard trimRight else { return }

  // Walk backward to find where text content ends (before any trailing closing tags)
  var textEnd = output.count
  var pos = output.count - 1
  while pos >= 0 {
    if output[pos] == 0x3E { // '>'
      // Find matching '<'
      var tagStart = pos - 1
      while tagStart >= 0, output[tagStart] != 0x3C {
        tagStart -= 1
      }
      if tagStart >= 0, tagStart + 1 < pos, output[tagStart + 1] == 0x2F {
        // It's a closing tag — check if it's pre/textarea (can't trim through those)
        let nameStart = tagStart + 2
        let nameEnd = pos
        var h: UInt64 = 14_695_981_039_346_656_037
        for k in nameStart ..< nameEnd {
          h ^= UInt64(output[k])
          h &*= 1_099_511_628_211
        }
        if preserveWhitespaceHashes.contains(h) {
          return // Can't trim through pre/textarea
        }
        // Skip past this closing tag — record where tags begin
        textEnd = tagStart
        pos = tagStart - 1
        continue
      }
      return // Start tag or other — stop, don't trim
    }
    break // Not a tag byte — found text content
  }

  // Trim trailing whitespace bytes before the closing tags
  var wsStart = textEnd
  while wsStart > 0, isWSByte(output[wsStart - 1]) {
    wsStart -= 1
  }
  if wsStart < textEnd {
    output.removeSubrange(wsStart ..< textEnd)
  }
}

/// Find `needle` bytes in `bytes[from ..< end]`.
private func findBytesIn(_ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ needle: [UInt8], from start: Int) -> Int? {
  let limit = end - needle.count
  guard limit >= start else { return nil }
  var i = start
  while i <= limit {
    var matched = true
    for j in 0 ..< needle.count {
      if bytes[i + j] != needle[j] {
        matched = false
        break
      }
    }
    if matched { return i }
    i += 1
  }
  return nil
}

/// Case-insensitive match at position.
@inline(__always)
private func matchesCaseInsensitive(_ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, at pos: Int, count: Int, pattern: [UInt8]) -> Bool {
  guard pos + count <= end else { return false }
  for j in 0 ..< count {
    if toLowerASCII(bytes[pos + j]) != toLowerASCII(pattern[j]) { return false }
  }
  return true
}

/// Check if bytes at afterLT match "!DOCTYPE" case-insensitively.
private func matchesDoctypeCI(_ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ afterLT: Int) -> Bool {
  let pattern: [UInt8] = [0x21, 0x44, 0x4F, 0x43, 0x54, 0x59, 0x50, 0x45]
  return matchesCaseInsensitive(bytes, end, at: afterLT, count: 8, pattern: pattern)
}

/// Find the closing `>` of a tag, skipping over quoted attribute values.
private func findTagEnd(_ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, from start: Int) -> Int? {
  var i = start
  while i < end {
    let b = bytes[i]
    if b == 0x3E { return i }
    if b == 0x22 || b == 0x27 {
      let quote = b
      i += 1
      while i < end, bytes[i] != quote {
        i += 1
      }
      if i < end { i += 1 }
      continue
    }
    i += 1
  }
  return nil
}

// MARK: - Attribute parsing (into RawAttr buffer)

private func parseAttributes(_ bytes: UnsafeBufferPointer<UInt8>, from start: Int, end: Int, into attrs: inout [RawAttr]) {
  attrs.removeAll(keepingCapacity: true)
  var pos = start

  while pos < end {
    while pos < end, isWSByte(bytes[pos]) || bytes[pos] == 0x2F {
      pos += 1
    }
    if pos >= end { break }

    let nameStart = pos
    while pos < end,
          bytes[pos] != 0x3D,
          !isWSByte(bytes[pos]),
          bytes[pos] != 0x2F,
          bytes[pos] != 0x3E
    {
      pos += 1
    }
    if pos == nameStart { break }
    let nameEnd = pos

    while pos < end, isWSByte(bytes[pos]) {
      pos += 1
    }

    if pos < end, bytes[pos] == 0x3D {
      pos += 1
      while pos < end, isWSByte(bytes[pos]) {
        pos += 1
      }

      if pos < end, bytes[pos] == 0x22 || bytes[pos] == 0x27 {
        let quote = bytes[pos]
        pos += 1
        let valStart = pos
        while pos < end, bytes[pos] != quote {
          pos += 1
        }
        let valEnd = pos
        if pos < end { pos += 1 }
        attrs.append(RawAttr(nameStart: nameStart, nameEnd: nameEnd, valueStart: valStart, valueEnd: valEnd, hasValue: true))
      } else {
        let valStart = pos
        while pos < end, !isWSByte(bytes[pos]), bytes[pos] != 0x3E, bytes[pos] != 0x2F {
          pos += 1
        }
        attrs.append(RawAttr(nameStart: nameStart, nameEnd: nameEnd, valueStart: valStart, valueEnd: pos, hasValue: true))
      }
    } else {
      attrs.append(RawAttr(nameStart: nameStart, nameEnd: nameEnd, valueStart: 0, valueEnd: 0, hasValue: false))
    }
  }
}

// MARK: - Comment handling

private func handleComment(_ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ start: Int, _ output: inout [UInt8]) -> Int {
  let contentStart = start + 4
  let endMarker: [UInt8] = [0x2D, 0x2D, 0x3E]
  let cEnd: Int
  let nextPos: Int

  if let pos = findBytesIn(bytes, end, endMarker, from: contentStart) {
    cEnd = pos
    nextPos = pos + 3
  } else {
    cEnd = end
    nextPos = end
  }

  guard contentStart < cEnd else { return nextPos }
  let firstByte = bytes[contentStart]

  // Preserve bang comments (<!--! ... -->)
  if firstByte == 0x21 {
    output.append(contentsOf: commentOpen)
    output.append(contentsOf: bytes[contentStart ..< cEnd])
    output.append(contentsOf: commentClose)
    return nextPos
  }

  // Special comments starting with [ or <
  if firstByte == 0x5B || firstByte == 0x3C {
    let content = String(decoding: bytes[contentStart ..< cEnd], as: UTF8.self)

    if content.hasPrefix("[if ") {
      if let closingRange = findSubstringInString("]>", in: content),
         let endifRange = findSubstringInString("<![endif]", in: content)
      {
        let before = content[content.startIndex ..< closingRange.upperBound]
        let inner = String(content[closingRange.upperBound ..< endifRange.lowerBound])
        let after = content[endifRange.lowerBound ..< content.endIndex]
        output.append(contentsOf: commentOpen)
        output.append(contentsOf: before.utf8)
        output.append(contentsOf: Bonsai.minifyHTML(inner).utf8)
        output.append(contentsOf: after.utf8)
        output.append(contentsOf: commentClose)
      } else {
        output.append(contentsOf: commentOpen)
        output.append(contentsOf: bytes[contentStart ..< cEnd])
        output.append(contentsOf: commentClose)
      }
      return nextPos
    }

    if content.hasPrefix("<![endif") || content.hasPrefix("[endif") {
      output.append(contentsOf: commentOpen)
      output.append(contentsOf: bytes[contentStart ..< cEnd])
      output.append(contentsOf: commentClose)
      return nextPos
    }
  }

  // Drop regular comments
  return nextPos
}

// MARK: - End tag handling

private func handleEndTag(
  _ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ start: Int,
  _ output: inout [UInt8],
  _ preserveDepth: inout Int, _ rawContentDepth: inout Int, _ foreignContentDepth: inout Int
) -> Int {
  var closeAngle = start
  while closeAngle < end, bytes[closeAngle] != 0x3E {
    closeAngle += 1
  }
  guard closeAngle < end else {
    appendCollapsedText(bytes, start, end, to: &output)
    return end
  }

  var nameStart = start + 2
  while nameStart < closeAngle, isWSByte(bytes[nameStart]) {
    nameStart += 1
  }
  var nameEnd = nameStart
  while nameEnd < closeAngle, !isWSByte(bytes[nameEnd]), bytes[nameEnd] != 0x3E {
    nameEnd += 1
  }

  if nameEnd > nameStart {
    output.append(0x3C)
    output.append(0x2F)
    output.append(contentsOf: bytes[nameStart ..< nameEnd])
    output.append(0x3E)

    let tagHashLower = fnvHashLowered(bytes, nameStart, nameEnd)
    let tagHashExact = fnvHash(bytes, nameStart, nameEnd)

    if preserveWhitespaceHashes.contains(tagHashExact), preserveDepth > 0 {
      preserveDepth -= 1
    }
    if rawContentElementHashes.contains(tagHashLower), rawContentDepth > 0 {
      rawContentDepth -= 1
    }
    if tagHashLower == svgHash || tagHashLower == mathHash, foreignContentDepth > 0 {
      foreignContentDepth -= 1
    }
  } else {
    output.append(contentsOf: bytes[start ..< closeAngle + 1])
  }
  return closeAngle + 1
}

// MARK: - Start tag handling

private func handleStartTag(
  _ bytes: UnsafeBufferPointer<UInt8>, _ end: Int, _ start: Int,
  _ output: inout [UInt8], _ attrs: inout [RawAttr],
  _ preserveDepth: inout Int, _ rawContentDepth: inout Int, _ foreignContentDepth: inout Int
) -> Int {
  let nameStart = start + 1

  guard let closeAngle = findTagEnd(bytes, end, from: nameStart) else {
    appendCollapsedText(bytes, start, end, to: &output)
    return end
  }

  var nameEnd = nameStart
  while nameEnd < closeAngle,
        !isWSByte(bytes[nameEnd]),
        bytes[nameEnd] != 0x2F,
        bytes[nameEnd] != 0x3E
  {
    nameEnd += 1
  }

  let tagHash = fnvHashLowered(bytes, nameStart, nameEnd)
  let tagHashExact = fnvHash(bytes, nameStart, nameEnd)
  let isVoid = voidElementHashes.contains(tagHash)
  let selfClosing = bytes[closeAngle - 1] == 0x2F || isVoid

  parseAttributes(bytes, from: nameEnd, end: closeAngle, into: &attrs)

  // Write tag name
  output.append(0x3C)
  output.append(contentsOf: bytes[nameStart ..< nameEnd])

  // Process attributes
  for ai in 0 ..< attrs.count {
    let attr = attrs[ai]
    let attrHash = fnvHashLowered(bytes, attr.nameStart, attr.nameEnd)

    // Remove redundant type attributes on script/style/link
    // caseSensitive: both attribute name AND tag name must be exact lowercase
    if attrHash == typeHash
      && bytesMatchExact(bytes, attr.nameStart, attr.nameEnd, typeBytesExact)
    {
      if tagHash == scriptHash
        && bytesMatchExact(bytes, nameStart, nameEnd, scriptBytesExact)
      {
        if !attr.hasValue { continue }
        let (ts, te) = trimWSRange(bytes, attr.valueStart, attr.valueEnd)
        let se = splitSemicolonEnd(bytes, ts, te)
        let valueTrimmedLower = String(decoding: bytes[ts ..< se], as: UTF8.self).lowercased()
        if valueTrimmedLower.isEmpty || executableScriptTypes.contains(valueTrimmedLower) {
          if valueTrimmedLower != "module" { continue }
        }
      }
      if (tagHash == styleHash || tagHash == linkHash)
        && (bytesMatchExact(bytes, nameStart, nameEnd, styleBytesExact)
          || bytesMatchExact(bytes, nameStart, nameEnd, linkBytesExact))
      {
        if !attr.hasValue { continue }
        let (ts, te) = trimWSRange(bytes, attr.valueStart, attr.valueEnd)
        let valueTrimmedLower = String(decoding: bytes[ts ..< te], as: UTF8.self).lowercased()
        if valueTrimmedLower.isEmpty || valueTrimmedLower == "text/css" { continue }
      }
    }

    // Remove redundant attributes (skip type on script/style/link — already handled)
    if attrHash != typeHash || (tagHash != scriptHash && tagHash != styleHash && tagHash != linkHash) {
      // Legacy: script language
      if tagHash == scriptHash && attrHash == languageHash { continue }

      // Legacy: script charset without src
      if tagHash == scriptHash && attrHash == charsetHash {
        if !attrsContainHash(bytes, attrs, srcHash) { continue }
      }

      // Legacy: a[name] matching a[id]
      if tagHash == aHash && attrHash == nameHash {
        if let idIdx = attrIndexByHash(bytes, attrs, idHash) {
          let idAttr = attrs[idIdx]
          if idAttr.hasValue && attr.hasValue {
            let (its, ite) = trimWSRange(bytes, idAttr.valueStart, idAttr.valueEnd)
            let (nts, nte) = trimWSRange(bytes, attr.valueStart, attr.valueEnd)
            if bytesEqualLowered(bytes, its, ite, nts, nte) { continue }
          }
        }
      }

      // General + tag-specific defaults
      if attr.hasValue {
        let (ts, te) = trimWSRange(bytes, attr.valueStart, attr.valueEnd)
        var isDefault = false
        for d in defaultAttrs {
          if d.attrHash == attrHash && (d.tagHash == 0 || d.tagHash == tagHash) {
            if bytesMatchLowered(bytes, ts, te, d.value) {
              isDefault = true
              break
            }
          }
        }
        if isDefault { continue }
      }
    }

    // Collapse boolean attributes
    if booleanAttributeHashes.contains(attrHash) {
      output.append(0x20)
      output.append(contentsOf: bytes[attr.nameStart ..< attr.nameEnd])
      continue
    }

    // Draggable special case
    if attrHash == draggableHash {
      if !attr.hasValue
        || (!bytesMatchLowered(bytes, attr.valueStart, attr.valueEnd, trueBytes)
          && !bytesMatchLowered(bytes, attr.valueStart, attr.valueEnd, falseBytes))
      {
        output.append(0x20)
        output.append(contentsOf: bytes[attr.nameStart ..< attr.nameEnd])
        continue
      }
    }

    // Empty collapsible
    if emptyCollapsibleAttributeHashes.contains(attrHash) {
      if !attr.hasValue || attr.valueStart == attr.valueEnd {
        output.append(0x20)
        output.append(contentsOf: bytes[attr.nameStart ..< attr.nameEnd])
        continue
      }
    }

    // Empty removable
    if emptyRemovableAttributeHashes.contains(attrHash) {
      if !attr.hasValue || isAllWhitespaceByte(bytes, attr.valueStart, attr.valueEnd) {
        continue
      }
    }

    // Output attribute
    output.append(0x20)
    output.append(contentsOf: bytes[attr.nameStart ..< attr.nameEnd])
    if attr.hasValue {
      output.append(0x3D) // =
      output.append(0x22) // "
      if preserveDepth > 0 || attrHash == valueAttrHash || attrHash == styleAttrHash {
        output.append(contentsOf: bytes[attr.valueStart ..< attr.valueEnd])
      } else {
        appendCollapsedAttributeValue(bytes, attr.valueStart, attr.valueEnd, to: &output)
      }
      output.append(0x22) // "
    }
  }

  // Self-closing slash handling
  if selfClosing && !isVoid {
    if foreignContentDepth > 0 {
      output.append(0x2F)
      output.append(0x3E)
    } else {
      output.append(0x3E)
    }
  } else {
    output.append(0x3E)
  }

  if !selfClosing {
    if preserveWhitespaceHashes.contains(tagHashExact) {
      preserveDepth += 1
    }
    if rawContentElementHashes.contains(tagHash) {
      rawContentDepth += 1
    }
    if tagHash == svgHash || tagHash == mathHash {
      foreignContentDepth += 1
    }
  }

  let afterTag = closeAngle + 1

  // Raw content elements: scan for matching </tag>
  if rawContentElementHashes.contains(tagHash) && !selfClosing {
    return parseRawContent(bytes, end, nameStart, nameEnd, afterTag, &output,
                           &preserveDepth, &rawContentDepth, &foreignContentDepth)
  }

  return afterTag
}

// MARK: - Raw content scan (script/style)

private func parseRawContent(
  _ bytes: UnsafeBufferPointer<UInt8>, _ end: Int,
  _ tagNameStart: Int, _ tagNameEnd: Int, _ from: Int,
  _ output: inout [UInt8],
  _ preserveDepth: inout Int, _ rawContentDepth: inout Int, _ foreignContentDepth: inout Int
) -> Int {
  let tagLen = tagNameEnd - tagNameStart
  var closingTagLower: [UInt8] = [0x3C, 0x2F]
  closingTagLower.reserveCapacity(2 + tagLen)
  for k in tagNameStart ..< tagNameEnd {
    closingTagLower.append(toLowerASCII(bytes[k]))
  }

  var i = from
  while i < end {
    if bytes[i] == 0x3C {
      if i + closingTagLower.count < end
        && matchesCaseInsensitive(bytes, end, at: i, count: closingTagLower.count, pattern: closingTagLower)
      {
        let afterName = i + closingTagLower.count
        if afterName < end && (bytes[afterName] == 0x3E || isWSByte(bytes[afterName])) {
          // Emit text before end tag
          if i > from {
            if rawContentDepth > 0 {
              appendRawContentText(bytes, from, i, to: &output)
            } else {
              appendCollapsedText(bytes, from, i, to: &output)
            }
          }
          // Find closing >
          var closeAngle = afterName
          while closeAngle < end, bytes[closeAngle] != 0x3E {
            closeAngle += 1
          }
          guard closeAngle < end else {
            output.append(contentsOf: bytes[i ..< end])
            return end
          }
          // Emit end tag
          output.append(0x3C)
          output.append(0x2F)
          output.append(contentsOf: bytes[tagNameStart ..< tagNameEnd])
          output.append(0x3E)

          let tagHashLower = fnvHashLowered(bytes, tagNameStart, tagNameEnd)

          if rawContentElementHashes.contains(tagHashLower), rawContentDepth > 0 {
            rawContentDepth -= 1
          }

          return closeAngle + 1
        }
      }
    }
    i += 1
  }

  if i > from {
    if rawContentDepth > 0 {
      appendRawContentText(bytes, from, i, to: &output)
    } else {
      appendCollapsedText(bytes, from, i, to: &output)
    }
  }
  return end
}

// MARK: - Attribute lookup helpers

@inline(__always)
private func attrsContainHash(_ bytes: UnsafeBufferPointer<UInt8>, _ attrs: [RawAttr], _ hash: UInt64) -> Bool {
  for a in attrs {
    if fnvHashLowered(bytes, a.nameStart, a.nameEnd) == hash { return true }
  }
  return false
}

@inline(__always)
private func attrIndexByHash(_ bytes: UnsafeBufferPointer<UInt8>, _ attrs: [RawAttr], _ hash: UInt64) -> Int? {
  for i in 0 ..< attrs.count {
    if fnvHashLowered(bytes, attrs[i].nameStart, attrs[i].nameEnd) == hash { return i }
  }
  return nil
}

/// Compare two byte ranges for equality after lowercasing.
@inline(__always)
private func bytesEqualLowered(_ bytes: UnsafeBufferPointer<UInt8>, _ s1: Int, _ e1: Int, _ s2: Int, _ e2: Int) -> Bool {
  guard e1 - s1 == e2 - s2 else { return false }
  let len = e1 - s1
  for i in 0 ..< len {
    if toLowerASCII(bytes[s1 + i]) != toLowerASCII(bytes[s2 + i]) { return false }
  }
  return true
}

// MARK: - Text processing (byte-level)

/// Append text with smart whitespace collapsing based on surrounding tag context.
///
/// Uses inline/block element classification to decide whether to trim whitespace:
/// - Between block elements: whitespace removed entirely
/// - Between inline elements: whitespace collapsed to single space
/// - Inside block elements: leading/trailing whitespace trimmed
///
/// Also handles inline deduplication: when the previous tag is an inline text
/// element and the output already ends with whitespace, leading whitespace is
/// trimmed to prevent double-spacing across tag boundaries.
private func appendSmartText(
  _ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int,
  prevTag: UInt64, prevTagIsClosing: Bool,
  nextTag: UInt64, nextTagIsClosing: Bool,
  prevWasKeptComment: Bool,
  charsEndState: inout CharsEndState,
  hasChars: inout Bool,
  to output: inout [UInt8]
) {
  guard start < end else { return }

  // Compute trimLeft
  var trimLeft: Bool
  if prevWasKeptComment {
    // Kept comments act like inlineKeepWSAlways — never trim
    trimLeft = false
  } else if prevTag == 0 {
    trimLeft = true // No previous tag — trim (top of document)
  } else if inlineKeepWSAlwaysHashes.contains(prevTag) {
    trimLeft = false
  } else {
    if prevTagIsClosing {
      trimLeft = !inlineKeepWSAroundHashes.contains(prevTag)
    } else {
      trimLeft = !inlineKeepWSWithinHashes.contains(prevTag)
    }
  }

  // Compute trimRight
  var trimRight: Bool
  if nextTag == 0 {
    trimRight = true // No next tag — trim (end of document)
  } else if inlineKeepWSAlwaysHashes.contains(nextTag) {
    trimRight = false
  } else {
    if nextTagIsClosing {
      trimRight = !inlineKeepWSWithinHashes.contains(nextTag)
    } else {
      trimRight = !inlineKeepWSAroundHashes.contains(nextTag)
    }
  }

  // Inline deduplication: mirrors html-minifier-next's /(?:^|\s)$/.test(currentChars)
  // (line 1382-1384). Trim leading WS when charsEndState is .empty or .endsWithWS.
  var inlineDedup = false
  if !trimLeft, prevTag != 0 {
    let isInlineText = prevWasKeptComment || inlineKeepWSWithinHashes.contains(prevTag)
    if isInlineText, charsEndState == .empty || charsEndState == .endsWithWS {
      if start < end, isWSByte(bytes[start]) {
        inlineDedup = true
      }
    }
  }

  // Find content boundaries
  var s = start
  var e = end

  if trimLeft || inlineDedup {
    while s < e, isWSByte(bytes[s]) {
      s += 1
    }
  }
  if trimRight {
    while e > s, isWSByte(bytes[e - 1]) {
      e -= 1
    }
  }

  if s >= e {
    // Content is empty after trimming — check if we should emit a single space
    let shouldEmitSpace = !trimLeft && !trimRight && !inlineDedup
    if shouldEmitSpace {
      var hasWS = false
      for j in start ..< end {
        if isWSByte(bytes[j]) { hasWS = true; break }
      }
      if hasWS {
        output.append(0x20)
        charsEndState = .endsWithWS
        hasChars = true
      }
    }
  } else {
    collapseInternalWhitespace(bytes, s, e, to: &output)
    hasChars = true
    // Track if the emitted text ended with whitespace
    if !output.isEmpty, isWSByte(output[output.count - 1]) {
      charsEndState = .endsWithWS
    } else {
      charsEndState = .other
    }
  }
}

/// Simple fallback for malformed HTML — just collapse whitespace and trim.
/// Used in error-recovery paths where tag context is unavailable.
private func appendCollapsedText(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  guard start < end else { return }
  var s = start
  while s < end, isWSByte(bytes[s]) {
    s += 1
  }
  var e = end
  while e > s, isWSByte(bytes[e - 1]) {
    e -= 1
  }
  if s < e {
    collapseInternalWhitespace(bytes, s, e, to: &output)
  }
}

/// Append raw content text (script/style) with leading/trailing whitespace stripped entirely.
/// Internal whitespace is preserved exactly as-is.
/// Matches html-minifier-next's `trimWhitespace` behavior.
private func appendRawContentText(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  guard start < end else { return }

  var leadEnd = start
  while leadEnd < end, isWSByte(bytes[leadEnd]) {
    leadEnd += 1
  }

  var trailStart = end
  while trailStart > leadEnd, isWSByte(bytes[trailStart - 1]) {
    trailStart -= 1
  }

  // Entirely whitespace — emit nothing
  if leadEnd >= trailStart { return }

  // Emit middle content only — no leading/trailing WS
  output.append(contentsOf: bytes[leadEnd ..< trailStart])
}

/// Collapse all internal whitespace runs to a single space, appending directly to output.
private func collapseInternalWhitespace(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  var i = start
  while i < end {
    if isWSByte(bytes[i]) {
      output.append(0x20)
      i += 1
      while i < end, isWSByte(bytes[i]) {
        i += 1
      }
    } else {
      let runStart = i
      while i < end, !isWSByte(bytes[i]) {
        i += 1
      }
      output.append(contentsOf: bytes[runStart ..< i])
    }
  }
}

/// Append an attribute value with whitespace trimmed and collapsed.
/// Only ASCII whitespace (0x20, 0x0A, 0x0D, 0x09, 0x0C) is affected.
private func appendCollapsedAttributeValue(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  // Trim leading
  var s = start
  while s < end, isWSByte(bytes[s]) {
    s += 1
  }
  // Trim trailing
  var e = end
  while e > s, isWSByte(bytes[e - 1]) {
    e -= 1
  }

  // Check if collapsing is needed at all
  var needsCollapse = false
  var i = s
  while i < e {
    if isWSByte(bytes[i]) {
      if i > s, isWSByte(bytes[i - 1]) {
        needsCollapse = true
        break
      }
      // Single whitespace that isn't a space also needs collapse
      if bytes[i] != 0x20 {
        needsCollapse = true
        break
      }
    }
    i += 1
  }

  // Also check if trimming changed anything
  if !needsCollapse, s == start, e == end {
    output.append(contentsOf: bytes[start ..< end])
    return
  }

  // Collapse internal whitespace runs to single space
  i = s
  while i < e {
    if isWSByte(bytes[i]) {
      output.append(0x20)
      i += 1
      while i < e, isWSByte(bytes[i]) {
        i += 1
      }
    } else {
      let runStart = i
      while i < e, !isWSByte(bytes[i]) {
        i += 1
      }
      output.append(contentsOf: bytes[runStart ..< i])
    }
  }
}

// MARK: - String helpers (only used for rare conditional comment processing)

private func findSubstringInString(_ needle: String, in haystack: String) -> Range<String.Index>? {
  let needleChars = Array(needle)
  guard !needleChars.isEmpty else { return nil }
  var i = haystack.startIndex
  while i < haystack.endIndex {
    var j = i
    var k = 0
    while j < haystack.endIndex, k < needleChars.count, haystack[j] == needleChars[k] {
      j = haystack.index(after: j)
      k += 1
    }
    if k == needleChars.count {
      return i ..< j
    }
    i = haystack.index(after: i)
  }
  return nil
}
