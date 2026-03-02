public enum Bonsai {
  /// Minify an HTML string using conservative settings that match
  /// html-minifier-next's conservative preset.
  ///
  /// - Collapses whitespace runs to a single space (conservativeCollapse)
  /// - Preserves line breaks at text node boundaries (preserveLineBreaks)
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

    var i = 0

    while i < end {
      if bytes[i] == 0x3C { // <
        let afterLT = i + 1
        if afterLT >= end {
          appendConservativeText(bytes, i, end, to: &output)
          break
        }

        // Comment: <!-- ... -->
        if afterLT + 2 < end
          && bytes[afterLT] == 0x21
          && bytes[afterLT + 1] == 0x2D
          && bytes[afterLT + 2] == 0x2D
        {
          i = handleComment(bytes, end, i, &output)
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
              appendConservativeText(bytes, i, end, to: &output)
              i = end
            }
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
              appendConservativeText(bytes, contentStart, pos, to: &output)
            }
            i = pos + 3
          } else {
            if preserveDepth > 0 {
              output.append(contentsOf: bytes[contentStart ..< end])
            } else if rawContentDepth > 0 {
              appendRawContentText(bytes, contentStart, end, to: &output)
            } else {
              appendConservativeText(bytes, contentStart, end, to: &output)
            }
            i = end
          }
          continue
        }

        // End tag: </...>
        if bytes[afterLT] == 0x2F {
          i = handleEndTag(bytes, end, i, &output, &preserveDepth, &rawContentDepth, &foreignContentDepth)
          continue
        }

        // Start tag: letter or _
        if isASCIILetter(bytes[afterLT]) || bytes[afterLT] == 0x5F {
          i = handleStartTag(bytes, end, i, &output, &attrs,
                             &preserveDepth, &rawContentDepth, &foreignContentDepth)
          continue
        }

        // Not a recognized tag — emit as text
        if preserveDepth > 0 {
          output.append(contentsOf: bytes[i ..< afterLT])
        } else if rawContentDepth > 0 {
          appendRawContentText(bytes, i, afterLT, to: &output)
        } else {
          appendConservativeText(bytes, i, afterLT, to: &output)
        }
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
          appendConservativeText(bytes, start, i, to: &output)
        }
      }
    }

    return String(decoding: output, as: UTF8.self)
  }
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
    appendConservativeText(bytes, start, end, to: &output)
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
    appendConservativeText(bytes, start, end, to: &output)
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
              appendConservativeText(bytes, from, i, to: &output)
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
      appendConservativeText(bytes, from, i, to: &output)
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

/// Append text with conservative whitespace collapsing and preserveLineBreaks.
///
/// preserveLineBreaks: newlines are only preserved at the START and END of text
/// nodes (adjacent to tags). Internal newlines collapse to space.
///
/// Algorithm:
/// 1. Extract leading whitespace: if contains newline → save `\n`, strip
/// 2. Extract trailing whitespace: if contains newline → save `\n`, strip
/// 3. Remaining leading whitespace (no newline) → collapse to ` `
/// 4. Remaining trailing whitespace (no newline) → collapse to ` `
/// 5. Collapse all internal whitespace runs to single space
/// 6. Prepend/append saved newlines
private func appendConservativeText(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  guard start < end else { return }

  // Find leading whitespace end
  var leadEnd = start
  while leadEnd < end, isWSByte(bytes[leadEnd]) {
    leadEnd += 1
  }

  // Find trailing whitespace start
  var trailStart = end
  while trailStart > start, isWSByte(bytes[trailStart - 1]) {
    trailStart -= 1
  }

  var lineBreakBefore = false
  var lineBreakAfter = false
  var contentStart = start
  var contentEnd = end

  // Step 1: Leading WS with newline → save newline, strip
  if leadEnd > start, containsNewlineInBytes(bytes, start, leadEnd) {
    lineBreakBefore = true
    contentStart = leadEnd
  }

  // Step 2: Trailing WS with newline → save newline, strip
  if trailStart < end, trailStart > contentStart,
     containsNewlineInBytes(bytes, trailStart, end)
  {
    lineBreakAfter = true
    contentEnd = trailStart
  }

  // Step 3: Collapse remaining leading WS to single space
  var innerStart = contentStart
  var prependSpace = false
  if !lineBreakBefore {
    var ws = innerStart
    while ws < contentEnd, isWSByte(bytes[ws]) {
      ws += 1
    }
    if ws > innerStart {
      prependSpace = true
      innerStart = ws
    }
  }

  // Step 4: Collapse remaining trailing WS to single space
  var innerEnd = contentEnd
  var appendSpace = false
  if !lineBreakAfter {
    var ws = innerEnd
    while ws > innerStart, isWSByte(bytes[ws - 1]) {
      ws -= 1
    }
    if ws < innerEnd {
      appendSpace = true
      innerEnd = ws
    }
  }

  // Steps 5+6: Collapse internal WS and assemble
  if innerStart >= innerEnd {
    // Content is empty after stripping
    if lineBreakBefore {
      output.append(0x0A)
    } else if lineBreakAfter {
      output.append(0x0A)
    } else {
      // Whitespace-only with no newlines → conservativeCollapse → single space
      var allWS = true
      for i in start ..< end {
        if !isWSByte(bytes[i]) { allWS = false; break }
      }
      if allWS { output.append(0x20) }
    }
  } else {
    if lineBreakBefore { output.append(0x0A) }
    if prependSpace { output.append(0x20) }
    collapseInternalWhitespace(bytes, innerStart, innerEnd, to: &output)
    if appendSpace { output.append(0x20) }
    if lineBreakAfter { output.append(0x0A) }
  }
}

/// Append raw content text (script/style) with only leading/trailing whitespace trimming.
/// Internal whitespace is preserved exactly as-is.
private func appendRawContentText(_ bytes: UnsafeBufferPointer<UInt8>, _ start: Int, _ end: Int, to output: inout [UInt8]) {
  guard start < end else { return }

  var leadEnd = start
  while leadEnd < end, isWSByte(bytes[leadEnd]) {
    leadEnd += 1
  }

  var trailStart = end
  while trailStart > start, isWSByte(bytes[trailStart - 1]) {
    trailStart -= 1
  }

  // Entirely whitespace
  if leadEnd >= trailStart {
    if containsNewlineInBytes(bytes, start, end) {
      output.append(0x0A)
    } else {
      output.append(0x20)
    }
    return
  }

  // Leading whitespace
  if leadEnd > start {
    if containsNewlineInBytes(bytes, start, leadEnd) {
      output.append(0x0A)
    } else {
      output.append(0x20)
    }
  }

  // Middle content — preserved as-is
  output.append(contentsOf: bytes[leadEnd ..< trailStart])

  // Trailing whitespace
  if trailStart < end {
    if containsNewlineInBytes(bytes, trailStart, end) {
      output.append(0x0A)
    } else {
      output.append(0x20)
    }
  }
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
