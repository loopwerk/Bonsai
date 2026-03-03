#!/usr/bin/env python3
"""Generate FNV-1a hashes for Constants.swift.

Run this script whenever you add or remove entries from the element/attribute
sets in Constants.swift. It prints the hash values and checks for collisions.

Usage:
    python3 Scripts/generate_hashes.py
"""


def fnv_hash_lowered(s):
    """FNV-1a hash with ASCII lowercasing (matches fnvHashLowered in Swift)."""
    h = 14695981039346656037
    for b in s.encode("ascii"):
        if 0x41 <= b <= 0x5A:
            b = b | 0x20
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


def fnv_hash(s):
    """FNV-1a hash, case-sensitive (matches fnvHash in Swift)."""
    h = 14695981039346656037
    for b in s.encode("ascii"):
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


VOID_ELEMENTS = [
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "param", "source", "track", "wbr",
]

RAW_CONTENT_ELEMENTS = ["script", "style"]

PRESERVE_WHITESPACE_ELEMENTS = ["pre", "textarea"]

BOOLEAN_ATTRIBUTES = [
    "allowfullscreen", "async", "autofocus", "autoplay", "checked",
    "compact", "controls", "declare", "default", "defaultchecked",
    "defaultmuted", "defaultselected", "defer", "disabled",
    "enabled", "formnovalidate", "hidden", "indeterminate", "inert",
    "ismap", "itemscope", "loop", "multiple", "muted", "nohref",
    "noresize", "noshade", "novalidate", "nowrap", "open", "pauseonexit",
    "readonly", "required", "reversed", "scoped", "seamless", "selected",
    "sortable", "truespeed", "typemustmatch", "visible",
]

EMPTY_COLLAPSIBLE_ATTRIBUTES = ["crossorigin", "contenteditable"]

EMPTY_REMOVABLE_ATTRIBUTES = [
    "class", "id", "style", "title", "lang", "dir", "value",
    "onclick", "ondblclick", "onmousedown", "onmouseup",
    "onmouseover", "onmousemove", "onmouseout",
    "onkeypress", "onkeydown", "onkeyup",
    "onfocus", "onblur", "onchange",
]

GENERAL_DEFAULTS = {
    "autocorrect": "on",
    "fetchpriority": "auto",
    "loading": "eager",
    "popovertargetaction": "toggle",
}

TAG_DEFAULTS = {
    "a": {"target": "_self"},
    "area": {"shape": "rect", "target": "_self"},
    "audio": {"preload": "auto"},
    "button": {"type": "submit"},
    "canvas": {"height": "150", "width": "300"},
    "form": {"autocomplete": "on", "enctype": "application/x-www-form-urlencoded", "method": "get"},
    "html": {"dir": "ltr"},
    "img": {"decoding": "auto"},
    "input": {"type": "text"},
    "link": {"media": "all"},
    "ol": {"type": "1"},
    "style": {"media": "all"},
    "textarea": {"wrap": "soft"},
    "track": {"kind": "subtitles"},
    "video": {"preload": "auto"},
}

INLINE_KEEP_WS_ALWAYS = ["img", "input", "wbr"]

INLINE_KEEP_WS_AROUND = [
    "a", "abbr", "acronym", "b", "bdi", "bdo", "big", "button", "cite", "code",
    "del", "dfn", "em", "font", "i", "img", "input", "ins", "kbd", "label",
    "mark", "math", "meter", "nobr", "object", "output", "progress", "q",
    "rb", "rp", "rt", "rtc", "ruby", "s", "samp", "select", "small", "span",
    "strike", "strong", "sub", "sup", "svg", "textarea", "time", "tt", "u",
    "var", "wbr",
]

INLINE_KEEP_WS_WITHIN = [
    "a", "abbr", "acronym", "b", "big", "del", "em", "font", "i", "ins",
    "kbd", "mark", "nobr", "s", "samp", "small", "span", "strike", "strong",
    "sub", "sup", "time", "tt", "u", "var",
]

