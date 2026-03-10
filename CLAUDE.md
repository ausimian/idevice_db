# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IDeviceDb is an Elixir library providing a queryable database of Apple devices (iPhones, iPads). Data is sourced from The Apple Wiki and stored as JSON in `priv/devices.json`. On module load, it's read into Erlang persistent terms for fast, zero-copy access.

## Common Commands

- **Build:** `mix compile` (enforces `mix format --check-formatted` and `--warnings-as-errors` via alias)
- **Test:** `mix test`
- **Single test by line:** `mix test test/idevice_db_test.exs:42`
- **Format:** `mix format`
- **Regenerate device database:** `mix generate_db` (scrapes The Apple Wiki)
- **Generate docs:** `mix docs`

## Architecture

The library has two main components:

**`lib/idevice_db.ex`** — The entire public API. Uses `@on_load :init` to read `priv/devices.json` at module load time and build several indexed maps stored in `:persistent_term`:
- `all_devices` — full device list
- `devices_by_model` — model code → device map
- `identifiers` — device identifier → generation name
- `ranked_generations`, `ranked_identifiers`, `ranked_models` — chronological rank maps for sorting comparisons

Each device record includes: `finish`, `identifier`, `models`, `generation`, `internal_name`, `storage`, `family` (atom: `:iPhone`, `:iPad`, `:iPadAir`, `:iPadPro`, `:iPadMini`).

**`lib/idevice_db/mix/tasks/generate_db.ex`** — Mix task that scrapes The Apple Wiki HTML tables using `Req` and `Floki`, handles rowspan merging, and writes `priv/devices.json`. Only compiled in dev/test (`elixirc_paths(:prod)` excludes it).

## Key Build Details

- Elixir ~> 1.15, tested against OTP 26.2 and 27.2
- Production dependency: only `jason`
- Dev/test dependencies: `req`, `floki`, `ex_doc`
- CI runs in `MIX_ENV=prod`, which compiles only `lib/idevice_db.ex`
- Version is derived from: hex metadata → GitHub tag → `git describe`
