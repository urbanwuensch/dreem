<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# agentguide

Show the instructions for AI assistants (coding agents), or put them into your analysis folder

## Syntax

[`agentguide`](#syntax1)

[`agentguide("install")`](#syntax2)

## Description

drEEM ships a guide for AI assistants such as Claude Code, Codex, Copilot or Cursor: `AGENTS.md` in the toolbox folder. It tells an assistant how to use drEEM correctly, in short:

* write a reproducible script and follow the order of the tutorials
* avoid methods that open windows and wait for you
* check the dataset status before each correction step
* leave scientific decisions to you (number of components, outliers, scatter settings)
* never report a PARAFAC model as validated unless split-half validation passed

Assistants only follow this guide if they read it. Most assistants automatically read an `AGENTS.md` (Claude Code: `CLAUDE.md`) in the folder they work in, but not one inside an installed toolbox. `agentguide("install")` copies the guide into your analysis folder so your assistant finds it.

> ***You remain responsible for the analysis. An assistant following this guide proposes and explains; check its scripts, the dataset history (`viewhistory`) and the model diagnostics before using results.***

<details open>

<summary><b>`agentguide` - print the guide</b></summary>

<a name="syntax1"></a>

Prints `AGENTS.md` to the command window. Useful to read it yourself, or for an assistant that runs MATLAB in batch mode (`matlab -batch`). When the toolbox is started in batch mode, `tbx = drEEMtoolbox` prints a one-line reminder of this command.

</details>

<details open>

<summary><b>`agentguide("install")` - copy the guide into the current folder</b></summary>

<a name="syntax2"></a>

Copies `AGENTS.md` into the current folder (`pwd`) and creates a one-line `CLAUDE.md` that points Claude Code to it. Run it once in the folder where you and your assistant analyse your data, then start the assistant in that folder.

Existing files are never overwritten. If the folder already contains an `AGENTS.md` or `CLAUDE.md`, the function stops and tells you; add a line pointing to the drEEM guide to your own file instead, e.g. *"Before using the drEEM toolbox, read `<toolbox folder>/AGENTS.md`."* The toolbox folder is `drEEMtoolbox.rootfolder`.

After a toolbox update, run it again in a fresh folder, or delete the copied files first, to get the updated guide.

</details>

## Examples

**Read the guide:**

```matlab
drEEMtoolbox.agentguide
```

**Prepare an analysis folder for an assistant:**

```matlab
cd("~/projects/estuary_EEMs")
drEEMtoolbox.agentguide("install")
```

Then start your assistant in `~/projects/estuary_EEMs` and describe your task, for example: *"The EEMs in this folder are Aqualog exports. Import them with drEEM, process them following the tutorials, and fit and validate a PARAFAC model. Ask me before decisions."*

## Input arguments

<details open>

<summary><b>`action` - what to do</b></summary>

<i>"show" (default) | "install"</i>

* `"show"`: print `AGENTS.md` to the command window
* `"install"`: copy `AGENTS.md` and a pointer `CLAUDE.md` into the current folder (never overwrites)

</details>
