#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema

if [[ $1 = "is_ci" ]]; then
  tuist generate --path "Example" --no-open
else
  tuist generate --path "Example"
fi

(cd "Example" && pod install)
