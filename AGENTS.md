# fsemver — agent instructions

Semver requirement parser and matcher for VitaSound Forth tooling (`~>`, `>=`, …).

## Before commit

After editing `.4th` files, run this sequence **before creating a git commit**:

1. **`fmix test`** — unit tests must pass.
2. **`flint`** — duplicate-word lint across project sources and `forth-packages/`.
3. **`fcov run fmix test`** then **`fcov report`** — definition coverage during tests.

### flint

- **Role:** scans all `*.4th` under the repo; reports duplicate `: word` definitions (including vendored deps).
- **Exit code:** always 0 (warn-only tool).
- **Agent rule:** read output for `[WARN]` lines; do not commit new duplicate definitions in **project** code. Warnings inside `forth-packages/` are often expected — note them, fix only if this repo owns the duplicate.
- **Version pin:** `key-value flint ~> 0.2` in `package.4th` (mismatch → `[WARN]`, lint still runs).

Shell: `flint` from repo root (needs `flint` on `PATH`, see [flint](https://github.com/VitaSound/flint)).

### fcov

- **Role:** instruments word definitions, runs tests, writes `.fcov/coverage.json` and console report.
- **Command:** `fcov run fmix test` then `fcov report` (or `fcov report --format json`).
- **Agent rule:** tests must pass under fcov; review coverage % and uncovered project words when changing public API.
- **Version pin:** `key-value fcov ~> 0.3` in `package.4th`.
- **Artifacts:** `.fcov/` is gitignored — never commit it.

Shell: `fcov` from repo root (needs `fcov` on `PATH`, see [fcov](https://github.com/VitaSound/fcov)).

### MCP equivalents (preferred)

| Step | MCP tool |
|------|----------|
| Tests | `fmix_test` |
| Lint | `flint_lint` |
| Coverage | `fcov_run` (`test_command`: `fmix test`) → `fcov_report` |

Do **not** skip flint/fcov before commit when MCP **vitasound-forth** is connected.

## Quality workflow

```text
fmix packages.get   # if package.4th or deps changed
fmix test
flint
fcov run fmix test && fcov report
```

MCP order: `fmix_packages_get` → `fmix_test` → `flint_lint` → `fcov_run` → `fcov_report`.

## MCP (preferred for agents)

Cursor MCP server: **`vitasound-forth`** (stdio bridge: [fmcp](https://github.com/VitaSound/fmcp)).

Use MCP tools instead of shell when the server is connected (Settings → MCP → vitasound-forth).

| MCP tool | Task |
|----------|------|
| `fmix_packages_get` | `forth-packages/` after clone or deps change |
| `fmix_test` | unit tests (step 1 before commit) |
| `flint_lint` | duplicate-word lint (step 2 before commit) |
| `fcov_run` / `fcov_report` | coverage (step 3 before commit) |
| `mcp_ping` | health check between batch calls |

`project_root` = absolute path to **this** repo (e.g. `/home/sea/fsemver`).

Full tool list, batch tips, troubleshooting: [fmcp/AGENTS.md](https://github.com/VitaSound/fmcp/blob/main/AGENTS.md).  
`mcp.json` setup: [fmcp/README.md](https://github.com/VitaSound/fmcp/blob/main/README.md#cursor-mcpjson).
