/**
 * Script to replace "var(--varname) * NUMBER" with "calc(var(--varname) * NUMBER)"
 * in a swift file.
 */

import fs from 'fs';
import path from 'path';

// Grab arguments
const [, , inputFile, outputFile] = process.argv;

if (!inputFile || !outputFile) {
  console.error('Usage: node improve-swift-variables.js <input-file> <output-file>');
  process.exit(1);
}

// Read the input .swift file
let fileContent = fs.readFileSync(inputFile, 'utf8');

// Use a regex to match patterns like: var(--some-var) * 2.00 (with optional spacing)
const pattern = /(var\(--[^)]+\))\s*\*\s*([\d.]+)/g;

// Replace with calc(...)
fileContent = fileContent.replace(pattern, 'calc($1 * $2)');

// Write out the transformed content to the output file
fs.writeFileSync(outputFile, fileContent, 'utf8');

console.log(
  `Successfully replaced multiplications with calc() functions in ${path.resolve(inputFile)} and wrote to ${path.resolve(outputFile)}`,
);