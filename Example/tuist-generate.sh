#!/bin/sh

# Generate Example App project structure
# via Tuist and Project.swift schema
tuist generate

# Install pod for the Example App
pod install
