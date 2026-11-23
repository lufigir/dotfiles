# Astro

An Orca app theme. Edit `themes/dark.json`; omitted tokens are derived from `--background` and `--foreground`.

## Develop

```sh
orca plugin validate .
orca plugin dev watch .    # loads this folder into Orca and prints its logs and reloads; Ctrl-C unloads it
```

Orca names the publisher after where the plugin is installed from: the GitHub or GitLab owner of
its repository, or `local` for a folder. See
https://github.com/stablyai/orca/blob/main/docs/reference/plugin-authoring.md.

The code colors (`tokenColors` in `themes/dark.json`) are Tokyo Night's, taken from Orca's
official `stablyai.orca-tokyo-night-theme`, so code reads as it does in Zed. After editing, run
`orca plugin install <this folder>` to update the installed copy.
