# num2words-moonbit 项目申报书

## 基本信息

- 项目名称：num2words-moonbit：Python num2words 的多语言数字转文字 MoonBit 移植
- 参赛者：xinxin
- GitHub 仓库链接：<https://github.com/668xin/num2words-moonbit>
- 项目方向：MoonBit 多语言数字转文字基础库 / 国际化文本生成基础设施
- 是否为移植项目：是

## 项目简介

num2words-moonbit 将 Python 生态成熟的 num2words 核心能力移植到 MoonBit，把整数、大整数、小数、年份、金额在运行时转换成**英、法、西、德、意、葡、俄七种人类语言（葡语含巴西 / 欧洲两个变体，共 8 个语言代码）**的自然语言读法，为发票、报表、语音播报、无障碍读屏、教育类数字认知应用提供可复用的数字朗读能力。

传统的跨语言做法是在 MoonBit 项目里再内嵌一个 Python 运行时去调用 num2words，或者从零手写各语言的拼接规则。前者要引入第二种语言运行时，体积与依赖成本都高，也破坏了 MoonBit 单一语言栈与 wasm 小体积优势；后者则重复造轮子，而法语 vigesimal（70=soixante-dix、80=quatre-vingts）、德语闭合复合词（einundvierzig、tausendzweihundert）、意大利语省音（ventuno、centotto）、葡萄牙语连接词条件（mil e cem 与 mil duzentos…）、俄语三档复数与阴阳性（одна тысяча / две тысячи / пять тысяч）等规则极易写错。把这个能力移植到 MoonBit，利好所有需要在 MoonBit 中做国际化数字读写的库作者、工具开发者和应用开发者，可以直接编进前端 / wasm 与边缘侧做数字朗读，无需第二种语言运行时。

工程边界上，库对**无法处理的输入返回明确错误而不是崩溃**：数字串先经语法校验，超出各语言量级词表上限时返回「超出支持范围」错误。内部用 `BigInt` 与十进制字符串承载数值，避免浮点精度损失（金额与大整数场景更稳）。

## 核心功能范围

- **声明式** **`Lang`** **描述符**（零词、个位、十位、百位、量级词、连接词、负号、小数符），把「语言规则」变成数据而非代码分支；新增一种语言只需增加一个 `lang_xx.mbt` 数据文件，核心引擎不改。
- **输入校验与错误处理**：
  - `is_valid_number`：接受 `-?\d+` 或 `-?\d+\.\d+`，拒绝空串、`-`、`5.`、`.5`、`1.2.3`、`12a`、`abc` 等；
  - `num2words_str`：非法输入或超量级返回 `""`，**不崩溃**（`BigInt::from_string` 遇畸形输入会 abort，故前置校验）；
  - `num2words_str_checked`：返回 `Result[String, String]`，区分 `invalid number` 与 `magnitude out of supported range`；
  - CLI 打印对应 `error:` 信息。
- **8 个语言代码**：英语 `en`（全模式）、法语 `fr`（vigesimal）、西班牙语 `es`（veintiuno、cien/ciento）、德语 `de`（闭合复合词）、意大利语 `it`（省音与连写）、葡萄牙语 `pt`（巴西变体，短标度 `bilhão`=10⁹）与 `pt_PT`（欧洲变体，长标度 `mil milhões`=10⁹、`bilião`=10¹²）、俄语 `ru`（三档复数、`тысяча` 阴性变体 `одна/две`）。
- **模式分发**：`cardinal` / `ordinal` / `ordinal_num` / `year` / `currency` / 小数。`ordinal` 与 `ordinal_num` **八种语言代码全部原生实现**并与上游逐条差分对齐（含上游怪癖，如西语 `décimoprimero`、`es`/`pt` 的 0 号序数为空串、欧葡长标度 `milésimo milionésimo`）；负数序数返回 `""`（上游抛 TypeError），意语除外（`meno terzo`）；**`currency` 八种语言代码全部原生实现**（新增带币种代码的 `num2words_currency`，默认 EUR、`pt` 默认 BRL；币种集与上游一致：en/fr/de/it 为 EUR/USD/GBP，es 20 种，ru 6 种，pt 仅 BRL，pt_PT 为 EUR/USD/GBP/CAD/AUD），并处理了西语性数一致、俄语三档复数与性别、葡语零分省略（欧葡 GBP 保留零分）等规则；`year` 在 `it` / `pt` / `pt_PT` / `ru` 中为基数读法。
- **多形态 API**：`num2words`(BigInt) / `num2words_int` / `num2words_float` / `num2words_str` / `num2words_str_checked` / `num2words_currency` / `is_valid_number`。
- **量级上限守卫**：`Lang::supports` / `Lang::max_power`，越界返回明确错误而非越界访问。
- **CLI**（`cmd/main`，`--lang` / `--to` / `--currency` / `--help`），可直接演示与按需调用。
- **75 个 whitebox 测试**（`moon test` 75/75 通过，0 warning 0 error），覆盖：八种语言代码的基数、序数 / 序数数字、货币（币种集、性别 / 复数、舍入与符号）、语变体差异、英文年份 / 小数、输入校验的接受与拒绝表、边界值（`-0`、前导零、`1.50`、1e21、1e-7、0 在各模式下）、浮点科学计数法展开与负零小数、量级上限内外、以及 Int/String/Float 三路路径一致性与跨语言一致性。
- **与上游的差分对照测试**：`tools/gen_fixtures.py` 调用上游 num2words 0.5.14 生成 551×8（基数）+ 19×5（年份）+ 249×7 + 248（序数）+ 11×8（序数数字）+ 51×4（货币 en/fr/de/it，意语 45）+ 520（西语货币）+ 156（俄语货币）+ 26（巴葡货币）+ 130（欧葡货币）≈ **7611 条**期望值，MoonBit 侧逐条断言；对照发现并修复了英语 `and` 连接与年份读法、西语 `mil millones`、德语 `eintausend`、意大利语重音与连接词、法语 `trois cent mille`、西语序数十位边界、货币模式绕过小数路径、欧葡长标度序数与 GBP 零分等真实缺陷。报告见 `DIFF_REPORT.md`。
- **README** 示例覆盖各语言各模式调用、CLI 用法、合法输入语法、错误处理行为与已知限制。
- **三平台 CI**（ubuntu / macOS / windows）自动运行 `moon test`。

