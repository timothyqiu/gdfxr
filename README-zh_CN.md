# gdfxr

<img src="icon.png?raw=true"  align="right" />

[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![AssetLib](https://img.shields.io/badge/AssetLib-gdfxr-478cbf)](https://godotengine.org/asset-library/asset/1249)
[![English README](https://img.shields.io/badge/README-English-red)](README.md)

以 Godot 插件形式移植的 [sfxr](https://www.drpetter.se/project_sfxr.html "DrPetter's homepage - sfxr")，这是一个非常流行的复古游戏音效生成器。

你可以在 Godot 中把 sfxr 音效文件当作普通的音频文件使用，也可以像在原始的 sfxr 中一样对音效进行编辑。

> 🚧 如果你想在 Godot 4 里使用这个插件，请移步 [godot-4](https://github.com/timothyqiu/gdfxr/tree/godot-4) 分支。

## 安装

这是一个普通的 Godot 插件。安装时，先下载 ZIP 包，解压后将 `addons/` 文件夹移动到你的项目文件夹中，然后在项目设置中启用本插件。

## 用法

启用插件后，你会看到出现了一个名叫“gdfxr”的底部面板。这就是音效编辑器。

<p align="center">
  <img src="screenshots/editor-zh_CN.png?raw=true" />
</p>

左侧的按钮是 7 种不同类型的音效生成器。还有一个根据当前音效略微演化声音的选项，以及一个完全随机生成音效的选项。大多数时候用这些按钮就可以了。

使用生成器按钮随机生成音效后，可以使用右侧的控件对音效的参数进行微调。

生成的音效可以保存成 `.sfxr` 文件，之后可以再次打开编辑。这些文件只包含生成器的参数，所以只有大概 100 字节。但可以直接把它们当普通的 `AudioStream` 用。

如果你希望使用原始的 sfxr 保存出的文件，请确保使用 `.sfxr` 扩展名保存。你也可以在原始的 sfxr 中加载并编辑 `.sfxr` 文件。

`.sfxr` 文件有循环（Loop）、位深度（Bit Depth）、采样率（Sample Rate）等导入选项。可以在 Godot 编辑器的导入面板中找到。

**注意：** 由于 GDScript 的性能限制，生成较长的音效时编辑器可能会有短暂的停滞。只有编辑器会受此影响。在游戏中使用 `.sfxr` 文件是不会在运行时生成任何东西的。

## 更新日志

见 [CHANGELOG](CHANGELOG.md)。
