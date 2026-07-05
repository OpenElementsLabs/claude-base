#!/usr/bin/env node
/**
 * db-tools MCP server.
 *
 * A minimal Model Context Protocol server (stdio transport) exposing database
 * helper tools to Claude Code. This is a stub: wire up your real database
 * driver where the TODO markers are.
 *
 * Install deps in the plugin root before use:
 *   npm install @modelcontextprotocol/sdk
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const DATABASE_URL = process.env.DATABASE_URL ?? "";

const server = new Server(
  {
    name: "db-tools",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const TOOLS = [
  {
    name: "run_query",
    description:
      "Execute a read-only SQL query against the configured database and return the rows.",
    inputSchema: {
      type: "object",
      properties: {
        sql: {
          type: "string",
          description: "A read-only SQL statement (SELECT / SHOW / EXPLAIN).",
        },
      },
      required: ["sql"],
    },
  },
  {
    name: "list_tables",
    description: "List the tables available in the connected database schema.",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "describe_table",
    description: "Return the column definitions for a given table.",
    inputSchema: {
      type: "object",
      properties: {
        table: {
          type: "string",
          description: "The name of the table to describe.",
        },
      },
      required: ["table"],
    },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: TOOLS,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (!DATABASE_URL) {
    return {
      isError: true,
      content: [
        {
          type: "text",
          text: "DATABASE_URL is not set. Configure it in the plugin's .mcp.json env or your environment.",
        },
      ],
    };
  }

  switch (name) {
    case "run_query": {
      // TODO: connect using your driver (e.g. pg, mysql2, better-sqlite3),
      // enforce read-only, run args.sql, and return the rows.
      return {
        content: [
          {
            type: "text",
            text: `[stub] would run query: ${args?.sql ?? ""}`,
          },
        ],
      };
    }
    case "list_tables": {
      // TODO: query the information schema for table names.
      return {
        content: [{ type: "text", text: "[stub] would list tables" }],
      };
    }
    case "describe_table": {
      // TODO: query the information schema for columns of args.table.
      return {
        content: [
          {
            type: "text",
            text: `[stub] would describe table: ${args?.table ?? ""}`,
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
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // Log to stderr only — stdout is reserved for the MCP protocol.
  console.error("db-tools MCP server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error starting db-tools MCP server:", error);
  process.exit(1);
});
