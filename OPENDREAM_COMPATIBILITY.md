# Bastion Station on OpenDream

This experimental branch contains the Bastion-side changes used to run the game on a modified OpenDream engine. It is based on original Bastion commit `01bd1c1a5429a8ebf49ef66f1bb943da998d2356` and is published as `opendream-compat` in Bob0o9's fork. The fork's `master` may contain newer upstream work; this branch has not been rebased onto or tested with those updates.

**This repository is only the game-side portion of the port.** Stock OpenDream and the VS Code extension's automatically downloaded engine are not sufficient for the tested setup. The matching [OpenDream](https://github.com/Bob0o9/OpenDream) and [RobustToolbox](https://github.com/Bob0o9/RobustToolbox) development copies are private. You need explicit read access to both before cloning/building them; this public game branch does not grant that access.

## Tested engine revisions

| Component | Revision |
| --- | --- |
| OpenDream | `34bab0aad7540299295f87bf7713c5a873346f2f` |
| RobustToolbox submodule | `5d337bd2de84cd086c0f23d072224857176a0d9e` |

Both private repositories use `opendream-compat` as their default branch. On November 17, 2026, the runtime code at OpenDream `ad0fcccd` with Bastion compatibility code `e3a649927b0` passed both engine builds, all 787 unit tests, and the connected regression suite. The newer revision above retains that runtime code and repairs dependency packaging; its three fragment-budget regression tests pass. Later documentation-only commits may follow these revisions. Local gameplay checks cover working standard camera feeds and restored clothing colors; complete BYOND compatibility and multiplayer stability remain unverified. These engine changes are not available in upstream releases.

Use the current `opendream-compat` branch when cloning: the RobustToolbox pin above packages the existing Lidgren fix without an unpublished nested dependency. The original tested engine revision used the same networking limit through a local-only Lidgren commit; that older dependency pin cannot be fetched by a fresh recursive clone. Access to the same two private repositories is sufficient.

The repaired dependency packaging passed a fresh recursive submodule checkout, package restore, and server/client/compiler Tools builds with .NET SDK 10.0.302. Existing failed clones can be repaired using the commands in the private engine's compatibility guide.

Most compatibility fixes live in OpenDream/RobustToolbox: DM execution, sprite/lighting rendering, inventory replication, input, browser integration, sight flags, maptext, and delivery of HUD animation events.

## What this branch changes

| Area | Game-side change |
| --- | --- |
| Associative lists | Remove the obsolete `OPENDREAM` macro that replaced `alist` with ordinary `list`. The patched compiler/runtime implements native associative-list semantics. |
| Startup | Defer client admission until Bastion's asynchronous subsystem initialization finishes, using `ODDeferClientAdmission()` and `ODAllowClientAdmission()`. |
| Early errors | Guard an uninitialized static regex in the runtime error handler. |
| Chat | Start chat sequence numbers at zero rather than interpolating null into JSON. |
| Legacy stat panel | Supply the missing spell-tab cleanup function and clear its stale arrays. |
| TGUI updates | Let the existing window queue retain updates produced before its opening handshake finishes. |
| Uplink | Correct nuclear-ops no-slip chameleon shoes' inherited metadata while retaining their original category; provide generated colored/GAGS preview sprites for normal and discounted entries. |
| Inventory previews | Under `OPENDREAM`, clear the hovered equipment preview when held items change, and unregister its signal when the preview or HUD is removed. |
| Developer tools | Build the sibling patched OpenDream server/client sequentially in Tools configuration, then compile Bastion with its expected build defines. |

This branch also includes optional UI/appearance improvements, rather than strictly necessary engine compatibility work: fitting the viewport after resizing, keeping chat tabs/settings reachable, sizing chat against its current pane, and making observers about 85% transparent. These are separate commits and can be reviewed or omitted independently. The original upstream code and asset licenses remain in effect.

## Local development setup

The tested platform is Windows x64. Install Git, the .NET SDK required by OpenDream's `global.json` (10.0.100 with its configured roll-forward policy), and Bastion's frontend/native dependencies. `dependencies.sh` is the project's dependency reference: the tested frontend uses Bun 1.3.6 and the native library is Monkestation/rust-g 7.0.0 (`rust_g64.dll` in the Bastion root on Windows). Follow upstream setup instructions for other dependencies; installing BYOND alone does not supply the patched OpenDream client.

Use sibling directories named `Bastion-Station` and `OpenDream`. After gaining access to both private engine repositories, clone OpenDream with `--branch opendream-compat --recurse-submodules`; its submodule URL points to the matching private RobustToolbox copy. Build from the OpenDream directory:

```powershell
dotnet restore
dotnet build OpenDreamServer/OpenDreamServer.csproj -c Tools --no-restore --disable-build-servers
dotnet build OpenDreamClient/OpenDreamClient.csproj -c Tools --no-restore --disable-build-servers
```

Stop existing game processes before rebuilding binaries. Initialize the engine's recursive submodules using the published fork URLs once those forks are available.

Build the frontend from `Bastion-Station/tgui`:

```powershell
bun install --frozen-lockfile
bun run tgui:build
```

From `Bastion-Station`, compile the game:

```powershell
../OpenDream/bin/DMCompiler/DMCompiler.exe --version=516.1687 --define=CBT tgstation.dme
```

`CBT` is Bastion's regular build define; omitting it can select mapper-preview icon states instead of runtime states. Generated frontend bundles, compiled world output, native libraries, saves, and local server configuration are not distributed through this source branch.

From the OpenDream `bin/Content.Server` directory, start the server:

```powershell
./OpenDreamServer.exe --cvar net.port=1212 --cvar opendream.always_show_exceptions=true --cvar opendream.json_path=../../../Bastion-Station/tgstation.json
```

Wait for `Initializations complete` in the server output. From `bin/Content.Client`, connect with the matching client:

```powershell
./OpenDreamClient.exe --connect --connect-address 127.0.0.1:1212 --username TestPlayer
```

The patched engine also has `Tools/Prepare-ResourcePack.ps1` and `Tools/Start-PreloadedClient.ps1` for preloading matching game resources. See that engine's `Tools/ResourcePacks.md`; rebuild and verify the pack after changing the compiled world/assets. Preloading is optional and the normal VS Code F5 launch does not automatically mount it.

## Status and limitations

Local testing has exercised lobby/round entry, observer movement and roles, portable lights, thermals, chat/TGUI, inventory, and shuttle navigation. This is not complete SS13 feature coverage or evidence of multi-player/network stability. BYOND clients cannot connect to an OpenDream server.

Known follow-ups include browser asset-cache warnings, unsupported multichannel audio, and input arriving before a client's startup admission completes. Native `world.Reboot()` currently shuts the OpenDream server down without relaunching it; use an external process restart for a new round. The three-second splash fade has an engine-side connected regression test, but still needs a real round-start visual retest.

No runnable release or public game server is included with this branch. When reporting a problem, include the game and engine revisions, reproduction steps, and relevant logs with account details, tokens, and private configuration removed.
