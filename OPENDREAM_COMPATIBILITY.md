# Bastion Station on OpenDream

This experimental branch contains the Bastion-side changes used to run the game on a modified OpenDream engine. It is based on upstream Bastion commit `2aaf38c8cd108159269e05d4277b9d63060a5c18` and is published as `opendream-compat` in Bob0o9's fork. On November 18, 2026, all 23 existing compatibility commits were rebased from the original `01bd1c1a5429a8ebf49ef66f1bb943da998d2356` baseline, bringing in 95 upstream commits without changing the compatibility patches.

**This repository is only the game-side portion of the port.** Stock OpenDream and the VS Code extension's automatically downloaded engine are not sufficient for the tested setup. The matching [OpenDream](https://github.com/Bob0o9/OpenDream) and [RobustToolbox](https://github.com/Bob0o9/RobustToolbox) development copies are private. You need explicit read access to both before cloning/building them; this public game branch does not grant that access.

## Tested engine revisions

| Component | Revision |
| --- | --- |
| OpenDream | `5e3c84822442cf6d3a2eb3e20ccea052cde645e1` |
| RobustToolbox submodule | `4aa574420a33cac3c039eed07d5b2e73f1da1f4a` |

Both private repositories use `opendream-compat` as their default branch. On November 18, 2026, the rebased game compiled successfully, all three TGUI bundles built, both engine builds passed, all 802 unit tests passed, and the connected regression suite passed. A fresh server completed initialization in 182.2 seconds and admitted the client; TGUI Say, the changelog and game preferences were checked. The talk box now honors frameless options even though its window already exists in the skin. Rebuild the matching server and client together. These checks do not replace full gameplay testing of the upstream changes. Earlier gameplay checks cover working standard camera feeds, restored clothing colors, delivery-bin flaps and corrected portable-light blending; complete BYOND compatibility and multiplayer stability remain unverified. These engine changes are not available in upstream releases.

Use the current `opendream-compat` branch when cloning: the RobustToolbox pin above packages the existing Lidgren fix without an unpublished nested dependency. The original tested engine revision used the same networking limit through a local-only Lidgren commit; that older dependency pin cannot be fetched by a fresh recursive clone. Access to the same two private repositories is sufficient.

The repaired dependency packaging passed a fresh recursive submodule checkout, package restore, and server/client/compiler Tools builds with .NET SDK 10.0.302. Existing failed clones can be repaired using the commands in the private engine's compatibility guide.

### Existing clones after the November 18 rebase

The game branch's history changed, so an older checkout cannot update with a
fast-forward pull. Preserve any local work first. A fresh clone uses the same
commands as before. Alternatively, fetch and create a new local branch at the
updated remote branch, leaving the old branch available for comparison:

```powershell
git fetch origin
git switch -c opendream-compat-updated origin/opendream-compat
```

OpenDream and RobustToolbox were updated normally and do not require a history
reset. Pull OpenDream and update its recursive submodules before rebuilding.

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

This branch also includes optional UI/appearance improvements, rather than strictly necessary engine compatibility work: fitting the viewport after resizing, keeping chat tabs/settings reachable, and sizing chat against its current pane. These are separate commits and can be reviewed or omitted independently. The earlier observer-alpha override was removed after the November 19 engine compositing correction; observers now use Bastion's original sprite transparency. The original upstream code and asset licenses remain in effect.

## Local development setup

The November 19 engine follow-up corrects translucent ambient shadows, which
made station gas look too opaque, and releases wildcard key handlers on focus
loss. The station gas correction was confirmed against a native BYOND build
of the same current game source. The engine passed 810 unit tests and its
connected regression test; the game compiled with both OpenDream and BYOND.

The tested platform is Windows x64. Install Git, the .NET SDK required by OpenDream's `global.json` (10.0.100 with its configured roll-forward policy), and Bastion's frontend/native dependencies. `dependencies.sh` is the project's dependency reference: the frontend specifies Node.js 24.12.0 and Bun 1.3.6, and the native library is Monkestation/rust-g 7.0.0 (`rust_g64.dll` in the Bastion root on Windows). Follow upstream setup instructions for other dependencies; installing BYOND alone does not supply the patched OpenDream client.

