---
name: translate
description: Add and translate new localization strings across all 60 languages
disable-model-invocation: true
argument-hint: "[key = \"English value\"]"
---

Add and translate: $ARGUMENTS

## Workflow

1. **Parse input**: Extract the key and English value from arguments
2. **Determine target**: Ask the user if unclear:
   - **CheckoutComponents**: `Sources/PrimerSDK/Resources/CheckoutComponentsLocalizable/{lang}.lproj/CheckoutComponentsStrings.strings`
   - **SDK (Drop-In/Headless)**: `Sources/PrimerSDK/Resources/Localizable/{lang}.lproj/Localizable.strings`
3. **Add English string**: Add `"key" = "English value";` to `en.lproj`
4. **Translate to all 60 languages**: Translate the English value and add to each `.lproj` file:
   ar, az, bg, bs, ca, cs, da, de, el, en, es-AR, es-MX, es, et, fa, fi, fil, fr, he, hi, hr, hu, hy, id, it, ja, ka, kk, ko, ku, ky, lt, lv, mk, ms, nb, nl-BE, nl, pl, pt-BR, pt, ro, ru, sk, sl, sq, sr, sv, th, tr, uk, ur-PK, uz, vi, zh-CN, zh-HK, zh-TW
5. **Armenian (hy) — special handling**: Use Python Unicode escape script per `.claude/rules/localization.md` — never write Armenian characters directly
6. **Verify**: Confirm all 60 language files contain the new key
