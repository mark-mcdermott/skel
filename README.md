<h1>
  <img src="./logo.png" width="25" valign="middle">
  Skel
</h1>

[![Tests](https://github.com/mark-mcdermott/skel/actions/workflows/test.yml/badge.svg)](https://github.com/mark-mcdermott/skel/actions/workflows/test.yml)

<p>
App scaffolding by typing in a tree-type list of the files and directories
</p>

<p align="center">
  <img src="./walkthrough-v0.1.0.gif" width="720" alt="Skel walkthrough">
</p>

## What
`skel` is a bash script where you can quickly create a bunch of blank files in the file structure you need by typing something like:

```bash
./skel.sh <<EOF
.eslint.json
.gitignore
.prettierrc
electron-builder.yml
src/
  main/
    index.ts
  preload/
    index.ts
  renderer/
    App.tsx
    electron.d.ts
    index.html
    main.tsx
    styles/
      global.css
    vite-env.d.ts
tsconfig.json
tsconfig.node.json
vite.config.ts
EOF
```

## Getting Started
- `git clone https://github.com/mark-mcdermott/skel.git`
- `cd skel`
- `chmod +x skel.sh`
- then try something like this:
```bash
./skel.sh <<EOF
file1.txt
directory1/
  file2.txt
  directory2/
    file3.txt
  file4.txt
file5.txt
EOF
```
- `skel` will create this file structure:
```
├── directory1
│   ├── directory2
│   │   └── file3.txt
│   ├── file2.txt
│   └── file4.txt
├── file1.txt
└── file5.txt
```

## Details
- `skel` uses heredoc syntax, so start your `skel` command like this:
```
skel <<EOF
```
- End your `skel` command like this:
```
EOF
```
- Every line between those two is the name of a file or directory.
- Directories **must** end in `/`. That's how `skel` knows it's a directory.
- For all files/directories inside a directory, use two spaces to indent.
- `skel` creates the file structure in the location you execute `skel` from.

## Why
Yesterday I searched for a way to scaffold a project out from memory using syntax like above and ChatGPT said there were no really clean bash solutions already built. So I built it. It was also nice practice thinking through a simple algorithm like this.

## How
I built this v0 of `skel` by hand over two days, with help from ChatGPT on the bash syntaxes I couldn't remember.

## Roadmap
This v0 is simple--it works if you follow every directory with `/` and use two spaces for all indents. It does not yet provide a look-ahead, error checking, error messages, or built-in instructions. These are on the map for v1.

## Issues
- No error checking
- No error messages
- Needs built-in instructions
- Should error on single spaces or tab indents
- Should error on multiple indents (multiple levels without directories)
- Should error on blank lines
- Should error on indents under files
- A lookahead approach that detected if next line is indented could omit `/` for all dirs except empty ones