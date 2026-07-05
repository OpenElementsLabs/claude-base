#!/usr/bin/env python3
"""Grade claude-plugin-builder eval runs. Writes grading.json into each run dir."""
import json, os, re, glob

ROOT = os.path.join(os.path.dirname(__file__), "iteration-1")

def find(base, pattern):
    return glob.glob(os.path.join(base, "**", pattern), recursive=True)

def read(path):
    try:
        return open(path, encoding="utf-8", errors="ignore").read()
    except Exception:
        return ""

def all_text(outputs):
    """Concatenate every text file under outputs/ (answers + produced files)."""
    buf = []
    for p in glob.glob(os.path.join(outputs, "**", "*"), recursive=True):
        if os.path.isfile(p):
            buf.append(f"\n\n### {os.path.relpath(p, outputs)}\n" + read(p))
    return "".join(buf)

def manifest_paths(outputs):
    return find(outputs, "plugin.json")

def claude_plugin_dirs(outputs):
    return [os.path.dirname(p) for p in find(outputs, "*")
            if os.path.basename(os.path.dirname(p)) == ".claude-plugin"]

def component_inside_claude_plugin(outputs):
    """True if any component dir/file wrongly sits inside a .claude-plugin/ folder."""
    bad = []
    for p in glob.glob(os.path.join(outputs, "**", ".claude-plugin", "*"), recursive=True):
        name = os.path.basename(p)
        if name != "plugin.json":
            bad.append(os.path.relpath(p, outputs))
    return bad

def plugin_root_of(manifest_path):
    # <root>/.claude-plugin/plugin.json  -> <root>
    return os.path.dirname(os.path.dirname(manifest_path))

def grade_eval0(outputs):
    text = all_text(outputs)
    mps = [p for p in manifest_paths(outputs) if ".claude-plugin" in p]
    res = []

    ok = bool(mps)
    res.append(("plugin.json is placed at .claude-plugin/plugin.json", ok,
                (os.path.relpath(mps[0], outputs) if ok else "no .claude-plugin/plugin.json found")))

    has_name = any('"name"' in read(p) for p in mps)
    res.append(("plugin.json includes a name field (required)", has_name,
                "found \"name\" in a manifest" if has_name else "no name field"))

    # commands/ and agents/ at a plugin root
    roots = [plugin_root_of(p) for p in mps]
    at_root = False
    ev = "no plugin root with commands/ + agents/"
    for r in roots:
        c = os.path.isdir(os.path.join(r, "commands"))
        a = os.path.isdir(os.path.join(r, "agents"))
        if c and a:
            at_root = True
            ev = f"commands/ and agents/ present at {os.path.relpath(r, outputs) or '.'}"
    bad = component_inside_claude_plugin(outputs)
    at_root = at_root and not bad
    if bad:
        ev = f"components wrongly inside .claude-plugin/: {bad}"
    res.append(("commands/ and agents/ directories are at the plugin root, NOT inside .claude-plugin/", at_root, ev))

    mkt = find(outputs, "marketplace.json")
    gh_src = bool(re.search(r'"source"\s*:\s*"github"', text)) or bool(mkt)
    res.append(("A marketplace.json (or a github plugin source) is provided so the plugin can be hosted on GitHub",
                gh_src, (os.path.relpath(mkt[0], outputs) if mkt else "github source in text")))

    add = re.search(r"/plugin\s+marketplace\s+add", text)
    inst = re.search(r"/plugin\s+install\s+\S+@\S+", text) or re.search(r"/plugin\s+install", text)
    ns = re.search(r"/[\w-]+:[\w-]+", text)
    ok5 = bool(add and inst and ns)
    res.append(("Install instructions use /plugin marketplace add <owner/repo> and /plugin install <name>@<marketplace>, and note that plugin skills/commands are namespaced",
                ok5, f"add={bool(add)} install={bool(inst)} namespaced_example={bool(ns)}"))
    return res