Use sibling directories named `Bastion-Station` and `OpenDream`. After gaining access to both private engine repositories, clone OpenDream with `--branch opendream-compat --recurse-submodules`; its submodule URL points to the matching private RobustToolbox copy. Build from the OpenDream directory:

```powershell
dotnet restore
dotnet build OpenDreamServer/OpenDreamServer.csproj -c Tools --no-restore --disable-build-servers
dotnet build OpenDreamClient/OpenDreamClient.csproj -c Tools --no-restore --disable-build-servers
```

Stop existing game processes before rebuilding binaries. Initialize the engine's recursive submodules using the published fork URLs once those forks are available.

Build the frontend from `Bastion-Station/tgui`:

```powershell
bun install --frozen-lockfile --ignore-scripts
bun run tgui:build
```

On Windows, `ttf2woff2`'s optional native-build install script uses subshell
redirection that Bun 1.3.6 cannot parse. `--ignore-scripts` skips package lifecycle
scripts while installing the locked dependencies. The explicit TGUI build still
runs afterward. A clean Windows install with this flag and Bun 1.3.6 successfully
built all three TGUI bundles. No compiler or package version change is required.

From `Bastion-Station`, compile the game:

```powershell
../OpenDream/bin/DMCompiler/DMCompiler.exe --version=516.1687 --define=CBT tgstation.dme
```

`CBT` is Bastion's regular build define; omitting it can select mapper-preview icon states instead of runtime states. Generated frontend bundles, compiled world output, native libraries, saves, and local server configuration are not distributed through this source branch.

The DM compiler above is built from the sibling OpenDream repository, not from
Bastion. Bastion's normal `BUILD.cmd` invokes BYOND DreamMaker and produces
`.dmb`/`.rsc` output; it does not replace the OpenDream compilation step that
creates `tgstation.json`.

From the OpenDream `bin/Content.Server` directory, start the server:

```powershell
./OpenDreamServer.exe --cvar net.port=1212 --cvar opendream.always_show_exceptions=true --cvar opendream.json_path=../../../Bastion-Station/tgstation.json
```

Wait for `Initializations complete` in the server output. From `bin/Content.Client`, connect with the matching client:

```powershell
./OpenDreamClient.exe --connect --connect-address 127.0.0.1:1212 --username TestPlayer
```

The patched engine also has `Tools/Prepare-ResourcePack.ps1` and `Tools/Start-PreloadedClient.ps1` for preloading matching game resources. See that engine's `Tools/ResourcePacks.md`; rebuild and verify the pack after changing the compiled world/assets. Preloading is optional and the normal VS Code F5 launch does not automatically mount it.

For double-click launching after the builds above, use **Launch Server.cmd** and
**Launch Client.cmd** at the top of the OpenDream folder. **Edit Launch Settings.cmd**
opens the local text file that selects `tgstation.json`; its default works with
these sibling folders. **Stop Server.cmd** stops that checkout's server. Basic
launching uses Windows PowerShell 5.1 or newer; PowerShell 7 adds automatic resource
preloading. Details are in the private engine's `Tools/Bastion-Launchers.md`.

## Status and limitations

Local testing has exercised lobby/round entry, observer movement and roles, portable lights, thermals, chat/TGUI, inventory, and shuttle navigation. This is not complete SS13 feature coverage or evidence of multi-player/network stability. BYOND clients cannot connect to an OpenDream server.

Known follow-ups include browser asset-cache warnings, unsupported multichannel audio, and input arriving before a client's startup admission completes. Native `world.Reboot()` currently shuts the OpenDream server down without relaunching it; use an external process restart for a new round. The three-second splash fade has an engine-side connected regression test, but still needs a real round-start visual retest.

No runnable release or public game server is included with this branch. When reporting a problem, include the game and engine revisions, reproduction steps, and relevant logs with account details, tokens, and private configuration removed.
