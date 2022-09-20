#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema
tuist generate --path "Example"

if [[ $1 != "is_ci" ]]; then
    # Install pod for the Example App
    (cd "Example" && pod install)
fi
