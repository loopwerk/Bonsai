@testable import Bonsai
import XCTest

/// Tests ported from html-minifier-next's test suite, run with:
/// { caseSensitive: true, collapseBooleanAttributes: true, collapseWhitespace: true,
///   removeComments: true, removeScriptTypeAttributes: true,
///   removeStyleLinkTypeAttributes: true, useShortDoctype: true }
final class BonsaiTests: XCTestCase {
  // ============================================================================
  // MARK: - Space normalization around text

  // html-minifier-next: "Space normalization around text" (lines 209-376)
  // ============================================================================

  func testSpaceNormLeadingTrailingNewlines() {
    // Line 214: collapseWhitespace: true
    XCTAssertEqual(
      Bonsai.minifyHTML("   <p>blah</p>\n\n\n   "),
      "<p>blah</p>"
    )
  }

  func testInlineElementsPreserveSpaces() {
    // Lines 226-233: collapseWhitespace: true, 8 variants per element
    let inlines = [
      "a", "abbr", "acronym", "b", "big", "del", "em", "font", "i", "ins", "kbd",
      "mark", "s", "samp", "small", "span", "strike", "strong", "sub", "sup",
      "time", "tt", "u", "var",
    ]
    for el in inlines {
      // Line 226: foo <el>baz</el> bar -> foo <el>baz</el> bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)> bar"),
        "foo <\(el)>baz</\(el)> bar",
        "\(el): spaces around"
      )
      // Line 227: foo<el>baz</el>bar -> foo<el>baz</el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)>bar"),
        "foo<\(el)>baz</\(el)>bar",
        "\(el): no spaces"
      )
      // Line 228: foo <el>baz</el>bar -> foo <el>baz</el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)>bar"),
        "foo <\(el)>baz</\(el)>bar",
        "\(el): leading space"
      )
      // Line 229: foo<el>baz</el> bar -> foo<el>baz</el> bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)> bar"),
        "foo<\(el)>baz</\(el)> bar",
        "\(el): trailing space"
      )
      // Line 230: foo <el> baz </el> bar -> foo <el>baz </el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)> baz </\(el)> bar"),
        "foo <\(el)>baz </\(el)>bar",
        "\(el): inner spaces, spaces around"
      )
      // Line 231: foo<el> baz </el>bar -> foo<el> baz </el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)> baz </\(el)>bar"),
        "foo<\(el)> baz </\(el)>bar",
        "\(el): inner spaces, no outer spaces"
      )
      // Line 232: foo <el> baz </el>bar -> foo <el>baz </el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)> baz </\(el)>bar"),
        "foo <\(el)>baz </\(el)>bar",
        "\(el): inner spaces, leading outer space"
      )
      // Line 233: foo<el> baz </el> bar -> foo<el> baz </el>bar
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)> baz </\(el)> bar"),
        "foo<\(el)> baz </\(el)>bar",
        "\(el): inner spaces, trailing outer space"
      )
    }
  }

  func testInlineElementsInsideDiv() {
    // Lines 234-241: inside <div>, collapseWhitespace: true, 8 variants per element
    let inlines = [
      "a", "abbr", "acronym", "b", "big", "del", "em", "font", "i", "ins", "kbd",
      "mark", "s", "samp", "small", "span", "strike", "strong", "sub", "sup",
      "time", "tt", "u", "var",
    ]
    for el in inlines {
      // Line 234
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)> bar</div>"),
        "<div>foo <\(el)>baz</\(el)> bar</div>",
        "\(el) in div: spaces"
      )
      // Line 235
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)>bar</div>"),
        "<div>foo<\(el)>baz</\(el)>bar</div>",
        "\(el) in div: no spaces"
      )
      // Line 236
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)>bar</div>"),
        "<div>foo <\(el)>baz</\(el)>bar</div>",
        "\(el) in div: leading space"
      )
      // Line 237
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)> bar</div>"),
        "<div>foo<\(el)>baz</\(el)> bar</div>",
        "\(el) in div: trailing space"
      )
      // Line 238
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)> baz </\(el)> bar</div>"),
        "<div>foo <\(el)>baz </\(el)>bar</div>",
        "\(el) in div: inner spaces, spaces around"
      )
      // Line 239
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)> baz </\(el)>bar</div>"),
        "<div>foo<\(el)> baz </\(el)>bar</div>",
        "\(el) in div: inner spaces, no outer spaces"
      )
      // Line 240
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)> baz </\(el)>bar</div>"),
        "<div>foo <\(el)>baz </\(el)>bar</div>",
        "\(el) in div: inner spaces, leading outer space"
      )
      // Line 241
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)> baz </\(el)> bar</div>"),
        "<div>foo<\(el)> baz </\(el)>bar</div>",
        "\(el) in div: inner spaces, trailing outer space"
      )
    }
  }

  func testNonTrimmingInlineElements() {
    // Lines 244-263: bdi, bdo, button, cite, code, dfn, math, q, rt, rtc, ruby, svg
    // These preserve whitespace around but trim within
    let elements = [
      "bdi", "bdo", "button", "cite", "code", "dfn", "math", "q", "rt", "rtc", "ruby", "svg",
    ]
    for el in elements {
      // Line 247
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)> bar"),
        "foo <\(el)>baz</\(el)> bar",
        "\(el): spaces around"
      )
      // Line 248
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)>bar"),
        "foo<\(el)>baz</\(el)>bar",
        "\(el): no spaces"
      )
      // Line 249
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)>bar"),
        "foo <\(el)>baz</\(el)>bar",
        "\(el): leading space"
      )
      // Line 250
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)> bar"),
        "foo<\(el)>baz</\(el)> bar",
        "\(el): trailing space"
      )
      // Line 251
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)> baz </\(el)> bar"),
        "foo <\(el)>baz</\(el)> bar",
        "\(el): inner spaces, spaces around"
      )
      // Line 252
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)> baz </\(el)>bar"),
        "foo<\(el)>baz</\(el)>bar",
        "\(el): inner spaces, no outer spaces"
      )
      // Line 253
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)> baz </\(el)>bar"),
        "foo <\(el)>baz</\(el)>bar",
        "\(el): inner spaces, leading outer space"
      )
      // Line 254
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)> baz </\(el)> bar"),
        "foo<\(el)>baz</\(el)> bar",
        "\(el): inner spaces, trailing outer space"
      )
      // Line 255
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)> bar</div>"),
        "<div>foo <\(el)>baz</\(el)> bar</div>",
        "\(el) in div: spaces"
      )
      // Line 256
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)>bar</div>"),
        "<div>foo<\(el)>baz</\(el)>bar</div>",
        "\(el) in div: no spaces"
      )
      // Line 257
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)>bar</div>"),
        "<div>foo <\(el)>baz</\(el)>bar</div>",
        "\(el) in div: leading space"
      )
      // Line 258
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)> bar</div>"),
        "<div>foo<\(el)>baz</\(el)> bar</div>",
        "\(el) in div: trailing space"
      )
      // Line 259
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)> baz </\(el)> bar</div>"),
        "<div>foo <\(el)>baz</\(el)> bar</div>",
        "\(el) in div: inner spaces, spaces around"
      )
      // Line 260
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)> baz </\(el)>bar</div>"),
        "<div>foo<\(el)>baz</\(el)>bar</div>",
        "\(el) in div: inner spaces, no outer spaces"
      )
      // Line 261
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)> baz </\(el)>bar</div>"),
        "<div>foo <\(el)>baz</\(el)>bar</div>",
        "\(el) in div: inner spaces, leading outer space"
      )
      // Line 262
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)> baz </\(el)> bar</div>"),
        "<div>foo<\(el)>baz</\(el)> bar</div>",
        "\(el) in div: inner spaces, trailing outer space"
      )
    }
  }

  func testNobrSpacePermutations() {
    // Lines 264-296: nobr space permutations with collapseWhitespace: true
    let cases: [(String, String)] = [
      ("<nobr>a</nobr>", "<nobr>a</nobr>"),
      ("<nobr>a </nobr>", "<nobr>a</nobr>"),
      ("<nobr> a</nobr>", "<nobr>a</nobr>"),
      ("<nobr> a </nobr>", "<nobr>a</nobr>"),
      ("a<nobr>b</nobr>c", "a<nobr>b</nobr>c"),
      ("a<nobr>b </nobr>c", "a<nobr>b </nobr>c"),
      ("a<nobr> b</nobr>c", "a<nobr> b</nobr>c"),
      ("a<nobr> b </nobr>c", "a<nobr> b </nobr>c"),
      ("a<nobr>b</nobr> c", "a<nobr>b</nobr> c"),
      ("a<nobr>b </nobr> c", "a<nobr>b</nobr> c"),
      ("a<nobr> b</nobr> c", "a<nobr> b</nobr> c"),
      ("a<nobr> b </nobr> c", "a<nobr> b</nobr> c"),
      ("a <nobr>b</nobr>c", "a <nobr>b</nobr>c"),
      ("a <nobr>b </nobr>c", "a <nobr>b </nobr>c"),
      ("a <nobr> b</nobr>c", "a <nobr>b</nobr>c"),
      ("a <nobr> b </nobr>c", "a <nobr>b </nobr>c"),
      ("a <nobr>b</nobr> c", "a <nobr>b</nobr> c"),
      ("a <nobr>b </nobr> c", "a <nobr>b</nobr> c"),
      ("a <nobr> b</nobr> c", "a <nobr>b</nobr> c"),
      ("a <nobr> b </nobr> c", "a <nobr>b</nobr> c"),
    ]
    for (input, expected) in cases {
      XCTAssertEqual(Bonsai.minifyHTML(input), expected, input)
    }
    // Also inside <div>
    for (input, expected) in cases {
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>\(input)</div>"),
        "<div>\(expected)</div>",
        "<div>\(input)</div>"
      )
    }
  }

  func testImgSpacePreservation() {
    // Lines 298-301
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <img> bar</p>"), "<p>foo <img> bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<img>bar</p>"), "<p>foo<img>bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <img>bar</p>"), "<p>foo <img>bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<img> bar</p>"), "<p>foo<img> bar</p>")
  }

  func testWbrSpaceHandling() {
    // Lines 302-309
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <wbr> bar</p>"), "<p>foo<wbr> bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<wbr>bar</p>"), "<p>foo<wbr>bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <wbr>bar</p>"), "<p>foo <wbr>bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<wbr> bar</p>"), "<p>foo<wbr> bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <wbr baz moo=\"\"> bar</p>"), "<p>foo<wbr baz moo=\"\"> bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<wbr baz moo=\"\">bar</p>"), "<p>foo<wbr baz moo=\"\">bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo <wbr baz moo=\"\">bar</p>"), "<p>foo <wbr baz moo=\"\">bar</p>")
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo<wbr baz moo=\"\"> bar</p>"), "<p>foo<wbr baz moo=\"\"> bar</p>")
  }

  func testNestedInlineElements() {
    // Lines 310-312
    XCTAssertEqual(
      Bonsai.minifyHTML("<p>  <a href=\"#\">  <code>foo</code></a> bar</p>"),
      "<p><a href=\"#\"><code>foo</code></a> bar</p>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<p><a href=\"#\"><code>foo  </code></a> bar</p>"),
      "<p><a href=\"#\"><code>foo</code></a> bar</p>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<p>  <a href=\"#\">  <code>   foo</code></a> bar   </p>"),
      "<p><a href=\"#\"><code>foo</code></a> bar</p>"
    )
  }

  func testCommentWhitespace() {
    // Line 313: collapseWhitespace only (no removeComments) — but Bonsai always removes comments
    // With removeComments, comments are removed, affecting whitespace
    // Line 314-317: collapseWhitespace + removeComments
    XCTAssertEqual(
      Bonsai.minifyHTML("<div> a <input><!-- b --> c </div>"),
      "<div>a <input> c</div>"
    )
  }

  func testProcessingInstructionPreserved() {
    // Lines 318-335: with collapseWhitespace + removeComments
    // Most PI variants produce: 'a<? b ?> c'
    // But when comment is between ?> and text, the space is lost
    let piCases: [(String, String)] = [
      (" a <? b ?> c ", "a<? b ?> c"),
      ("<!-- d --> a <? b ?> c ", "a<? b ?> c"),
      (" <!-- d -->a <? b ?> c ", "a<? b ?> c"),
      (" a<!-- d --> <? b ?> c ", "a<? b ?> c"),
      (" a <!-- d --><? b ?> c ", "a<? b ?> c"),
      (" a <? b ?><!-- d --> c ", "a<? b ?>c"),
      (" a <? b ?> <!-- d -->c ", "a<? b ?>c"),
      (" a <? b ?> c<!-- d --> ", "a<? b ?> c"),
      (" a <? b ?> c <!-- d -->", "a<? b ?> c"),
    ]
    for (input, expected) in piCases {
      XCTAssertEqual(Bonsai.minifyHTML(input), expected, input)
    }
    // Also inside <p>
    let piPCases: [(String, String)] = [
      ("<p> a <? b ?> c </p>", "<p>a<? b ?> c</p>"),
      ("<p><!-- d --> a <? b ?> c </p>", "<p>a<? b ?> c</p>"),
      ("<p> <!-- d -->a <? b ?> c </p>", "<p>a<? b ?> c</p>"),
      ("<p> a<!-- d --> <? b ?> c </p>", "<p>a<? b ?> c</p>"),
      ("<p> a <!-- d --><? b ?> c </p>", "<p>a<? b ?> c</p>"),
      ("<p> a <? b ?><!-- d --> c </p>", "<p>a<? b ?>c</p>"),
      ("<p> a <? b ?> <!-- d -->c </p>", "<p>a<? b ?>c</p>"),
      ("<p> a <? b ?> c<!-- d --> </p>", "<p>a<? b ?> c</p>"),
      ("<p> a <? b ?> c <!-- d --></p>", "<p>a<? b ?> c</p>"),
    ]
    for (input, expected) in piPCases {
      XCTAssertEqual(Bonsai.minifyHTML(input), expected, input)
    }
  }

  func testEmptyInlineElementSpaces() {
    // Lines 337-347
    XCTAssertEqual(
      Bonsai.minifyHTML("<li><i></i> <b></b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<li><i> </i> <b></b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<li> <i></i> <b></b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<li><i></i> <b> </b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<li> <i> </i> <b> </b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
  }

  func testNestedInlineDeep() {
    // Lines 348-350
    XCTAssertEqual(
      Bonsai.minifyHTML("<div> <a href=\"#\"> <span> <b> foo </b> <i> bar </i> </span> </a> </div>"),
      "<div><a href=\"#\"><span><b>foo </b><i>bar</i></span></a></div>"
    )
  }

  func testHeadCommentWhitespace() {
    // Lines 351-356: collapseWhitespace only (no removeComments)
    // But Bonsai always removes comments, so expected differs
    XCTAssertEqual(
      Bonsai.minifyHTML("<head> <!-- a --> <!-- b --><link> </head>"),
      "<head><link></head>"
    )
    XCTAssertEqual(
      Bonsai.minifyHTML("<head> <!-- a --> <!-- b --> <!-- c --><link> </head>"),
      "<head><link></head>"
    )
  }

  func testNbspInTextCollapse() {
    // Line 357-359
    XCTAssertEqual(
      Bonsai.minifyHTML("<p> foo\u{00A0}bar\nbaz  \u{00A0}\nmoo\t</p>"),
      "<p>foo\u{00A0}bar baz \u{00A0} moo</p>"
    )
  }

  func testLabelInputObjectSelectTextarea() {
    // Lines 360-366
    let input = "<label> foo </label>\n" +
      "<input>\n" +
      "<object> bar </object>\n" +
      "<select> baz </select>\n" +
      "<textarea> moo </textarea>\n"
    let expected = "<label>foo</label> <input> <object>bar</object> <select>baz</select> <textarea> moo </textarea>"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  func testPreWithTrailingText() {
    // Lines 367-375
    let input = "<pre>\n" +
      "foo\n" +
      "<br>\n" +
      "bar\n" +
      "</pre>\n" +
      "baz\n"
    let expected = "<pre>\nfoo\n<br>\nbar\n</pre>baz"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  // ============================================================================
  // MARK: - Collapse whitespace

  // html-minifier-next: "Collapse whitespace" (lines 1550-1620)
  // ============================================================================

  func testCollapseScriptContent() {
    // Line 1553-1555: script content trimmed, type removed
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/javascript\">  \n\t   alert(1) \n\n\n  \t </script>"),
      "<script>alert(1)</script>"
    )
  }

  func testCollapseMultipleBlocks() {
    // Line 1557-1559
    XCTAssertEqual(
      Bonsai.minifyHTML("<p>foo</p>    <p> bar</p>\n\n   \n\t\t  <div title=\"quz\">baz  </div>"),
      "<p>foo</p><p>bar</p><div title=\"quz\">baz</div>"
    )
  }

  func testCollapseLeadingSpace() {
    // Line 1561-1563
    XCTAssertEqual(Bonsai.minifyHTML("<p> foo    bar</p>"), "<p>foo bar</p>")
  }

  func testCollapseNewlineToSpace() {
    // Line 1565-1567
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo\nbar</p>"), "<p>foo bar</p>")
  }

  func testCollapseInlineElementSpaces() {
    // Line 1569-1571
    XCTAssertEqual(
      Bonsai.minifyHTML("<p> foo    <span>  blah     <i>   22</i>    </span> bar <img src=\"\"></p>"),
      "<p>foo <span>blah <i>22</i> </span>bar <img src=\"\"></p>"
    )
  }

  func testTextareaPreserved() {
    // Line 1573-1575
    XCTAssertEqual(
      Bonsai.minifyHTML("<textarea> foo bar     baz \n\n   x \t    y </textarea>"),
      "<textarea> foo bar     baz \n\n   x \t    y </textarea>"
    )
  }

  func testTextareaFollowedByWhitespace() {
    // Line 1577-1579
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><textarea></textarea>    </div>"),
      "<div><textarea></textarea></div>"
    )
  }

  func testCaseSensitivePreElement() {
    // Line 1584-1585: caseSensitive means <pRe> is NOT recognized as pre
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><pRe> $foo = \"baz\"; </pRe>    </div>"),
      "<div><pRe>$foo = \"baz\";</pRe></div>"
    )
  }

  func testPrePreservesWhitespace() {
    // Lines 1605-1607
    XCTAssertEqual(
      Bonsai.minifyHTML("<pre title=\"some title\">   hello     world </pre>"),
      "<pre title=\"some title\">   hello     world </pre>"
    )
  }

  func testPreCodePreservesWhitespace() {
    // Lines 1609-1611
    XCTAssertEqual(
      Bonsai.minifyHTML("<pre title=\"some title\"><code>   hello     world </code></pre>"),
      "<pre title=\"some title\"><code>   hello     world </code></pre>"
    )
  }

  func testScriptPreservesInternalWhitespace() {
    // Lines 1613-1615: script content — only trailing trimmed, internal preserved
    XCTAssertEqual(
      Bonsai.minifyHTML("<script>alert(\"foo     bar\")    </script>"),
      "<script>alert(\"foo     bar\")</script>"
    )
  }

  func testStylePreservesInternalWhitespace() {
    // Lines 1617-1619
    XCTAssertEqual(
      Bonsai.minifyHTML("<style>alert(\"foo     bar\")    </style>"),
      "<style>alert(\"foo     bar\")</style>"
    )
  }

  func testBigDocumentIntegration() {
    // Lines 1587-1603: major integration test
    // Adjusted for Bonsai features: removeComments, removeScriptTypeAttributes,
    // removeStyleLinkTypeAttributes, collapseBooleanAttributes
    let input = "<script type=\"text/javascript\">var = \"hello\";</script>\r\n\r\n\r\n" +
      "<style type=\"text/css\">#foo { color: red;        }          </style>\r\n\r\n\r\n" +
      "<div>\r\n  <div>\r\n    <div><!-- hello -->\r\n      <div>" +
      "<!--! hello -->\r\n        <div>\r\n          <div class=\"\">\r\n\r\n            " +
      "<textarea disabled=\"disabled\">     this is a textarea </textarea>\r\n          " +
      "</div>\r\n        </div>\r\n      </div>\r\n    </div>\r\n  </div>\r\n</div>" +
      "<pre>       \r\nxxxx</pre><span>x</span> <span>Hello</span> <b>billy</b>     \r\n" +
      "<input type=\"text\">\r\n<textarea></textarea>\r\n<pre></pre>"
    let expected = "<script>var = \"hello\";</script>" +
      "<style>#foo { color: red;        }</style>" +
      "<div><div><div>" +
      "<div><!--! hello --><div><div>" +
      "<textarea disabled>     this is a textarea </textarea>" +
      "</div></div></div></div></div></div>" +
      "<pre>       \r\nxxxx</pre><span>x</span> <span>Hello</span> <b>billy</b> " +
      "<input> <textarea></textarea><pre></pre>"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  // ============================================================================
  // MARK: - Doctype normalization

  // html-minifier-next: "Doctype normalization" (lines 415-435)
  // ============================================================================

  func testDoctypeShortened() {
    // Line 421
    XCTAssertEqual(Bonsai.minifyHTML("<!DOCTYPE html>"), "<!doctype html>")
  }

  func testDoctypeNewline() {
    // Line 427
    XCTAssertEqual(Bonsai.minifyHTML("<!DOCTYPE\nhtml>"), "<!doctype html>")
  }

  func testDoctypeTab() {
    // Line 431
    XCTAssertEqual(Bonsai.minifyHTML("<!DOCTYPE\thtml>"), "<!doctype html>")
  }

  func testDoctypeFullPublic() {
    // Line 435
    XCTAssertEqual(
      Bonsai.minifyHTML("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\"\n    \"http://www.w3.org/TR/html4/strict.dtd\">"),
      "<!doctype html>"
    )
  }

  // ============================================================================
  // MARK: - Remove comments

  // html-minifier-next: "Remove comments" (lines 438-456)
  // ============================================================================

  func testRemoveComment() {
    // Line 442
    XCTAssertEqual(Bonsai.minifyHTML("<!-- test -->"), "")
  }

  func testRemoveMultipleComments() {
    // Line 445
    XCTAssertEqual(
      Bonsai.minifyHTML("<!-- foo --><div>baz</div><!-- bar\n\n moo -->"),
      "<div>baz</div>"
    )
  }

  func testCommentInAttributePreserved() {
    // Line 449
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title=\"<!-- comment in attribute -->\">foo</p>"),
      "<p title=\"<!-- comment in attribute -->\">foo</p>"
    )
  }

  func testCommentInsideScriptPreserved() {
    // Line 452
    XCTAssertEqual(
      Bonsai.minifyHTML("<script><!-- alert(1) --></script>"),
      "<script><!-- alert(1) --></script>"
    )
  }

  func testCommentInsideStylePreserved() {
    // Line 455: caseSensitive preserves STYLE case
    XCTAssertEqual(
      Bonsai.minifyHTML("<STYLE><!-- alert(1) --></STYLE>"),
      "<STYLE><!-- alert(1) --></STYLE>"
    )
  }

  // ============================================================================
  // MARK: - Ignore comments (bang comments)

  // html-minifier-next: "Ignore comments" (lines 458-485)
  // ============================================================================

  func testBangCommentPreserved() {
    // Line 462
    XCTAssertEqual(Bonsai.minifyHTML("<!--! test -->"), "<!--! test -->")
  }

  func testBangCommentsPreserved() {
    // Line 466
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--! foo --><div>baz</div><!--! bar\n\n moo -->"),
      "<!--! foo --><div>baz</div><!--! bar\n\n moo -->"
    )
  }

  func testBangCommentMixedWithRegular() {
    // Line 470
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--! foo --><div>baz</div><!-- bar\n\n moo -->"),
      "<!--! foo --><div>baz</div>"
    )
  }

  func testSpaceBangIsRegularComment() {
    // Line 474: space before bang = not a bang comment
    XCTAssertEqual(Bonsai.minifyHTML("<!-- ! test -->"), "")
  }

  func testBangCommentInAttributePreserved() {
    // Line 485
    XCTAssertEqual(
      Bonsai.minifyHTML("<p rel=\"<!-- comment in attribute -->\" title=\"<!--! ignored comment in attribute -->\">foo</p>"),
      "<p rel=\"<!-- comment in attribute -->\" title=\"<!--! ignored comment in attribute -->\">foo</p>"
    )
  }

  // ============================================================================
  // MARK: - Conditional comments

  // html-minifier-next: "Conditional comments" (lines 488-557)
  // ============================================================================

  func testDownlevelHiddenConditional() {
    // Line 492
    XCTAssertEqual(
      Bonsai.minifyHTML("<![if IE 5]>test<![endif]>"),
      "<![if IE 5]>test<![endif]>"
    )
  }

  func testConditionalIE6() {
    // Line 495
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if IE 6]>test<![endif]-->"),
      "<!--[if IE 6]>test<![endif]-->"
    )
  }

  func testConditionalIE7Revealed() {
    // Line 498
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if IE 7]>-->test<!--<![endif]-->"),
      "<!--[if IE 7]>-->test<!--<![endif]-->"
    )
  }

  func testConditionalIE8Revealed() {
    // Line 501
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if IE 8]><!-->test<!--<![endif]-->"),
      "<!--[if IE 8]><!-->test<!--<![endif]-->"
    )
  }

  func testConditionalLtIE() {
    // Line 504
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if lt IE 5.5]>test<![endif]-->"),
      "<!--[if lt IE 5.5]>test<![endif]-->"
    )
  }

  func testConditionalComplex() {
    // Line 507
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if (gt IE 5)&(lt IE 7)]>test<![endif]-->"),
      "<!--[if (gt IE 5)&(lt IE 7)]>test<![endif]-->"
    )
  }

  func testDownlevelRevealedConditional() {
    // Line 560-562
    XCTAssertEqual(
      Bonsai.minifyHTML("<![if !IE]><link href=\"non-ie.css\" rel=\"stylesheet\"><![endif]>"),
      "<![if !IE]><link href=\"non-ie.css\" rel=\"stylesheet\"><![endif]>"
    )
  }

  // ============================================================================
  // MARK: - Collapse space in conditional comments

  // html-minifier-next: "Collapse space in conditional comments" (lines 565-591)
  // ============================================================================

  func testConditionalCommentCollapseWhitespace() {
    // Lines 568-580: processConditionalComments minifies inner content
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if IE 7]>\n\n   \t\n   \t\t <link rel=\"stylesheet\" href=\"/css/ie7-fixes.css\" type=\"text/css\" />\n\t<![endif]-->"),
      "<!--[if IE 7]><link rel=\"stylesheet\" href=\"/css/ie7-fixes.css\"><![endif]-->"
    )
  }

  func testConditionalCommentCollapseParagraph() {
    // Lines 582-590
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if lte IE 6]>\n    \n   \n\n\n\t<p title=\" sigificant     whitespace   \">blah blah</p><![endif]-->"),
      "<!--[if lte IE 6]><p title=\"sigificant whitespace\">blah blah</p><![endif]-->"
    )
  }

  // ============================================================================
  // MARK: - Collapse boolean attributes

  // html-minifier-next: "Collapse boolean attributes" (lines 1882-1918)
  // ============================================================================

  func testCollapseBooleanDisabled() {
    // Line 1886
    XCTAssertEqual(Bonsai.minifyHTML("<input disabled=\"disabled\">"), "<input disabled>")
  }

  func testCollapseBooleanCheckedReadonly() {
    // Line 1889: caseSensitive preserves CHECKED case
    XCTAssertEqual(
      Bonsai.minifyHTML("<input CHECKED = \"checked\" readonly=\"readonly\">"),
      "<input CHECKED readonly>"
    )
  }

  func testCollapseBooleanSelected() {
    // Line 1892
    XCTAssertEqual(
      Bonsai.minifyHTML("<option name=\"blah\" selected=\"selected\">moo</option>"),
      "<option name=\"blah\" selected>moo</option>"
    )
  }

  func testCollapseBooleanAutofocus() {
    // Line 1895
    XCTAssertEqual(Bonsai.minifyHTML("<input autofocus=\"autofocus\">"), "<input autofocus>")
  }

  func testCollapseBooleanRequired() {
    // Line 1898
    XCTAssertEqual(Bonsai.minifyHTML("<input required=\"required\">"), "<input required>")
  }

  func testCollapseBooleanMultiple() {
    // Line 1901
    XCTAssertEqual(Bonsai.minifyHTML("<input multiple=\"multiple\">"), "<input multiple>")
  }

  func testCollapseBooleanExhaustiveList() {
    // Lines 1903-1918: caseSensitive preserves attribute name case
    let input = "<div Allowfullscreen=foo Async=foo Autofocus=foo Autoplay=foo Checked=foo Compact=foo Controls=foo " +
      "Declare=foo Default=foo Defaultchecked=foo Defaultmuted=foo Defaultselected=foo Defer=foo Disabled=foo " +
      "Enabled=foo Formnovalidate=foo Hidden=foo Indeterminate=foo Inert=foo Ismap=foo Itemscope=foo " +
      "Loop=foo Multiple=foo Muted=foo Nohref=foo Noresize=foo Noshade=foo Novalidate=foo Nowrap=foo Open=foo " +
      "Pauseonexit=foo Readonly=foo Required=foo Reversed=foo Scoped=foo Seamless=foo Selected=foo Sortable=foo " +
      "Truespeed=foo Typemustmatch=foo Visible=foo></div>"
    let expected = "<div Allowfullscreen Async Autofocus Autoplay Checked Compact Controls Declare Default Defaultchecked " +
      "Defaultmuted Defaultselected Defer Disabled Enabled Formnovalidate Hidden Indeterminate Inert " +
      "Ismap Itemscope Loop Multiple Muted Nohref Noresize Noshade Novalidate Nowrap Open Pauseonexit Readonly " +
      "Required Reversed Scoped Seamless Selected Sortable Truespeed Typemustmatch Visible></div>"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  // ============================================================================
  // MARK: - Collapse enumerated attributes

  // html-minifier-next: "Collapse enumerated attributes" (lines 1921-1940)
  // ============================================================================

  func testDraggableAuto() {
    // Line 1922
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable=\"auto\"></div>"), "<div draggable></div>")
  }

  func testDraggableTrue() {
    // Line 1923
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable=\"true\"></div>"), "<div draggable=\"true\"></div>")
  }

  func testDraggableFalse() {
    // Line 1924
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable=\"false\"></div>"), "<div draggable=\"false\"></div>")
  }

  func testDraggableFoo() {
    // Line 1925
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable=\"foo\"></div>"), "<div draggable></div>")
  }

  func testDraggableBare() {
    // Line 1926
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable></div>"), "<div draggable></div>")
  }

  func testDraggableCaseSensitiveAuto() {
    // Line 1927: caseSensitive preserves Draggable case
    XCTAssertEqual(Bonsai.minifyHTML("<div Draggable=\"auto\"></div>"), "<div Draggable></div>")
  }

  func testDraggableCaseSensitiveTrue() {
    // Line 1928
    XCTAssertEqual(Bonsai.minifyHTML("<div Draggable=\"true\"></div>"), "<div Draggable=\"true\"></div>")
  }

  func testDraggableCaseSensitiveFalse() {
    // Line 1929
    XCTAssertEqual(Bonsai.minifyHTML("<div Draggable=\"false\"></div>"), "<div Draggable=\"false\"></div>")
  }

  func testDraggableCaseSensitiveFoo() {
    // Line 1930
    XCTAssertEqual(Bonsai.minifyHTML("<div Draggable=\"foo\"></div>"), "<div Draggable></div>")
  }

  func testDraggableCaseSensitiveBare() {
    // Line 1931
    XCTAssertEqual(Bonsai.minifyHTML("<div Draggable></div>"), "<div Draggable></div>")
  }

  func testDraggableAutoUppercase() {
    // Line 1932
    XCTAssertEqual(Bonsai.minifyHTML("<div draggable=\"Auto\"></div>"), "<div draggable></div>")
  }

  func testCrossoriginEmpty() {
    // Line 1933
    XCTAssertEqual(Bonsai.minifyHTML("<img crossorigin=\"\">"), "<img crossorigin>")
  }

  func testCrossoriginAnonymous() {
    // Line 1934
    XCTAssertEqual(Bonsai.minifyHTML("<img crossorigin=\"anonymous\">"), "<img crossorigin=\"anonymous\">")
  }

  func testCrossoriginUseCredentials() {
    // Line 1935
    XCTAssertEqual(
      Bonsai.minifyHTML("<img crossorigin=\"use-credentials\">"),
      "<img crossorigin=\"use-credentials\">"
    )
  }

  func testScriptCrossoriginEmpty() {
    // Line 1936
    XCTAssertEqual(
      Bonsai.minifyHTML("<script crossorigin=\"\" src=\"x.js\"></script>"),
      "<script crossorigin src=\"x.js\"></script>"
    )
  }

  func testContenteditableEmpty() {
    // Line 1937
    XCTAssertEqual(Bonsai.minifyHTML("<div contenteditable=\"\"></div>"), "<div contenteditable></div>")
  }

  func testContenteditableTrue() {
    // Line 1938
    XCTAssertEqual(
      Bonsai.minifyHTML("<div contenteditable=\"true\"></div>"),
      "<div contenteditable=\"true\"></div>"
    )
  }

  func testContenteditableFalse() {
    // Line 1939
    XCTAssertEqual(
      Bonsai.minifyHTML("<div contenteditable=\"false\"></div>"),
      "<div contenteditable=\"false\"></div>"
    )
  }

  // ============================================================================
  // MARK: - Remove script type attributes

  // html-minifier-next: "Remove JavaScript-related `type` attributes" (lines 1278-1334)
  // ============================================================================

  func testRemoveScriptTypeEmpty() {
    // Line 1284
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"\">alert(1)</script>"),
      "<script>alert(1)</script>"
    )
  }

  func testRemoveScriptTypeNoValue() {
    // Line 1290
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type>alert(1)</script>"),
      "<script>alert(1)</script>"
    )
  }

  func testKeepScriptTypeModules() {
    // Line 1295: "modules" (plural, not "module") is not a known type
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"modules\">alert(1)</script>"),
      "<script type=\"modules\">alert(1)</script>"
    )
  }

  func testRemoveScriptTypeTextJavascript() {
    // Line 1300
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/javascript\">alert(1)</script>"),
      "<script>alert(1)</script>"
    )
  }

  func testUppercaseScriptTypeNotRemoved() {
    // Line 1304: caseSensitive — SCRIPT/TYPE not lowercase, type preserved
    XCTAssertEqual(
      Bonsai.minifyHTML("<SCRIPT TYPE=\"  text/javascript \">alert(1)</SCRIPT>"),
      "<SCRIPT TYPE=\"text/javascript\">alert(1)</SCRIPT>"
    )
  }

  func testRemoveScriptTypeSemicolon() {
    // Line 1308
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"application/javascript;version=1.8\">alert(1)</script>"),
      "<script>alert(1)</script>"
    )
  }

  func testKeepScriptTypeVbscript() {
    // Line 1312
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/vbscript\">MsgBox(\"foo bar\")</script>"),
      "<script type=\"text/vbscript\">MsgBox(\"foo bar\")</script>"
    )
  }

  func testKeepScriptTypeLdJson() {
    // Line 1317
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"application/ld+json\">{\"foo\":\"bar\"}</script>"),
      "<script type=\"application/ld+json\">{\"foo\":\"bar\"}</script>"
    )
  }

  func testKeepScriptTypeImportmap() {
    // Line 1321
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"importmap\">{\"imports\":{}}</script>"),
      "<script type=\"importmap\">{\"imports\":{}}</script>"
    )
  }

  func testKeepScriptTypeProblemJson() {
    // Line 1325
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"application/problem+json\">{\"status\":404}</script>"),
      "<script type=\"application/problem+json\">{\"status\":404}</script>"
    )
  }

  func testKeepScriptTypeMergePatchJson() {
    // Line 1329
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"application/merge-patch+json\">{\"title\":\"New\"}</script>"),
      "<script type=\"application/merge-patch+json\">{\"title\":\"New\"}</script>"
    )
  }

  func testKeepScriptTypeJsonPatchJson() {
    // Line 1333
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"application/json-patch+json\">[{\"op\":\"add\"}]</script>"),
      "<script type=\"application/json-patch+json\">[{\"op\":\"add\"}]</script>"
    )
  }

  // ============================================================================
  // MARK: - Remove style/link type attributes

  // html-minifier-next: "Remove CSS-related `type` attributes" (lines 1336-1372)
  // ============================================================================

  func testRemoveStyleTypeEmpty() {
    // Line 1342
    XCTAssertEqual(
      Bonsai.minifyHTML("<style type=\"\">.foo { color: red }</style>"),
      "<style>.foo { color: red }</style>"
    )
  }

  func testRemoveStyleTypeNoValue() {
    // Line 1348
    XCTAssertEqual(
      Bonsai.minifyHTML("<style type>.foo { color: red }</style>"),
      "<style>.foo { color: red }</style>"
    )
  }

  func testRemoveStyleTypeTextCss() {
    // Line 1353
    XCTAssertEqual(
      Bonsai.minifyHTML("<style type=\"text/css\">.foo { color: red }</style>"),
      "<style>.foo { color: red }</style>"
    )
  }

  func testUppercaseStyleTypeNotRemoved() {
    // Line 1357: caseSensitive — STYLE/TYPE not lowercase
    XCTAssertEqual(
      Bonsai.minifyHTML("<STYLE TYPE = \"  text/CSS \">body { font-size: 1.75em }</STYLE>"),
      "<STYLE TYPE=\"text/CSS\">body { font-size: 1.75em }</STYLE>"
    )
  }

  func testKeepStyleTypeTextPlain() {
    // Line 1360
    XCTAssertEqual(
      Bonsai.minifyHTML("<style type=\"text/plain\">.foo { background: green }</style>"),
      "<style type=\"text/plain\">.foo { background: green }</style>"
    )
  }

  func testRemoveLinkTypeTextCss() {
    // Line 1364
    XCTAssertEqual(
      Bonsai.minifyHTML("<link rel=\"stylesheet\" type=\"text/css\" href=\"https://example.com\">"),
      "<link rel=\"stylesheet\" href=\"https://example.com\">"
    )
  }

  func testRemoveLinkTypeNoValue() {
    // Line 1369
    XCTAssertEqual(
      Bonsai.minifyHTML("<link rel=\"stylesheet\" type href=\"https://example.com\">"),
      "<link rel=\"stylesheet\" href=\"https://example.com\">"
    )
  }

  func testKeepLinkTypeAtomXml() {
    // Line 1372
    XCTAssertEqual(
      Bonsai.minifyHTML("<link rel=\"alternate\" type=\"application/atom+xml\" href=\"data.xml\">"),
      "<link rel=\"alternate\" type=\"application/atom+xml\" href=\"data.xml\">"
    )
  }

  // ============================================================================
  // MARK: - Space normalization between attributes

  // html-minifier-next: "Space normalization between attributes" (lines 174-181)
  // ============================================================================

  func testSelfClosingSlashRemoved() {
    // Line 176
    XCTAssertEqual(Bonsai.minifyHTML("<img src=\"test\"/>"), "<img src=\"test\">")
  }

  func testNormalizesSpaceAroundEquals() {
    // Line 177
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title = \"bar\">foo</p>"),
      "<p title=\"bar\">foo</p>"
    )
  }

  func testNormalizesMultilineAttribute() {
    // Line 178
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title\n\n\t  =\n     \"bar\">foo</p>"),
      "<p title=\"bar\">foo</p>"
    )
  }

  func testMultilineSlashRemoved() {
    // Line 179
    XCTAssertEqual(
      Bonsai.minifyHTML("<img src=\"test\" \n\t />"),
      "<img src=\"test\">"
    )
  }

  func testNormalizesMultipleAttributeSpaces() {
    // Line 180
    XCTAssertEqual(
      Bonsai.minifyHTML("<input title=\"bar\"       id=\"boo\"    value=\"hello world\">"),
      "<input title=\"bar\" id=\"boo\" value=\"hello world\">"
    )
  }

  // ============================================================================
  // MARK: - Types of whitespace that should always be preserved

  // html-minifier-next: "Types of whitespace that should always be preserved" (lines 378-413)
  // ============================================================================

  func testHairSpacePreservedInText() {
    // Lines 380-381
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>\u{200A}fo\u{200A}o\u{200A}</div>"),
      "<div>\u{200A}fo\u{200A}o\u{200A}</div>"
    )
  }

  func testHairSpaceEntityPreserved() {
    // Lines 384-385: Bonsai does not decode entities, so &#8202; passes through
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>&#8202;fo&#8202;o&#8202;</div>"),
      "<div>&#8202;fo&#8202;o&#8202;</div>"
    )
  }

  func testNbspPreservedInText() {
    // Lines 391-392
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>\u{00A0}fo\u{00A0}o\u{00A0}</div>"),
      "<div>\u{00A0}fo\u{00A0}o\u{00A0}</div>"
    )
  }

  func testNbspEntityPreserved() {
    // Lines 395-396: Bonsai does not decode entities, so &nbsp; passes through
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>&nbsp;fo&nbsp;o&nbsp;</div>"),
      "<div>&nbsp;fo&nbsp;o&nbsp;</div>"
    )
  }

  func testHairSpacePreservedInAttribute() {
    // Lines 406-407
    XCTAssertEqual(
      Bonsai.minifyHTML("<p class=\"foo\u{200A}bar\"></p>"),
      "<p class=\"foo\u{200A}bar\"></p>"
    )
  }

  // ============================================================================
  // MARK: - caseSensitive

  // html-minifier-next: "caseSensitive" (lines 2422-2429)
  // ============================================================================

  func testCaseSensitiveAttributePreserved() {
    // Line 2427: caseSensitive: true preserves mixed-case attribute names
    XCTAssertEqual(
      Bonsai.minifyHTML("<div mixedCaseAttribute=\"value\"></div>"),
      "<div mixedCaseAttribute=\"value\"></div>"
    )
  }

  // ============================================================================
  // MARK: - Mixed HTML and SVG

  // html-minifier-next: "Mixed HTML and SVG" (lines 2441-2464)
  // ============================================================================

  func testMixedHtmlAndSvg() {
    // Lines 2442-2463
    let input = "<html><body>\n" +
      "  <svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\"\n" +
      "     width=\"612px\" height=\"502.174px\" viewBox=\"0 65.326 612 502.174\" enable-background=\"new 0 65.326 612 502.174\"\n" +
      "     xml:space=\"preserve\" class=\"logo\">    <ellipse class=\"ground\" cx=\"283.5\" cy=\"487.5\" rx=\"259\" ry=\"80\"/>    <polygon points=\"100,10 40,198 190,78 10,78 160,198\"\n" +
      "      style=\"fill:lime;stroke:purple;stroke-width:5;fill-rule:evenodd;\" />\n" +
      "    <filter id=\"pictureFilter\">\n" +
      "      <feGaussianBlur stdDeviation=\"15\" />\n" +
      "    </filter>\n" +
      "  </svg>\n" +
      "</body></html>"
    let expected = "<html><body>" +
      "<svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" " +
      "width=\"612px\" height=\"502.174px\" viewBox=\"0 65.326 612 502.174\" enable-background=\"new 0 65.326 612 502.174\" " +
      "xml:space=\"preserve\" class=\"logo\">" +
      "<ellipse class=\"ground\" cx=\"283.5\" cy=\"487.5\" rx=\"259\" ry=\"80\"/>" +
      "<polygon points=\"100,10 40,198 190,78 10,78 160,198\" style=\"fill:lime;stroke:purple;stroke-width:5;fill-rule:evenodd;\"/>" +
      "<filter id=\"pictureFilter\">" +
      "<feGaussianBlur stdDeviation=\"15\"/>" +
      "</filter></svg></body></html>"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  // ============================================================================
  // MARK: - SVG and MathML self-closing elements

  // html-minifier-next: "SVG and MathML self-closing elements" (lines 2466-2491)
  // ============================================================================

  func testSvgPreservesClosingSlash() {
    // Lines 2468-2470: SVG elements keep />, HTML void elements don't
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><img src=\"test.jpg\"/><svg><path d=\"M 0 0\"/><circle cx=\"5\" cy=\"5\" r=\"2\"/></svg><br/></div>"),
      "<div><img src=\"test.jpg\"><svg><path d=\"M 0 0\"/><circle cx=\"5\" cy=\"5\" r=\"2\"/></svg><br></div>"
    )
  }

  func testMathMLPreservesClosingSlash() {
    // Lines 2473-2475
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><math><mrow><mi>x</mi></mrow><mspace width=\"1em\"/><mrow><mi>y</mi></mrow></math></div>"),
      "<div><math><mrow><mi>x</mi></mrow><mspace width=\"1em\"/><mrow><mi>y</mi></mrow></math></div>"
    )
  }

  func testNestedSvgGroups() {
    // Lines 2483-2485
    XCTAssertEqual(
      Bonsai.minifyHTML("<svg><g><path d=\"M 0 0\"/><g><circle cx=\"5\" cy=\"5\" r=\"2\"/></g></g></svg>"),
      "<svg><g><path d=\"M 0 0\"/><g><circle cx=\"5\" cy=\"5\" r=\"2\"/></g></g></svg>"
    )
  }

  func testSvgVoidElements() {
    // Lines 2488-2490
    XCTAssertEqual(
      Bonsai.minifyHTML("<svg><line x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"/><rect x=\"0\" y=\"0\" width=\"10\" height=\"10\"/><use href=\"#x\"/></svg>"),
      "<svg><line x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"/><rect x=\"0\" y=\"0\" width=\"10\" height=\"10\"/><use href=\"#x\"/></svg>"
    )
  }

  // ============================================================================
  // MARK: - Remove redundant attributes

  // html-minifier-next: "Remove redundant attributes" (lines 1089-1157)
  // Tests marked (composite) are extracted from "Attribute value defaults" (lines 1175-1218)
  // with pre-quoted inputs since Bonsai always quotes unquoted attributes.
  // ============================================================================

  func testRemoveRedundantFormMethodGet() {
    // Line 1092-1093
    XCTAssertEqual(
      Bonsai.minifyHTML("<form method=\"get\">hello world</form>"),
      "<form>hello world</form>"
    )
  }

  func testKeepFormMethodPost() {
    // Line 1095-1096
    XCTAssertEqual(
      Bonsai.minifyHTML("<form method=\"post\">hello world</form>"),
      "<form method=\"post\">hello world</form>"
    )
  }

  func testRemoveRedundantInputTypeText() {
    // Line 1102-1103
    XCTAssertEqual(Bonsai.minifyHTML("<input type=\"text\">"), "<input>")
  }

  func testRemoveInputTypeTextWithWhitespace() {
    // Line 1105-1106
    XCTAssertEqual(
      Bonsai.minifyHTML("<input type=\"  TEXT  \" value=\"foo\">"),
      "<input value=\"foo\">"
    )
  }

  func testKeepInputTypeCheckbox() {
    // Line 1108-1109
    XCTAssertEqual(
      Bonsai.minifyHTML("<input type=\"checkbox\">"),
      "<input type=\"checkbox\">"
    )
  }

  func testRemoveAnchorRedundantName() {
    // Line 1115-1116
    XCTAssertEqual(
      Bonsai.minifyHTML("<a id=\"foo\" name=\"foo\">blah</a>"),
      "<a id=\"foo\">blah</a>"
    )
  }

  func testKeepInputNameWithId() {
    // Line 1118-1119
    XCTAssertEqual(
      Bonsai.minifyHTML("<input id=\"foo\" name=\"foo\">"),
      "<input id=\"foo\" name=\"foo\">"
    )
  }

  func testKeepAnchorNameWithoutId() {
    // Line 1121-1122
    XCTAssertEqual(
      Bonsai.minifyHTML("<a name=\"foo\">blah</a>"),
      "<a name=\"foo\">blah</a>"
    )
  }

  func testRemoveAnchorNameMatchingIdTrimmed() {
    // Line 1124-1125: Uses Unicode ellipsis U+2026, trailing space before >
    XCTAssertEqual(
      Bonsai.minifyHTML("<a href=\"\u{2026}\" name=\"  bar  \" id=\"bar\" >blah</a>"),
      "<a href=\"\u{2026}\" id=\"bar\">blah</a>"
    )
  }

  func testRemoveScriptCharsetWithoutSrc() {
    // Line 1131-1133: Bonsai also removes type="text/javascript" via removeScriptTypeAttributes
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/javascript\" charset=\"UTF-8\">alert(222);</script>"),
      "<script>alert(222);</script>"
    )
  }

  func testKeepScriptCharsetWithSrc() {
    // Line 1135-1136: Bonsai removes type but keeps charset (src present)
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/javascript\" src=\"https://example.com\" charset=\"UTF-8\">alert(222);</script>"),
      "<script src=\"https://example.com\" charset=\"UTF-8\">alert(222);</script>"
    )
  }

  func testRemoveScriptCharsetUppercase() {
    // Line 1138-1140: Uses Unicode ellipsis U+2026
    XCTAssertEqual(
      Bonsai.minifyHTML("<script CHARSET=\" \u{2026} \">alert(222);</script>"),
      "<script>alert(222);</script>"
    )
  }

  func testRemoveScriptLanguage() {
    // Line 1146-1147
    XCTAssertEqual(
      Bonsai.minifyHTML("<script language=\"Javascript\">x=2,y=4</script>"),
      "<script>x=2,y=4</script>"
    )
  }

  func testRemoveScriptLanguageWithWhitespace() {
    // Line 1149-1150
    XCTAssertEqual(
      Bonsai.minifyHTML("<script LANGUAGE = \"  javaScript  \">x=2,y=4</script>"),
      "<script>x=2,y=4</script>"
    )
  }

  func testRemoveAreaShapeRect() {
    // Line 1154-1156
    XCTAssertEqual(
      Bonsai.minifyHTML("<area shape=\"rect\" coords=\"696,25,958,47\" href=\"#\" title=\"foo\">"),
      "<area coords=\"696,25,958,47\" href=\"#\" title=\"foo\">"
    )
  }

  func testRemoveRedundantButtonTypeSubmit() {
    // Lines 1182-1183 / 1203 (composite)
    XCTAssertEqual(
      Bonsai.minifyHTML("<button type=\"submit\">Go</button>"),
      "<button>Go</button>"
    )
  }

  func testRemoveImgDefaultAttributes() {
    // Lines 1185 / 1206 (composite): loading="eager", fetchpriority="auto", decoding="auto"
    XCTAssertEqual(Bonsai.minifyHTML("<img loading=\"eager\">"), "<img>")
    XCTAssertEqual(Bonsai.minifyHTML("<img fetchpriority=\"auto\">"), "<img>")
    XCTAssertEqual(Bonsai.minifyHTML("<img decoding=\"auto\">"), "<img>")
  }

  func testRemoveStyleMediaAll() {
    // Lines 1180 / 1201 (composite)
    XCTAssertEqual(
      Bonsai.minifyHTML("<style media=\"all\"></style>"),
      "<style></style>"
    )
  }

  func testRemoveLinkMediaAll() {
    // Lines 1179 / 1200 (composite)
    XCTAssertEqual(
      Bonsai.minifyHTML("<link rel=\"stylesheet\" media=\"all\">"),
      "<link rel=\"stylesheet\">"
    )
  }

  func testRemoveTextareaWrapSoft() {
    // Lines 1193 / 1214 (composite)
    XCTAssertEqual(
      Bonsai.minifyHTML("<textarea wrap=\"soft\"></textarea>"),
      "<textarea></textarea>"
    )
  }

  func testRemoveTrackKindSubtitles() {
    // Lines 1195 / 1216 (composite)
    XCTAssertEqual(
      Bonsai.minifyHTML("<track src=\"example\" kind=\"subtitles\">"),
      "<track src=\"example\">"
    )
  }

  func testRemoveHtmlDirLtr() {
    // Lines 1177 / 1198 (composite)
    XCTAssertEqual(Bonsai.minifyHTML("<html dir=\"ltr\">"), "<html>")
  }

  // ============================================================================
  // MARK: - Remove empty attributes

  // html-minifier-next: "Remove empty attributes" (lines 951-977)
  // ============================================================================

  func testRemoveEmptyAttributes() {
    // Line 954-955
    XCTAssertEqual(
      Bonsai.minifyHTML("<p id=\"\" class=\"\" STYLE=\" \" title=\"\n\" lang=\"\" dir=\"\">x</p>"),
      "<p>x</p>"
    )
  }

  func testRemoveEmptyEventAndKeyboardHandlers() {
    // Lines 957-959: Combined mouse + keyboard handlers
    let input = "<p onclick=\"\"   ondblclick=\" \" onmousedown=\"\" ONMOUSEUP=\"\" onmouseover=\" \" onmousemove=\"\" onmouseout=\"\" " +
      "onkeypress=\n\n  \"\n     \" onkeydown=\n\"\" onkeyup\n=\"\">x</p>"
    XCTAssertEqual(Bonsai.minifyHTML(input), "<p>x</p>")
  }

  func testRemoveEmptyFocusHandlersKeepValue() {
    // Line 961-962
    XCTAssertEqual(
      Bonsai.minifyHTML("<input onfocus=\"\" onblur=\"\" onchange=\" \" value=\" boo \">"),
      "<input value=\" boo \">"
    )
  }

  func testRemoveEmptyInputValue() {
    // Line 964-965
    XCTAssertEqual(
      Bonsai.minifyHTML("<input value=\"\" name=\"foo\">"),
      "<input name=\"foo\">"
    )
  }

  func testKeepEmptyImgSrcAndAlt() {
    // Line 967-968
    XCTAssertEqual(
      Bonsai.minifyHTML("<img src=\"\" alt=\"\">"),
      "<img src=\"\" alt=\"\">"
    )
  }

  func testRemoveBareEmptyAttributes() {
    // Line 971-972
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-foo class id style title lang dir onfocus onblur onchange onclick ondblclick onmousedown onmouseup onmouseover onmousemove onmouseout onkeypress onkeydown onkeyup></div>"),
      "<div data-foo></div>"
    )
  }

  // ============================================================================
  // MARK: - Collapse attribute whitespace

  // html-minifier-next: "Collapse attribute whitespace" (lines 4199-4274)
  // ============================================================================

  func testCollapseAttributeWhitespace() {
    // Lines 4208-4210
    let input = "<article title=\"foo  bar\" data-selector=\"teaser-object parent-image-label picture-article\" data-external-selector=\"\n      teaser-object parent-image-label \n        \n    \"></article>"
    let expected = "<article title=\"foo bar\" data-selector=\"teaser-object parent-image-label picture-article\" data-external-selector=\"teaser-object parent-image-label\"></article>"
    XCTAssertEqual(Bonsai.minifyHTML(input), expected)
  }

  func testCollapseMediaAttributeWhitespace() {
    // Lines 4219-4223
    XCTAssertEqual(
      Bonsai.minifyHTML("<source media=\"(min-width:  768px)\">"),
      "<source media=\"(min-width: 768px)\">"
    )
  }

  func testTrimAndCollapseAttributeWhitespace() {
    // Lines 4226-4229
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"  hello world  \"></div>"),
      "<div title=\"hello world\"></div>"
    )
  }

  func testCollapseNewlinesTabsInAttribute() {
    // Lines 4242-4244
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-value=\"hello\t\tworld\n\ntest\"></div>"),
      "<div data-value=\"hello world test\"></div>"
    )
  }

  func testNoChangeCleanAttribute() {
    // Lines 4247-4248
    XCTAssertEqual(
      Bonsai.minifyHTML("<p class=\"foo bar baz\"></p>"),
      "<p class=\"foo bar baz\"></p>"
    )
  }

  func testAttributeWhitespaceWithTextCollapsing() {
    // Lines 4256-4258
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title=\"  foo   bar  \">\n  Hello   \n  world  \n</p>"),
      "<p title=\"foo bar\">Hello world</p>"
    )
  }

  func testHairSpacePreservedInAttributeCollapse() {
    // Lines 4261-4263
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"foo\u{200A}bar  baz\"></div>"),
      "<div title=\"foo\u{200A}bar baz\"></div>"
    )
  }

  func testNoBreakSpaceNotCollapsedInAttribute() {
    // Lines 4266-4267
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"foo\u{00A0}\u{00A0}bar\"></div>"),
      "<div title=\"foo\u{00A0}\u{00A0}bar\"></div>"
    )
  }
}