def grade_eval1(outputs):
    text = all_text(outputs)
    mps = [p for p in manifest_paths(outputs) if ".claude-plugin" in p]
    res = []

    name_ok = any('db-tools' in read(p) for p in mps)
    res.append(("plugin.json is at .claude-plugin/plugin.json with name db-tools",
                bool(mps) and name_ok, f"manifest={bool(mps)} name db-tools={name_ok}"))

    skills = [p for p in find(outputs, "SKILL.md") if os.sep + "skills" + os.sep in p]
    desc_ok = any(re.search(r"^\s*description\s*:", read(p), re.M) for p in skills)
    res.append(("A skill exists as skills/<name>/SKILL.md with a description in its frontmatter",
                bool(skills) and desc_ok, f"skills/SKILL.md={bool(skills)} has description={desc_ok}"))

    mcp_files = find(outputs, ".mcp.json")
    mcp_inline = any('mcpServers' in read(p) for p in mps)
    runs_index = bool(re.search(r"servers/index\.js", text))
    mcp_ok = (bool(mcp_files) or mcp_inline) and runs_index
    res.append(("An MCP configuration (.mcp.json or mcpServers in plugin.json) is provided that runs servers/index.js",
                mcp_ok, f".mcp.json={bool(mcp_files)} inline={mcp_inline} refs servers/index.js={runs_index}"))

    # ${CLAUDE_PLUGIN_ROOT} used for the server path (in mcp config files or inline manifest)
    cfg_text = "".join(read(p) for p in mcp_files) + "".join(read(p) for p in mps)
    root_var = "${CLAUDE_PLUGIN_ROOT}" in cfg_text
    res.append(("The MCP server command/args path uses ${CLAUDE_PLUGIN_ROOT} instead of an absolute or hard-coded path",
                root_var, "found ${CLAUDE_PLUGIN_ROOT} in MCP config" if root_var else "not found in MCP config"))

    bad = component_inside_claude_plugin(outputs)
    res.append(("All component directories are at the plugin root, not inside .claude-plugin/",
                not bad, "clean" if not bad else f"inside .claude-plugin/: {bad}"))
    return res

def grade_eval2(outputs):
    t = all_text(outputs)
    tl = t.lower()
    res = []
    a1 = "marketplace.json" in tl
    res.append(("Explains the marketplace catalog file at .claude-plugin/marketplace.json", a1,
                "mentions marketplace.json"))
    a2 = "extraknownmarketplaces" in tl and "enabledplugins" in tl
    res.append(("Shows extraKnownMarketplaces (and enabledPlugins) in project .claude/settings.json so teammates are auto-prompted when they trust the repo",
                a2, f"extraKnownMarketplaces={'extraknownmarketplaces' in tl} enabledPlugins={'enabledplugins' in tl}"))
    a3 = ("bump" in tl or "bumped" in tl) and "version" in tl
    res.append(("States that an explicit version in plugin.json must be bumped on every release or users won't receive updates",
                a3, "mentions bumping version"))
    a4 = ("sha" in tl or "commit" in tl) and ("omit" in tl or "without" in tl or "leave" in tl or "no version" in tl or "unset" in tl)
    res.append(("Given frequent pushes, recommends omitting version so the git commit SHA is used and every commit counts as an update",
                a4, "discusses commit-SHA / omitting version"))
    a5 = "marketplace update" in tl or "auto-update" in tl or "auto update" in tl
    res.append(("Mentions /plugin marketplace update (or auto-update) to refresh the marketplace", a5,
                "mentions update/auto-update"))
    return res

GRADERS = {
    "eval-0-convert-claude-to-plugin": grade_eval0,
    "eval-1-build-mcp-skill-plugin": grade_eval1,
    "eval-2-marketplace-and-versioning": grade_eval2,
}

for eval_dir, grader in GRADERS.items():
    for cfg in ("with_skill", "without_skill"):
        outputs = os.path.join(ROOT, eval_dir, cfg, "outputs")
        if not os.path.isdir(outputs):
            continue
        graded = grader(outputs)
        exps = [{"text": t, "passed": bool(p), "evidence": e} for (t, p, e) in graded]
        passed = sum(1 for x in exps if x["passed"])
        total = len(exps)
        out = {
            "expectations": exps,
            "summary": {"passed": passed, "failed": total - passed, "total": total,
                        "pass_rate": round(passed / total, 2) if total else 0},
        }
        dest = os.path.join(ROOT, eval_dir, cfg, "grading.json")
        json.dump(out, open(dest, "w"), indent=2)
        print(f"{eval_dir:38s} {cfg:14s} {passed}/{total}")
        for x in exps:
            print(f"    [{'PASS' if x['passed'] else 'FAIL'}] {x['text'][:70]}  <- {x['evidence'][:60]}")
