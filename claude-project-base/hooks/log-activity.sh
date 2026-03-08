#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // empty')
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
echo "$TIMESTAMP [$TOOL] $TOOL_INPUT" >> claude.log
exit 0
