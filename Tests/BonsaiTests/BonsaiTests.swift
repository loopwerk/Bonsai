@testable import Bonsai
import XCTest

/// Tests ported from html-minifier-next's test suite, run with the conservative preset:
/// { caseSensitive: true, collapseBooleanAttributes: true, collapseWhitespace: true,
///   conservativeCollapse: true, preserveLineBreaks: true, processConditionalComments: true,
///   removeComments: true, removeScriptTypeAttributes: true,
///   removeStyleLinkTypeAttributes: true, useShortDoctype: true }
final class BonsaiTests: XCTestCase {
  // ============================================================================
  // MARK: - Space normalization around text

  // html-minifier-next: "Space normalization around text" (lines 209-339)
  // ============================================================================

  func testSpaceNormLeadingTrailingNewlines() {
    // Line 220: conservativeCollapse + preserveLineBreaks
    XCTAssertEqual(
      Bonsai.minifyHTML("   <p>blah</p>\n\n\n   "),
      " <p>blah</p>\n"
    )
  }

  func testInlineElementsPreserveSpaces() {
    // Lines 225-233: with conservativeCollapse, input preserved as-is
    let inlines = [
      "a", "abbr", "acronym", "b", "big", "del", "em", "font", "i", "ins", "kbd",
      "mark", "s", "samp", "small", "span", "strike", "strong", "sub", "sup",
      "time", "tt", "u", "var",
    ]
    for el in inlines {
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)> bar"),
        "foo <\(el)>baz</\(el)> bar",
        "\(el): spaces around"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)>bar"),
        "foo<\(el)>baz</\(el)>bar",
        "\(el): no spaces"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("foo <\(el)>baz</\(el)>bar"),
        "foo <\(el)>baz</\(el)>bar",
        "\(el): leading space"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("foo<\(el)>baz</\(el)> bar"),
        "foo<\(el)>baz</\(el)> bar",
        "\(el): trailing space"
      )
    }
  }

  func testInlineElementsInsideDiv() {
    // Lines 234-241: inside <div>, conservativeCollapse preserves spaces
    let inlines = [
      "a", "abbr", "acronym", "b", "big", "del", "em", "font", "i", "ins", "kbd",
      "mark", "s", "samp", "small", "span", "strike", "strong", "sub", "sup",
      "time", "tt", "u", "var",
    ]
    for el in inlines {
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)> bar</div>"),
        "<div>foo <\(el)>baz</\(el)> bar</div>",
        "\(el) in div: spaces"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)>bar</div>"),
        "<div>foo<\(el)>baz</\(el)>bar</div>",
        "\(el) in div: no spaces"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo <\(el)>baz</\(el)>bar</div>"),
        "<div>foo <\(el)>baz</\(el)>bar</div>",
        "\(el) in div: leading space"
      )
      XCTAssertEqual(
        Bonsai.minifyHTML("<div>foo<\(el)>baz</\(el)> bar</div>"),
        "<div>foo<\(el)>baz</\(el)> bar</div>",
        "\(el) in div: trailing space"
      )
    }
  }

  func testNobrSpacePermutations() {
    // Lines 265-296: conservativeCollapse preserves all nobr inputs as-is
    let cases: [(String, String)] = [
      ("<nobr>a</nobr>", "<nobr>a</nobr>"),
      ("<nobr>a </nobr>", "<nobr>a </nobr>"),
      ("<nobr> a</nobr>", "<nobr> a</nobr>"),
      ("<nobr> a </nobr>", "<nobr> a </nobr>"),
      ("a<nobr>b</nobr>c", "a<nobr>b</nobr>c"),
      ("a<nobr>b </nobr>c", "a<nobr>b </nobr>c"),
      ("a<nobr> b</nobr>c", "a<nobr> b</nobr>c"),
      ("a<nobr> b </nobr>c", "a<nobr> b </nobr>c"),
      ("a<nobr>b</nobr> c", "a<nobr>b</nobr> c"),
      ("a<nobr>b </nobr> c", "a<nobr>b </nobr> c"),
      ("a<nobr> b</nobr> c", "a<nobr> b</nobr> c"),
      ("a<nobr> b </nobr> c", "a<nobr> b </nobr> c"),
      ("a <nobr>b</nobr>c", "a <nobr>b</nobr>c"),
      ("a <nobr>b </nobr>c", "a <nobr>b </nobr>c"),
      ("a <nobr> b</nobr>c", "a <nobr> b</nobr>c"),
      ("a <nobr> b </nobr>c", "a <nobr> b </nobr>c"),
      ("a <nobr>b</nobr> c", "a <nobr>b</nobr> c"),
      ("a <nobr>b </nobr> c", "a <nobr>b </nobr> c"),
      ("a <nobr> b</nobr> c", "a <nobr> b</nobr> c"),
      ("a <nobr> b </nobr> c", "a <nobr> b </nobr> c"),
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

  func testProcessingInstructionPreserved() {
    // Lines 318-335: conservativeCollapse + removeComments
    XCTAssertEqual(Bonsai.minifyHTML(" a <? b ?> c "), " a <? b ?> c ")
    XCTAssertEqual(Bonsai.minifyHTML("<!-- d --> a <? b ?> c "), " a <? b ?> c ")
    XCTAssertEqual(Bonsai.minifyHTML("<p> a <? b ?> c </p>"), "<p> a <? b ?> c </p>")
  }

  func testEmptyInlineElementSpaces() {
    // Line 337-338
    XCTAssertEqual(
      Bonsai.minifyHTML("<li><i></i> <b></b> foo</li>"),
      "<li><i></i> <b></b> foo</li>"
    )
  }

  // ============================================================================
  // MARK: - Collapse whitespace

  // html-minifier-next: "Collapse whitespace" (lines 1550-1620)
  // ============================================================================

  func testCollapseScriptContent() {
    // Line 1553-1555: script content trimmed, type removed
    XCTAssertEqual(
      Bonsai.minifyHTML("<script type=\"text/javascript\">  \n\t   alert(1) \n\n\n  \t </script>"),
      "<script>\nalert(1)\n</script>"
    )
  }

  func testCollapseMultipleBlocks() {
    // Line 1557-1559
    XCTAssertEqual(
      Bonsai.minifyHTML("<p>foo</p>    <p> bar</p>\n\n   \n\t\t  <div title=\"quz\">baz  </div>"),
      "<p>foo</p> <p> bar</p>\n<div title=\"quz\">baz </div>"
    )
  }

  func testConservativeCollapseLeadingSpace() {
    // Line 1561-1563
    XCTAssertEqual(Bonsai.minifyHTML("<p> foo    bar</p>"), "<p> foo bar</p>")
  }

  func testCollapseNewlineToSpace() {
    // Line 1565-1567
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo\nbar</p>"), "<p>foo bar</p>")
  }

  func testCollapseInlineElementSpaces() {
    // Line 1569-1571
    XCTAssertEqual(
      Bonsai.minifyHTML("<p> foo    <span>  blah     <i>   22</i>    </span> bar <img src=\"\"></p>"),
      "<p> foo <span> blah <i> 22</i> </span> bar <img src=\"\"></p>"
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
      "<div><textarea></textarea> </div>"
    )
  }

  func testCaseSensitivePreElement() {
    // Line 1581-1585: caseSensitive means <pRe> is NOT recognized as pre
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><pRe> $foo = \"baz\"; </pRe>    </div>"),
      "<div><pRe> $foo = \"baz\"; </pRe> </div>"
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
      "<script>alert(\"foo     bar\") </script>"
    )
  }

  func testStylePreservesInternalWhitespace() {
    // Lines 1617-1619
    XCTAssertEqual(
      Bonsai.minifyHTML("<style>alert(\"foo     bar\")    </style>"),
      "<style>alert(\"foo     bar\") </style>"
    )
  }

  func testBoldContentWithNewlines() {
    // From space normalization section
    XCTAssertEqual(Bonsai.minifyHTML("<b>   foo \n\n</b>"), "<b> foo\n</b>")
  }

  func testBigDocumentIntegration() {
    // Lines 1587-1603: major integration test
    let input = "<script type=\"text/javascript\">var = \"hello\";</script>\r\n\r\n\r\n" +
      "<style type=\"text/css\">#foo { color: red;        }          </style>\r\n\r\n\r\n" +
      "<div>\r\n  <div>\r\n    <div><!-- hello -->\r\n      <div>" +
      "<!--! hello -->\r\n        <div>\r\n          <div class=\"\">\r\n\r\n            " +
      "<textarea disabled=\"disabled\">     this is a textarea </textarea>\r\n          " +
      "</div>\r\n        </div>\r\n      </div>\r\n    </div>\r\n  </div>\r\n</div>" +
      "<pre>       \r\nxxxx</pre><span>x</span> <span>Hello</span> <b>billy</b>     \r\n" +
      "<input type=\"text\">\r\n<textarea></textarea>\r\n<pre></pre>"
    let expected = "<script>var = \"hello\";</script>\n" +
      "<style>#foo { color: red;        } </style>\n" +
      "<div>\n<div>\n<div>\n<div><!--! hello -->\n<div>\n<div>\n" +
      "<textarea disabled>     this is a textarea </textarea>\n" +
      "</div>\n</div>\n</div>\n</div>\n</div>\n</div>" +
      "<pre>       \r\nxxxx</pre><span>x</span> <span>Hello</span> <b>billy</b>\n" +
      "<input>\n<textarea></textarea>\n<pre></pre>"
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
      "<!--[if IE 7]>\n<link rel=\"stylesheet\" href=\"/css/ie7-fixes.css\">\n<![endif]-->"
    )
  }

  func testConditionalCommentCollapseParagraph() {
    // Lines 582-590
    XCTAssertEqual(
      Bonsai.minifyHTML("<!--[if lte IE 6]>\n    \n   \n\n\n\t<p title=\" sigificant     whitespace   \">blah blah</p><![endif]-->"),
      "<!--[if lte IE 6]>\n<p title=\"sigificant whitespace\">blah blah</p><![endif]-->"
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
  // MARK: - Additional whitespace tests

  // ============================================================================

  func testConservativeCollapseMultipleSpaces() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo    bar</p>"), "<p>foo bar</p>")
  }

  func testConservativeCollapseTrailingSpace() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo    bar </p>"), "<p>foo bar </p>")
  }

  func testConservativeCollapseTabs() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo\t\tbar</p>"), "<p>foo bar</p>")
  }

  func testWhitespaceOnlyNoNewlines() {
    XCTAssertEqual(Bonsai.minifyHTML("   "), " ")
  }

  func testWhitespaceOnlyWithNewlines() {
    XCTAssertEqual(Bonsai.minifyHTML("   \n\t  "), "\n")
  }

  func testNewlinesBetweenBlocks() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>\n  <p>hi</p>\n</div>"),
      "<div>\n<p>hi</p>\n</div>"
    )
  }

  func testNewlinesBetweenParagraphs() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p>a</p>\n\n<p>b</p>"),
      "<p>a</p>\n<p>b</p>"
    )
  }

  func testNewlineAroundParagraph() {
    XCTAssertEqual(Bonsai.minifyHTML("a\n<p>b</p>\nc"), "a\n<p>b</p>\nc")
  }

  func testNewlineAtEndOfParagraph() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>text\n</p>"), "<p>text\n</p>")
  }

  func testNewlineAtStartOfParagraph() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>\ntext</p>"), "<p>\ntext</p>")
  }

  func testInternalNewlineCollapsesToSpace() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>a\nb</p>"), "<p>a b</p>")
  }

  func testMultipleInternalNewlines() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>a\n\n\nb</p>"), "<p>a b</p>")
  }

  func testTopLevelNewlinesCollapseToSpace() {
    XCTAssertEqual(Bonsai.minifyHTML("text\n\ntext"), "text text")
  }

  func testDivTextWithTrailingNewline() {
    XCTAssertEqual(Bonsai.minifyHTML("<div>  text \n </div>"), "<div> text\n</div>")
  }

  func testDivTextWithLeadingNewline() {
    XCTAssertEqual(Bonsai.minifyHTML("<div>\ntext  </div>"), "<div>\ntext </div>")
  }

  func testCRLFHandled() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>text\r\n</p>"), "<p>text\n</p>")
  }

  func testMixedWhitespaceWithNewline() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo \t\n\t bar</p>"), "<p>foo bar</p>")
  }

  func testWhitespaceBetweenDivs() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div>  </div>  \n  <div>  </div>"),
      "<div> </div>\n<div> </div>"
    )
  }

  func testNewlinesAroundInput() {
    XCTAssertEqual(Bonsai.minifyHTML("test\n\n<input>\n\ntest"), "test\n<input>\ntest")
  }

  // ============================================================================
  // MARK: - Pre/textarea additional tests

  // ============================================================================

  func testPreExactPreservation() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<pre>  a\n  b  </pre>"),
      "<pre>  a\n  b  </pre>"
    )
  }

  func testTextareaExactPreservation() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<textarea>  a\n  b  </textarea>"),
      "<textarea>  a\n  b  </textarea>"
    )
  }

  func testNestedPreTags() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<pre>  <code>  hello  </code>  </pre>"),
      "<pre>  <code>  hello  </code>  </pre>"
    )
  }

  func testMultiplePreservedElements() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<pre>  a  </pre><textarea>  b  </textarea>"),
      "<pre>  a  </pre><textarea>  b  </textarea>"
    )
  }

  func testUppercasePreNotRecognized() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<PRE>  hello   world  </PRE>"),
      "<PRE> hello world </PRE>"
    )
  }

  func testUppercaseTextareaNotRecognized() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<TEXTAREA>  hello   world  </TEXTAREA>"),
      "<TEXTAREA> hello world </TEXTAREA>"
    )
  }

  // ============================================================================
  // MARK: - Script/style content additional tests

  // ============================================================================

  func testScriptContentSimple() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script>  alert(1)  </script>"),
      "<script> alert(1) </script>"
    )
  }

  func testScriptContentWithNewlines() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script>\n  var x = 1;\n</script>"),
      "<script>\nvar x = 1;\n</script>"
    )
  }

  func testScriptContentPreservesInternal() {
    // Internal whitespace preserved, only leading/trailing trimmed
    XCTAssertEqual(
      Bonsai.minifyHTML("<script>  var x = 1;  \n  var y = 2;  </script>"),
      "<script> var x = 1;  \n  var y = 2; </script>"
    )
  }

  func testStyleContentSimple() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<style>  body { color: red; }  </style>"),
      "<style> body { color: red; } </style>"
    )
  }

  func testUppercaseScriptContent() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<SCRIPT>  var x = 1;  </SCRIPT>"),
      "<SCRIPT> var x = 1; </SCRIPT>"
    )
  }

  func testUppercaseStyleContent() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<STYLE>  body { }  </STYLE>"),
      "<STYLE> body { } </STYLE>"
    )
  }

  // ============================================================================
  // MARK: - Self-closing tags / void elements

  // ============================================================================

  func testSelfClosingSlashRemoved() {
    XCTAssertEqual(Bonsai.minifyHTML("<img src=\"test\"/>"), "<img src=\"test\">")
  }

  func testMultipleSelfClosingTags() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<br /><img src=\"test.png\" /><hr />"),
      "<br><img src=\"test.png\"><hr>"
    )
  }

  func testNonVoidSelfClosingSlashRemoved() {
    XCTAssertEqual(Bonsai.minifyHTML("<div />"), "<div>")
    XCTAssertEqual(Bonsai.minifyHTML("<span />"), "<span>")
  }

  // ============================================================================
  // MARK: - SVG/MathML self-closing

  // ============================================================================

  func testSvgSelfClosingPreserved() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<svg><circle r=\"5\"/></svg>"),
      "<svg><circle r=\"5\"/></svg>"
    )
  }

  func testSvgSelfClosingSpaceRemoved() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<svg><circle r=\"5\" /></svg>"),
      "<svg><circle r=\"5\"/></svg>"
    )
  }

  func testSvgVoidElementSlashRemoved() {
    XCTAssertEqual(Bonsai.minifyHTML("<svg><br/></svg>"), "<svg><br></svg>")
  }

  func testMathMLSelfClosingPreserved() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<math><mspace width=\"1em\"/></math>"),
      "<math><mspace width=\"1em\"/></math>"
    )
  }

  func testNestedSvgThenNormal() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div><svg><circle r=\"5\"/></svg><span/></div>"),
      "<div><svg><circle r=\"5\"/></svg><span></div>"
    )
  }

  // ============================================================================
  // MARK: - Attribute space normalization

  // ============================================================================

  func testNormalizesSpaceAroundEquals() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title = \"bar\">foo</p>"),
      "<p title=\"bar\">foo</p>"
    )
  }

  func testNormalizesMultilineAttribute() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title\n\n\t  =\n     \"bar\">foo</p>"),
      "<p title=\"bar\">foo</p>"
    )
  }

  func testNormalizesMultipleAttributeSpaces() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input title=\"bar\"       id=\"boo\"    value=\"hello world\">"),
      "<input title=\"bar\" id=\"boo\" value=\"hello world\">"
    )
  }

  // ============================================================================
  // MARK: - Case preservation

  // ============================================================================

  func testPreservesTagCase() {
    XCTAssertEqual(Bonsai.minifyHTML("<DIV>hello</DIV>"), "<DIV>hello</DIV>")
    XCTAssertEqual(Bonsai.minifyHTML("<Span>text</Span>"), "<Span>text</Span>")
  }

  func testPreservesAttributeNameCase() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div onClick=\"foo()\">bar</div>"),
      "<div onClick=\"foo()\">bar</div>"
    )
  }

  func testPreservesDataAttributes() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-MyValue=\"test\">bar</div>"),
      "<div data-MyValue=\"test\">bar</div>"
    )
  }

  // ============================================================================
  // MARK: - Edge cases

  // ============================================================================

  func testEmptyDocument() {
    XCTAssertEqual(Bonsai.minifyHTML(""), "")
  }

  func testPlainText() {
    XCTAssertEqual(Bonsai.minifyHTML("hello world"), "hello world")
  }

  func testPlainTextMultipleSpaces() {
    XCTAssertEqual(Bonsai.minifyHTML("hello   world"), "hello world")
  }

  func testHairSpacePreserved() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo\u{200A}bar</p>"), "<p>foo\u{200A}bar</p>")
  }

  func testNoBreakSpacePreserved() {
    XCTAssertEqual(Bonsai.minifyHTML("<p>foo\u{00A0}bar</p>"), "<p>foo\u{00A0}bar</p>")
  }

  func testCDATAContent() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<![CDATA[  content  ]]>"),
      " content "
    )
  }

  func testUnquotedAttributeValues() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div class=foo>bar</div>"),
      "<div class=\"foo\">bar</div>"
    )
  }

  func testAttributeWithoutValue() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-custom>hello</div>"),
      "<div data-custom>hello</div>"
    )
  }

  // ============================================================================
  // MARK: - Remove redundant attributes

  // html-minifier-next: "Remove redundant attributes" (lines 1089-1218)
  // ============================================================================

  func testRemoveRedundantFormMethodGet() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<form method=\"get\">hello world</form>"),
      "<form>hello world</form>"
    )
  }

  func testRemoveRedundantInputTypeText() {
    XCTAssertEqual(Bonsai.minifyHTML("<input type=\"text\">"), "<input>")
  }

  func testRemoveRedundantButtonTypeSubmit() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<button type=\"submit\">Go</button>"),
      "<button>Go</button>"
    )
  }

  func testKeepFormMethodPost() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<form method=\"post\">hello world</form>"),
      "<form method=\"post\">hello world</form>"
    )
  }

  func testRemoveInputTypeTextWithWhitespace() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input type=\"  TEXT  \" value=\"foo\">"),
      "<input value=\"foo\">"
    )
  }

  func testKeepInputTypeCheckbox() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input type=\"checkbox\">"),
      "<input type=\"checkbox\">"
    )
  }

  func testRemoveAnchorRedundantName() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<a id=\"foo\" name=\"foo\">blah</a>"),
      "<a id=\"foo\">blah</a>"
    )
  }

  func testKeepInputNameWithId() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input id=\"foo\" name=\"foo\">"),
      "<input id=\"foo\" name=\"foo\">"
    )
  }

  func testKeepAnchorNameWithoutId() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<a name=\"foo\">blah</a>"),
      "<a name=\"foo\">blah</a>"
    )
  }

  func testRemoveAnchorNameMatchingIdTrimmed() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<a href=\"...\" name=\"  bar  \" id=\"bar\">blah</a>"),
      "<a href=\"...\" id=\"bar\">blah</a>"
    )
  }

  func testRemoveScriptCharsetWithoutSrc() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script charset=\"UTF-8\">alert(222);</script>"),
      "<script>alert(222);</script>"
    )
  }

  func testKeepScriptCharsetWithSrc() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script src=\"https://example.com\" charset=\"UTF-8\">alert(222);</script>"),
      "<script src=\"https://example.com\" charset=\"UTF-8\">alert(222);</script>"
    )
  }

  func testRemoveScriptCharsetUppercase() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script CHARSET=\" ... \">alert(222);</script>"),
      "<script>alert(222);</script>"
    )
  }

  func testRemoveScriptLanguage() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script language=\"Javascript\">x=2,y=4</script>"),
      "<script>x=2,y=4</script>"
    )
  }

  func testRemoveScriptLanguageWithWhitespace() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<script LANGUAGE = \"  javaScript  \">x=2,y=4</script>"),
      "<script>x=2,y=4</script>"
    )
  }

  func testRemoveAreaShapeRect() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<area shape=\"rect\" coords=\"696,25,958,47\" href=\"#\" title=\"foo\">"),
      "<area coords=\"696,25,958,47\" href=\"#\" title=\"foo\">"
    )
  }

  func testRemoveImgLoadingEager() {
    XCTAssertEqual(Bonsai.minifyHTML("<img loading=\"eager\">"), "<img>")
  }

  func testKeepImgLoadingLazy() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<img loading=\"lazy\">"),
      "<img loading=\"lazy\">"
    )
  }

  func testRemoveImgFetchpriorityAuto() {
    XCTAssertEqual(Bonsai.minifyHTML("<img fetchpriority=\"auto\">"), "<img>")
  }

  func testRemoveImgDecodingAuto() {
    XCTAssertEqual(Bonsai.minifyHTML("<img decoding=\"auto\">"), "<img>")
  }

  func testKeepButtonTypeButton() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<button type=\"button\">Go</button>"),
      "<button type=\"button\">Go</button>"
    )
  }

  func testRemoveStyleMediaAll() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<style media=\"all\"></style>"),
      "<style></style>"
    )
  }

  func testRemoveLinkMediaAll() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<link rel=\"stylesheet\" media=\"all\">"),
      "<link rel=\"stylesheet\">"
    )
  }

  func testRemoveTextareaWrapSoft() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<textarea wrap=\"soft\"></textarea>"),
      "<textarea></textarea>"
    )
  }

  func testRemoveTrackKindSubtitles() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<track src=\"example\" kind=\"subtitles\">"),
      "<track src=\"example\">"
    )
  }

  func testRemoveHtmlDirLtr() {
    XCTAssertEqual(Bonsai.minifyHTML("<html dir=\"ltr\">"), "<html>")
  }

  // ============================================================================
  // MARK: - Remove empty attributes

  // html-minifier-next: "Remove empty attributes" (lines 951-977)
  // ============================================================================

  func testRemoveEmptyAttributes() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p id=\"\" class=\"\" STYLE=\" \" title=\"\n\" lang=\"\" dir=\"\">x</p>"),
      "<p>x</p>"
    )
  }

  func testRemoveEmptyEventHandlers() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p onclick=\"\" ondblclick=\" \" onmousedown=\"\" onmouseup=\"\" onmouseover=\" \" onmousemove=\"\" onmouseout=\"\">x</p>"),
      "<p>x</p>"
    )
  }

  func testRemoveEmptyKeyboardHandlers() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p onkeypress=\"\" onkeydown=\"\" onkeyup=\"\">x</p>"),
      "<p>x</p>"
    )
  }

  func testRemoveEmptyFocusHandlersKeepValue() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input onfocus=\"\" onblur=\"\" onchange=\" \" value=\" boo \">"),
      "<input value=\" boo \">"
    )
  }

  func testRemoveEmptyInputValue() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<input value=\"\" name=\"foo\">"),
      "<input name=\"foo\">"
    )
  }

  func testKeepEmptyImgSrcAndAlt() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<img src=\"\" alt=\"\">"),
      "<img src=\"\" alt=\"\">"
    )
  }

  func testRemoveBareEmptyAttributes() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-foo class id style title lang dir onfocus onblur onchange onclick ondblclick onmousedown onmouseup onmouseover onmousemove onmouseout onkeypress onkeydown onkeyup></div>"),
      "<div data-foo></div>"
    )
  }

  func testKeepEmptyDataAttributes() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-x=\"\">hello</div>"),
      "<div data-x=\"\">hello</div>"
    )
  }

  // ============================================================================
  // MARK: - Collapse attribute whitespace

  // html-minifier-next: "Collapse attribute whitespace" (lines 4199-4273)
  // ============================================================================

  func testCollapseAttributeWhitespace() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"foo  bar\">x</div>"),
      "<div title=\"foo bar\">x</div>"
    )
  }

  func testTrimAndCollapseAttributeWhitespace() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"  hello  world  \">x</div>"),
      "<div title=\"hello world\">x</div>"
    )
  }

  func testCollapseNewlinesTabsInAttribute() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div data-value=\"hello\t\tworld\n\ntest\">x</div>"),
      "<div data-value=\"hello world test\">x</div>"
    )
  }

  func testNoChangeCleanAttribute() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p class=\"foo bar baz\">x</p>"),
      "<p class=\"foo bar baz\">x</p>"
    )
  }

  func testCollapseMultilineAttribute() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<article data-external-selector=\"\n      teaser-object parent-image-label \n        \n    \">x</article>"),
      "<article data-external-selector=\"teaser-object parent-image-label\">x</article>"
    )
  }

  func testNoBreakSpaceNotCollapsedInAttribute() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<div title=\"foo\u{00A0}\u{00A0}bar\">x</div>"),
      "<div title=\"foo\u{00A0}\u{00A0}bar\">x</div>"
    )
  }

  func testAttributeWhitespaceWithTextCollapsing() {
    XCTAssertEqual(
      Bonsai.minifyHTML("<p title=\"  foo   bar  \">\n  Hello   \n  world  \n</p>"),
      "<p title=\"foo bar\">\nHello world\n</p>"
    )
  }
}
