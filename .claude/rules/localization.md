---
paths:
  - "**/*.strings"
---

# Localization Rules

Add, change or fix strings with the `translate` skill (plugin `primer-core` from the primer-claude
marketplace). It covers the language list, placeholders, brand names, Serbian Latin script and
back-translating legal text. CI runs `Scripts/check_translations.py` on every PR; run it locally
before committing (command in the root `CLAUDE.md`).

Catalogs:

- CheckoutComponents: `Modules/PrimerResources/Sources/PrimerResources/Resources/CheckoutComponentsLocalizable/{lang}.lproj/CheckoutComponentsStrings.strings`
- Drop-in / Headless: `Modules/PrimerResources/Sources/PrimerResources/Resources/Localizable/{lang}.lproj/Localizable.strings`

## Armenian (hy) Translation Note
When translating strings to Armenian, do NOT write Armenian characters directly in the code/tool output as they may get corrupted. Instead, use a Python script with Unicode escape sequences:

```python
python3 << 'PYEOF'
# Armenian translations using Unicode escape sequences
translations = {
    "primer_ach_title": "\u0532\u0561\u0576\u056f\u0561\u0575\u056b\u0576 \u0570\u0561\u0577\u056b\u057e",
    "primer_ach_button_continue": "\u0547\u0561\u0580\u0578\u0582\u0576\u0561\u056f\u0565\u056c",
    # ... add more translations
}

import re
file_path = 'Modules/PrimerResources/Sources/PrimerResources/Resources/CheckoutComponentsLocalizable/hy.lproj/CheckoutComponentsStrings.strings'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

for key, value in translations.items():
    content = re.sub(f'"{key}" = "[^"]*";', f'"{key}" = "{value}";', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF
```

Common Armenian Unicode escape sequences:
- Bank account = \u0532\u0561\u0576\u056f\u0561\u0575\u056b\u0576 \u0570\u0561\u0577\u056b\u057e
- Continue = \u0547\u0561\u0580\u0578\u0582\u0576\u0561\u056f\u0565\u056c
- Cancel = \u0549\u0565\u0572\u0561\u0580\u056f\u0565\u056c
- Permission = \u0539\u0578\u0582\u0575\u056c\u0561\u057f\u057e\u0578\u0582\u0569\u0575\u0578\u0582\u0576
- I agree = \u0540\u0561\u0574\u0561\u0571\u0561\u0575\u0576 \u0565\u0574
