// Notchy plugin for opencode.
// Translates opencode events into the payloads Claude Code hooks send and pipes them to
// notchy-hook, so both agents share one status format, one lock and one Terminal lookup.
import { spawn } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

const HOOK = join(homedir(), ".notchy", "bin", "notchy-hook")

// opencode tool name -> the Claude Code name notchy-hook knows how to describe.
const TOOL_NAMES = {
  bash: "Bash",
  read: "Read",
  write: "Write",
  edit: "Edit",
  multiedit: "MultiEdit",
  glob: "Glob",
  grep: "Grep",
  webfetch: "WebFetch",
  websearch: "WebSearch",
  task: "Task",
  todowrite: "TodoWrite",
  question: "AskUserQuestion",
  plan_exit: "ExitPlanMode",
}

function claudeTool(tool, args = {}) {
  const input = { ...args, file_path: args.filePath }
  if (tool === "todowrite") {
    // Notchy hides "deleted" tasks; opencode calls the same thing "cancelled".
    input.todos = (args.todos ?? []).map((t) => ({ ...t, status: t.status === "cancelled" ? "deleted" : t.status }))
  }
  return { tool_name: TOOL_NAMES[tool] ?? tool, tool_input: input }
}

function runHook(payload) {
  return new Promise((resolve) => {
    const child = spawn(HOOK, [], { stdio: ["pipe", "ignore", "ignore"] })
    child.on("error", resolve) // Notchy not installed: stay silent.
    child.on("close", resolve)
    child.stdin.on("error", () => {})
    child.stdin.end(JSON.stringify(payload))
  })
}

export const NotchyPlugin = async ({ client, directory }) => {
  // Subagent (task) sessions have a parent; only top-level sessions get a dot.
  const isRoot = new Map()
  function checkRoot(id) {
    if (!isRoot.has(id)) {
      isRoot.set(
        id,
        client.session
          .get({ path: { id } })
          .then((res) => !res.data?.parentID)
          .catch(() => true),
      )
    }
    return isRoot.get(id)
  }

  async function lastAssistantText(id) {
    const res = await client.session.messages({ path: { id } }).catch(() => null)
    for (const { info, parts } of [...(res?.data ?? [])].reverse()) {
      if (info.role !== "assistant") continue
      const text = parts
        .filter((p) => p.type === "text" && !p.synthetic)
        .map((p) => p.text)
        .join(" ")
        .trim()
      if (text) return text
    }
  }

  // Run hooks one at a time, in order, without making opencode wait for them.
  let queue = Promise.resolve()
  function send(sessionID, event, extra = () => ({})) {
    queue = queue
      .then(async () => {
        if (!(await checkRoot(sessionID))) return
        await runHook({ session_id: sessionID, hook_event_name: event, cwd: directory, ...(await extra()) })
      })
      .catch(() => {})
  }

  return {
    "chat.message": async (input, output) => {
      const prompt = output.parts
        .filter((p) => p.type === "text" && !p.synthetic)
        .map((p) => p.text)
        .join(" ")
      send(input.sessionID, "UserPromptSubmit", () => ({ prompt }))
    },

    "tool.execute.before": async (input, output) => {
      send(input.sessionID, "PreToolUse", () => claudeTool(input.tool, output.args))
    },

    "tool.execute.after": async (input) => {
      send(input.sessionID, "PostToolUse", () => claudeTool(input.tool, input.args))
    },

    event: async ({ event }) => {
      const props = event.properties
      switch (event.type) {
        case "session.created":
          isRoot.set(props.info.id, Promise.resolve(!props.info.parentID))
          send(props.info.id, "SessionStart")
          break
        case "session.deleted":
          send(props.info.id, "SessionEnd")
          break
        case "permission.asked": {
          const target = (props.patterns ?? []).join(" ")
          const args = { command: target, filePath: target, url: target, pattern: target }
          send(props.sessionID, "PermissionRequest", () => claudeTool(props.permission, args))
          break
        }
        case "permission.replied":
          // Back to working; the following idle event marks it done if the user rejected.
          send(props.sessionID, "PostToolUse", () => ({ tool_name: "" }))
          break
        case "session.idle":
          send(props.sessionID, "Stop", async () => ({ last_assistant_message: await lastAssistantText(props.sessionID) }))
          break
      }
    },
  }
}
