#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema

internal_app_path="Internal/Debug App"

if [[ $1 = "is_ci" ]]; then
  tuist generate --path "$internal_app_path" --no-open
else
  tuist generate --path "$internal_app_path"
  (cd "$internal_app_path" && pod install)
fi
