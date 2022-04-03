#!/bin/bash
#
# Script for generating SQL INSERTs using Synth and rules from synth/ directory
#
# Author: Michal ŠMAHEL (xsmahe01)
# Date: April 2022

# Converts value to lowercase
# Input: ... lower(VaLuE) ...
# Output: ... value ...
function lower() {
  sed -E 's/lower\((.+)\)/\L\1/g'
}

# Increments value
# Input: ... inc(11) ...
# Output: ... 12 ...
function inc() {
  sed -E 's/(.*)inc\(([0-9]+)\)(.*)/echo "\1$((\2+1))\3"/ge'
}

# Applies custom functions for processing values
function custom_functions() {
  lower | inc
}

# Parses generated data in line JSON into CSV
last_table=""
function parse() {
  while read line; do
    table=$(echo "$line" | jq -r '.[]' | tail -n 1)
    keys=$(echo "$line" | jq -r 'keys[]' | grep -vE "^type$")
    values=$(echo "$line" | jq '.[]' | grep -vE "^\"$table\"$")

    # Constructing data for SQL query
    # Column names are encapsulated due to name collusion prevention (with built-in types)
    columns=$(echo "$keys" | sed -E 's/(.+)/"\1"/' | tr '\n' ',' | sed 's/,$//g' | sed 's/,/, /g' | sed "s/'//")
    data=$(echo "$values" | tr '\n' ',' | sed 's/,$//g' | sed 's/,/, /g' | tr '"' "'" | custom_functions)

    # Dividing inserts by the table and adding simple human readable header
    if [[ $table != "$last_table" ]]; then
      # New line after queries
      # When no table has been processed yet, last_table is empty
      if [[ -n $last_table ]]; then
        echo ""
      fi

      # Name of the table (header)
      echo "-- $table" | sed -E 's/([a-z])/\U\1/' | sed 's/_/ /g'

      last_table=$table
    fi

    # Construct SQL query
    # Table name is encapsulated due to name collision prevention (with built-in types)
    echo "INSERT INTO \"$table\" ($columns)"
    echo "VALUES ($data)"
  done
}

# Phase 1
#synth generate --to json:./generated/phase-1.json ./synth/phase-1 --random

# Phase 2
#synth generate --to json:./generated/phase-2.json ./synth/phase-2 --random

# Phase 3
synth generate --to jsonl: ./synth/phase-5 --random

#synth generate --to jsonl: ./synth --random | parse
