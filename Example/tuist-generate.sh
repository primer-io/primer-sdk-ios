#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema
tuist generate --path "Example"

(cd "Example" && pod install)
