---
paths:
  - "**/*.strings"
---

# Localization Rules

Add, change or fix strings with the `translate` skill (plugin `primer-core` from the primer-claude
marketplace). It covers the language list, placeholders, brand names, Serbian Latin script, Armenian and
back-translating legal text. CI runs `Scripts/check_translations.py` on pull requests to `master`
and `bn/feature/checkout-components`; run it locally before committing (command in the root
`CLAUDE.md`).

Catalogs:

- CheckoutComponents: `Modules/PrimerResources/Sources/PrimerResources/Resources/CheckoutComponentsLocalizable/{lang}.lproj/CheckoutComponentsStrings.strings`
- Drop-in / Headless: `Modules/PrimerResources/Sources/PrimerResources/Resources/Localizable/{lang}.lproj/Localizable.strings`
