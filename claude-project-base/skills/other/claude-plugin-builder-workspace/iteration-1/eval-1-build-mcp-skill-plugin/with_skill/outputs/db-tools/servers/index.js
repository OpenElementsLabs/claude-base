#!/usr/bin/env node
/**
 * db-tools MCP server (stub).
 *
 * A minimal Model Context Protocol server bundled with the db-tools plugin.
 * It speaks MCP over stdio and exposes a couple of illustrative database
 * tools. Replace the tool implementations with real database access for your
 * environment.
 *
 * The plugin's .mcp.json launches this file via:
 *   node ${CLAUDE_PLUGIN_ROOT}/servers/index.js
 *
 * Reference implementation using the official SDK:
 *   npm install @modelcontextprotocol/sdk
 *
 * To keep this stub dependency-free it implements the JSON-RPC framing by hand.
 * Swap in the SDK (McpServer + StdioServerTransport) for production use.
 */

"use strict";

const DATABASE_URL = process.env.DATABASE_URL || "";

const TOOLS = [
  {
    name: "list_tables",
    description: "List the tables available in the connected database.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "run_query",
    description:
      "Run a read-only SQL query against the connected database and return the rows.",
    inputSchema: {
      type: "object",
      properties: {
        sql: {
          type: "string",
          description: "A single read-only SQL statement (SELECT ...).",
        },
      },
      required: ["sql"],
      additionalProperties: false,
    },
  },
];

function callTool(name, args) {
  // TODO: replace these stubs with real database access using DATABASE_URL.
  switch (name) {
    case "list_tables":
      return {
        content: [
          {
            type: "text",
            text: DATABASE_URL
              ? "list_tables stub: connect to DATABASE_URL and return real table names here."
              : "No DATABASE_URL configured. Set the DATABASE_URL environment variable.",
          },
        ],
      };
    case "run_query": {
      const sql = (args && args.sql) || "";
      if (!/^\s*select\b/i.test(sql)) {
        return {
          isError: true,
          content: [
            { type: "text", text: "run_query only accepts read-only SELECT statements." },
          ],
        };
      }
      return {
        content: [
          {
            type: "text",
            text: `run_query stub: would execute against DATABASE_URL:\n${sql}`,
          },
        ],
      };
    }
    default:
      return {
        isError: true,
        content: [{ type: "text", text: `Unknown tool: ${name}` }],
      };
  }
}

function handle(request) {
  const { id, method, params } = request;

  switch (method) {
    case "initialize":
      return {
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "db-tools", version: "1.0.0" },
        },
      };
    case "notifications/initialized":
      return null; // notification, no response
    case "tools/list":
      return { jsonrpc: "2.0", id, result: { tools: TOOLS } };
    case "tools/call": {
      const result = callTool(params && params.name, params && params.arguments);
      return { jsonrpc: "2.0", id, result };
    }
    case "ping":
      return { jsonrpc: "2.0", id, result: {} };
    default:
      if (id === undefined) return null; // unknown notification
      return {
        jsonrpc: "2.0",
        id,
        error: { code: -32601, message: `Method not found: ${method}` },
      };
  }
}

// --- Minimal stdio JSON-RPC loop (newline-delimited JSON) ---
let buffer = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buffer += chunk;
  let newlineIndex;
  while ((newlineIndex = buffer.indexOf("\n")) !== -1) {
    const line = buffer.slice(0, newlineIndex).trim();
    buffer = buffer.slice(newlineIndex + 1);
    if (!line) continue;
    let request;
    try {
      request = JSON.parse(line);
    } catch (err) {
      continue;
    }
    const response = handle(request);
    if (response) process.stdout.write(JSON.stringify(response) + "\n");
  }
});

process.stdin.on("end", () => process.exit(0));
