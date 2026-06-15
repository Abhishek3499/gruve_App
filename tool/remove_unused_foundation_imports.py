#!/usr/bin/env python3
"""Remove unused flutter/foundation.dart imports after AppLogger migration."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FOUNDATION_IMPORT = re.compile(
    r"^import 'package:flutter/foundation\.dart';\n",
    re.MULTILINE,
)


def still_needs_foundation(content: str) -> bool:
    symbols = [
        "kDebugMode",
        "kReleaseMode",
        "kProfileMode",
        "defaultTargetPlatform",
        "TargetPlatform",
        "visibleForTesting",
        "protected",
        "immutable",
        "mustCallSuper",
        "optionalTypeArgs",
        "required",
        "Deprecated",
        "Category",
        "Documentation",
        "Summary",
        "factory",
        "Foundation",
    ]
    for symbol in symbols:
        if re.search(rf"\b{re.escape(symbol)}\b", content):
            return True
    return False


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if "app_logger.dart" in str(path):
            continue
        text = path.read_text(encoding="utf-8")
        if "package:flutter/foundation.dart" not in text:
            continue
        if still_needs_foundation(text):
            continue
        new_text = FOUNDATION_IMPORT.sub("", text)
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            changed += 1
            print(f"removed foundation import: {path.relative_to(ROOT)}")
    print(f"\nDone. {changed} files updated.")


if __name__ == "__main__":
    main()
