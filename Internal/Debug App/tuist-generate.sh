#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema

if [[ $1 = "is_ci" ]]; then
  tuist generate --path "Internal/Debug App" --no-open
else
  tuist generate --path "Internal/Debug App"
  (cd "Example" && pod install)
fi