## 预期验收产物

- 公开仓库 `668xin/num2words-moonbit`，含 `moon.mod` 元数据与全部源码；当前以**公开仓库 / git 依赖**方式引入（见验收边界第 2 条）。
- 8 个语言代码的数字读法，在**各语言量级上限以内**输出正确结果；对非法输入与越界输入返回明确错误而非崩溃。
- 75 个测试与三平台 CI 测试记录，其中含 7611 条与上游 num2words 的差分对照。
- `DIFF_REPORT.md`：差分测试方法、覆盖范围、逐语言结果与明示的对照规则（意语重音、葡语标点、货币舍入与整数语义）。
- 完整 README + **LGPL-2.1 LICENSE**（与上游一致，许可证正文已与 SPDX / GitHub Licenses API 权威文本校验一致）+ 来源署名。
- 相对上游的差异化：纯 MoonBit 零运行时依赖、声明式扩展新语言、BigInt 与十进制字符串避免精度损失。

## 验收边界（明确不做 / 当前限制）

1. **不承诺「任意大整数」。** 量级词表有限，各语言上限为：`en`/`ru` 10³³、`fr` 10³⁰、`es`/`de`/`pt_PT` 10²⁴、`it`/`pt` 10²¹；超出范围返回明确错误。
2. **不承诺已发布到 mooncakes.io。** 当前 `moon add 668xin/num2words-moonbit` 无法解析（`Module not found in registry`）；发布到 mooncakes 列为后续项，需联网与账号操作。
3. **`currency` 八种语言代码均已原生支持**，币种集与上游一致：`en`/`fr`/`de`/`it` 为 EUR/USD/GBP，`es` 20 种，`ru` 6 种，`pt` 仅 BRL，`pt_PT` 为 EUR/USD/GBP/CAD/AUD（默认值分别为 EUR / BRL）；不支持的币种返回 `Err` / `""`。
4. **不提供反向转换**（`words → number`）。
5. **不作性能声明**——未发布性能基准。
6. **葡萄牙语提供巴西与欧洲两个变体**：`pt` 为 `dezesseis`、短标度 `bilhão`=10⁹；`pt_PT` 为 `dezasseis`、长标度 `mil milhões`=10⁹ / `bilião`=10¹²，两者的序数、currency 币种集与零分规则差异均已按上游对齐。
7. 小数在 `cardinal` 模式下按**逐位朗读**（`1234.56` → *… point five six*），不做四舍五入；`currency` 模式按第三位小数四舍五入到分。

## 移植或参考说明

- 原项目名称：num2words
- 原项目链接：<https://github.com/savoirfairelinux/num2words>
- 原项目许可证：LGPL-2.1
- 本项目许可证：LGPL-2.1

与原项目相比，本项目会做以下简化和重新设计：

- 使用 MoonBit 原生包结构、类型系统（BigInt、StringView）和测试方式（whitebox `*_wbtest.mbt`）组织代码，而不是复刻 Python 的 OOP 类继承结构；
- 用声明式 `Lang` 描述符替代上游按语言子类化的实现，新增一种语言只需加一个 `lang_xx.mbt` 数据文件，扩展成本更低；
- 输入直接吃十进制字符串与 `BigInt`，避免上游 Float 路径的浮点精度损失（金额 / 大整数场景更稳）；
- 当前覆盖 `en` / `fr` / `es` / `de` / `it` / `pt` / `pt_PT` / `ru` 八种语言代码；`zh` 等作为后续扩展范围，保留统一入口与描述符；
- 以 MoonBit API 与 CLI 为主要交付接口，方便接入 Web（wasm）、CLI、国际化报表与语音播报场景。

