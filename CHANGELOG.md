# Changelog

## 1.0.0 (2024-06-09)


### ⚠ BREAKING CHANGES

* API Config changes/Types ([#9](https://github.com/tris203/precognition.nvim/issues/9))

### Features

* { and } gutter hints ([f13e0f2](https://github.com/tris203/precognition.nvim/commit/f13e0f2d2de7c679978dc367e9ef6e67ed2b2b8f))
* % support ([#8](https://github.com/tris203/precognition.nvim/issues/8)) ([fd62c75](https://github.com/tris203/precognition.nvim/commit/fd62c753bd0a8e57772ad7e9a0346431a51ee52e))
* add `Precognition` command ([#58](https://github.com/tris203/precognition.nvim/issues/58)) ([c7b4be4](https://github.com/tris203/precognition.nvim/commit/c7b4be4e4eb219d534910fbb20571b96d3d87d37))
* add peek function ([7851c33](https://github.com/tris203/precognition.nvim/commit/7851c33dc410546f8765964e4164231323e36c07))
* API Config changes/Types ([#9](https://github.com/tris203/precognition.nvim/issues/9)) ([563b5d2](https://github.com/tris203/precognition.nvim/commit/563b5d29cc23dee5b1f90ed726356c1fb049f85c))
* b motion, skipcol for overlapping motions in render ([7eb18cf](https://github.com/tris203/precognition.nvim/commit/7eb18cf8a450db6e4389d80f8526f364bdf08469))
* basic hinting behavior with ^ and $ motions ([2672029](https://github.com/tris203/precognition.nvim/commit/2672029a3c87b21b051c89990f51710cf0254f29))
* big word support ([#23](https://github.com/tris203/precognition.nvim/issues/23)) ([672a00f](https://github.com/tris203/precognition.nvim/commit/672a00f839078d80feff38ad5f13d949dabd32bf))
* blacklist buffers ([#12](https://github.com/tris203/precognition.nvim/issues/12)) ([75db367](https://github.com/tris203/precognition.nvim/commit/75db367ccc30ddc3abeea07da644d0e0181b940c))
* custom highlight colors ([#28](https://github.com/tris203/precognition.nvim/issues/28)) ([455f527](https://github.com/tris203/precognition.nvim/commit/455f5275649990f99449ac152a832dc7a9b42a6a))
* e-motion and prepare for tests ([8def51c](https://github.com/tris203/precognition.nvim/commit/8def51c1907a0d92966b040703d7c7fd1f5dc608))
* further customise highlight colors ([#31](https://github.com/tris203/precognition.nvim/issues/31)) ([83d452d](https://github.com/tris203/precognition.nvim/commit/83d452db377867729230a7fbf806c39fa2977a9b))
* Gutter hints for vertical movement ([00902be](https://github.com/tris203/precognition.nvim/commit/00902be32a902544548ccb845f9946eaa79198a7))
* hint prio ([5c6f374](https://github.com/tris203/precognition.nvim/commit/5c6f3747d6cb0753eea12008f6861bac0189ed6b))
* initial API and main module structure ([9a2f371](https://github.com/tris203/precognition.nvim/commit/9a2f371ec056fdc042dcdd9004734b3098eeaad8))
* remove CursorHold dependency ([#16](https://github.com/tris203/precognition.nvim/issues/16)) ([ba2147d](https://github.com/tris203/precognition.nvim/commit/ba2147d7425153a75568c2e529d82f192b0a5d91))
* startVisible flag ([c292777](https://github.com/tris203/precognition.nvim/commit/c292777ed6e701e5d376b2f545bdb445d3635c30))
* support "prio" priority value for gutter marks ([#43](https://github.com/tris203/precognition.nvim/issues/43)) ([cab9d0a](https://github.com/tris203/precognition.nvim/commit/cab9d0a50be7c3c3d097cf96e50785ce9c5bb2f0))
* use nvim's `utf_class` via ffi for char classing ([#49](https://github.com/tris203/precognition.nvim/issues/49)) ([488dc26](https://github.com/tris203/precognition.nvim/commit/488dc265d3bd4f68834540ca5b3a13af5925bae6))
* w motion, show/hide/toggle functions ([a6709ff](https://github.com/tris203/precognition.nvim/commit/a6709ff478ff021ca89f358400e2dd0ac9a024a0))
* **wip:** w motion ([f0bcfb0](https://github.com/tris203/precognition.nvim/commit/f0bcfb0ebe4551980bb534e5131bb54145b7253f))


### Bug Fixes

* a lot of edge cases ([#4](https://github.com/tris203/precognition.nvim/issues/4)) ([ee3f8a6](https://github.com/tris203/precognition.nvim/commit/ee3f8a66d6f38b4832804c03b44836e04b4e6761))
* e motion - behind cursor ([a9a1b1d](https://github.com/tris203/precognition.nvim/commit/a9a1b1d1123fcb1c5c4381fa5d4c705d835940af))
* e motion ([#21](https://github.com/tris203/precognition.nvim/issues/21)) ([2feea7e](https://github.com/tris203/precognition.nvim/commit/2feea7e6b2e27afd9b5571dd60baccc75ea9b160))
* empty line fix ([105fb2b](https://github.com/tris203/precognition.nvim/commit/105fb2b26a5c20f43be50679a2c24a00cd28b869))
* hint precendce ([314d430](https://github.com/tris203/precognition.nvim/commit/314d430245ce3ebb16ab2922ba0f42a5c0206bc3))
* more buffnr flexibility ([99dd135](https://github.com/tris203/precognition.nvim/commit/99dd135eb7d50a58eb5b6ee17cdf1a3d386e9fc2))
* multibyte chars in text lines ([#48](https://github.com/tris203/precognition.nvim/issues/48)) ([f893367](https://github.com/tris203/precognition.nvim/commit/f893367e00f618b8b2eddd38db2ac2b5676390b7))
* next/prev paragraph when lines contain whitespace ([#30](https://github.com/tris203/precognition.nvim/issues/30)) ([7a4c5eb](https://github.com/tris203/precognition.nvim/commit/7a4c5eb483123d5bb3fd4b02c984dd153a2118d6))
* normal buffers only ([d31d493](https://github.com/tris203/precognition.nvim/commit/d31d4937a78cfef3dc76431a6b49d77bfb82ed95))
* offset for backwards matching pairs motion ([#51](https://github.com/tris203/precognition.nvim/issues/51)) ([22d7b41](https://github.com/tris203/precognition.nvim/commit/22d7b4113086c833063eaaa3d31621ab54c055b6))
* partial config type ([#10](https://github.com/tris203/precognition.nvim/issues/10)) ([b948966](https://github.com/tris203/precognition.nvim/commit/b948966f5ad5cf7818915de34ad6a31c5cfa2671))
* remove extra space when the cursor is mid-word ([6dd0c62](https://github.com/tris203/precognition.nvim/commit/6dd0c62eced0e99596c2868dbe7a3235307cc45f))
* replacement characters ([#40](https://github.com/tris203/precognition.nvim/issues/40)) ([b40c353](https://github.com/tris203/precognition.nvim/commit/b40c3539f95504bea2ac4ac4dc866a95edba6d4d))
* respect shiftwidth/tabstop ([41b2a7b](https://github.com/tris203/precognition.nvim/commit/41b2a7bff2644750891ca8ba8a404e635d8b7062))
* skipcol offset ([ca9a0ef](https://github.com/tris203/precognition.nvim/commit/ca9a0ef7a16a1028adc078eaf4363309710a91fb))
* spacing issues ([836fc28](https://github.com/tris203/precognition.nvim/commit/836fc28bacd9f28ebff668256fa93cc2fad23691))
* w motions after EOL ([c4ed7ff](https://github.com/tris203/precognition.nvim/commit/c4ed7ff77e4e530e4b0695118333bcf36f98b9e9))


### Performance Improvements

* inline `require` calls to minimize startup cost ([#59](https://github.com/tris203/precognition.nvim/issues/59)) ([d3f33a9](https://github.com/tris203/precognition.nvim/commit/d3f33a9fea40ac60ae36da9213eea61470e73dba))
* more consistent rendering, less flicker ([66f1fc6](https://github.com/tris203/precognition.nvim/commit/66f1fc60a430bf07a70ddcb813e57ad4ce86acf0))