NAMED_HASHES = [
    "script", "style", "link", "a", "svg", "math",
    "type", "language", "charset", "src", "name", "id",
    "draggable", "value", "nobr", "wbr",
]


def format_value_bytes(val):
    return ", ".join(f"0x{b:02X}" for b in val.encode("ascii"))


def print_set(label, items, case_sensitive=False):
    hash_fn = fnv_hash if case_sensitive else fnv_hash_lowered
    note = " (case-sensitive)" if case_sensitive else ""
    print(f"\n// {label}{note}")
    for item in items:
        print(f"  {hash_fn(item)}, // {item}")


def main():
    print_set("voidElementHashes", VOID_ELEMENTS)
    print_set("rawContentElementHashes", RAW_CONTENT_ELEMENTS)
    print_set("preserveWhitespaceHashes", PRESERVE_WHITESPACE_ELEMENTS, case_sensitive=True)
    print_set("booleanAttributeHashes", BOOLEAN_ATTRIBUTES)
    print_set("emptyCollapsibleAttributeHashes", EMPTY_COLLAPSIBLE_ATTRIBUTES)
    print_set("emptyRemovableAttributeHashes", EMPTY_REMOVABLE_ATTRIBUTES)
    print_set("inlineKeepWSAlwaysHashes", INLINE_KEEP_WS_ALWAYS)
    print_set("inlineKeepWSAroundHashes", INLINE_KEEP_WS_AROUND)
    print_set("inlineKeepWSWithinHashes", INLINE_KEEP_WS_WITHIN)

    print("\n// Named hashes")
    for name in NAMED_HASHES:
        print(f"let {name}Hash: UInt64 = {fnv_hash_lowered(name)} // {name}")
    
    # styleAttrHash and valueAttrHash are the same as styleHash/valueHash
    # but named separately for clarity in Bonsai.swift
    print(f"let valueAttrHash: UInt64 = {fnv_hash_lowered('value')} // value")
    print(f"let styleAttrHash: UInt64 = {fnv_hash_lowered('style')} // style")

    print("\n// defaultAttrs")
    for attr, val in GENERAL_DEFAULTS.items():
        ah = fnv_hash_lowered(attr)
        vb = format_value_bytes(val)
        print(f'  DefaultAttr(tagHash: 0, attrHash: {ah}, value: [{vb}]), // *:{attr}="{val}"')
    
    for tag in sorted(TAG_DEFAULTS):
        th = fnv_hash_lowered(tag)
        for attr in sorted(TAG_DEFAULTS[tag]):
            val = TAG_DEFAULTS[tag][attr]
            ah = fnv_hash_lowered(attr)
            vb = format_value_bytes(val)
            print(f'  DefaultAttr(tagHash: {th}, attrHash: {ah}, value: [{vb}]), // {tag}:{attr}="{val}"')

    # Collision check
    print("\n// Collision check")
    all_sets = [
        ("void", VOID_ELEMENTS, False),
        ("raw", RAW_CONTENT_ELEMENTS, False),
        ("pws", PRESERVE_WHITESPACE_ELEMENTS, True),
        ("bool", BOOLEAN_ATTRIBUTES, False),
        ("ec", EMPTY_COLLAPSIBLE_ATTRIBUTES, False),
        ("er", EMPTY_REMOVABLE_ATTRIBUTES, False),
        ("iws_always", INLINE_KEEP_WS_ALWAYS, False),
        ("iws_around", INLINE_KEEP_WS_AROUND, False),
        ("iws_within", INLINE_KEEP_WS_WITHIN, False),
    ]
    found_collision = False
    for set_name, items, case_sensitive in all_sets:
        hash_fn = fnv_hash if case_sensitive else fnv_hash_lowered
        seen = {}
        for item in items:
            h = hash_fn(item)
            if h in seen:
                print(f"COLLISION in {set_name}: {item} and {seen[h]}")
                found_collision = True
            seen[h] = item
    if not found_collision:
        print("// No collisions found")


if __name__ == "__main__":
    main()
