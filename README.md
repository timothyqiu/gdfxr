# gdfxr

<img src="icon.png?raw=true"  align="right" />

[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![AssetLib](https://img.shields.io/badge/AssetLib-gdfxr-478cbf)](https://godotengine.org/asset-library/asset/1249)
[![中文 README](https://img.shields.io/badge/README-%E4%B8%AD%E6%96%87-red)](README-zh_CN.md)

A Godot plugin that ports [sfxr](https://www.drpetter.se/project_sfxr.html "DrPetter's homepage - sfxr"),
the popular program of choice to make retro sound effects for games.

You can use sfxr sound files like regular audio files in Godot and edit sound files like in the
original sfxr.

> 🚧 Checkout the [godot-4](https://github.com/timothyqiu/gdfxr/tree/godot-4) branch if you want to use this plugin in Godot 4.

## Installation

This is a regular plugin for Godot. To install, download the ZIP archive, extract it, and move the
`addons/` folder it contains into your project folder. Then, enable the plugin in project settings.

## Usage

After enabling the plugin, you'll see a bottom panel named "gdfxr" appear.
This is the sound editor.

<p align="center">
  <img src="screenshots/editor.png?raw=true" />
</p>

Buttons on the left are sound generators of 7 different categories. There are also an option to
mutate the current sound slightly, and an option to generate a completely random sound.
These are the buttons you'll be working with most of the time.

After a random sound is generated with the generator buttons, you can fine-tune the sound with
the controls on the right.

The generated sound can be saved and edited later as an `.sfxr` file.
These files only contain the generator parameters, so they are only about 100 bytes.
But they can be used directly as regular `AudioStream`s.

If you want to reuse an existing sound from the original sfxr, make sure to save it with an
`.sfxr` extension. You can also load & edit the `.sfxr` file with the original sfxr.

**Note:** Due to performance constraints with GDScript, the editor may freeze a bit when generating
long sounds. This only happens in-editor.
Using `.sfxr` files in-game won't generate anything at runtime.

## Changelog

See [CHANGELOG](CHANGELOG.md).
