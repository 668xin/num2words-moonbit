# num2words-moonbit 项目申报书

## 基本信息
- 项目名称：num2words-moonbit：Python num2words 的多语言数字转文字 MoonBit 移植
- 参赛者：668xin（GitHub 账号；真实姓名请替换）
- 联系方式：（待填：手机号 / 邮箱）
- GitHub 仓库链接：https://github.com/668xin/num2words-moonbit.git
- 项目方向：MoonBit 多语言数字转文字基础库 / 国际化文本生成基础设施
- 是否为移植项目：是

## 项目简介
num2words-moonbit 将 Python 生态成熟的 num2words 核心能力移植到 MoonBit，把任意数值（整数、任意大整数、小数、年份、金额）在运行时转换成英、法、西、德四种人类语言的自然语言读法，为发票、报表、语音播报、无障碍读屏、教育类数字认知应用提供可复用的数字朗读能力。

传统的跨语言做法是在 MoonBit 项目里再内嵌一个 Python 运行时去调用 num2words，或者从零手写各语言的拼接规则。前者要引入第二种语言运行时，体积与依赖成本都高，也破坏了 MoonBit 单一语言栈与 wasm 小体积优势；后者则重复造轮子，而法语 vigesimal（70=soixante-dix、80=quatre-vingts）、德语闭合复合词（einundvierzig、tausendzweihundert）等规则极易写错。把这个能力移植到 MoonBit，利好所有需要在 MoonBit 中做国际化数字读写的库作者、工具开发者和应用开发者，可以直接编进前端 / wasm 与边缘侧做数字朗读，无需第二种语言运行时；同时用 BigInt 与十进制字符串作为输入，避免浮点精度损失（金额与大整数场景更稳）。

本项目开发过程使用了 AI 编程助手辅助生成代码，但项目的目标设定、架构设计、测试策略与质量把关由参赛者本人掌握；库为确定性规则引擎，所有输出可由单元测试逐条复现。

## 核心功能范围
- 提供声明式 Lang 描述符（零词、个位、十位、量级词、连接词、负号、小数符），把「语言规则」变成数据而非代码分支；
- 支持整数、任意大整数（BigInt）、小数、年份、金额等多种数值输入；
- 提供统一转换入口 num2words(...)，按模式分发 cardinal / ordinal / ordinal_num / year / currency / 小数；
- 支持英语全模式（cardinal / ordinal / ordinal_num / year / currency）与法语（vigesimal：soixante-dix、quatre-vingts）、西班牙语（veintiuno、cien / ciento、un millón）、德语（闭合复合词 einundvierzig、tausendzweihundert）四种语言；
- 提供 num2words / num2words_int / num2words_float / num2words_str 多形态 API，直接吃十进制字符串与 BigInt，避免浮点精度损失；
- 提供 CLI（cmd/main，支持 --lang / --to / --help），可直接演示与按需调用；
- 提供 14 个 whitebox 测试，覆盖四语言基数与英文序数 / 年份 / 金额 / 小数，测试结果 0 warning 0 error；
- 提供 README 示例，覆盖各语言各模式调用与 CLI 用法；
- 提供三平台 CI（ubuntu / macOS / windows）自动运行 moon test。

## 预期验收产物
- 668xin/num2words-moonbit 库，可直接通过 `moon add 668xin/num2words-moonbit` 在 MoonBit 项目中使用其 API；
- 支持 en / fr / es / de 四语言、六模式（cardinal / ordinal / ordinal_num / year / currency / 小数）的数字读法，对任意整数与合理范围小数输出正确的自然语言读法；
- 自带 14 个测试与三平台 CI 测试记录报告；
- 完整 README + LGPL-2.1 LICENSE（与上游一致）+ 来源署名；
- （差异化）相对上游：纯 MoonBit 零运行时依赖、声明式扩展新语言、BigInt / 十进制字符串避免精度损失。

## 移植或参考说明
- 原项目名称：num2words
- 原项目链接：https://github.com/savoirfairelinux/num2words
- 原项目许可证：LGPL-2.1
- 本项目许可证：LGPL-2.1（与上游 num2words 统一；本项目为独立重新实现，未复制上游源码，采用与上游一致的 LGPL-2.1）

与原项目相比，本项目会做以下简化和重新设计：
- 使用 MoonBit 原生包结构、类型系统（BigInt、StringView）和测试方式（whitebox *_wbtest.mbt）组织代码，而不是复刻 Python 的 OOP 类继承结构；
- 用声明式 Lang 描述符替代上游按语言子类化的实现，新增一种语言只需加一个 lang_xx.mbt 数据文件，扩展成本更低；
- 输入直接吃十进制字符串与 BigInt，避免上游 Float 路径的浮点精度损失（金额 / 大整数场景更稳）；
- 当前覆盖 en / fr / es / de 四种语言，更多语言（ru / it / pt / zh 等）作为后续扩展范围，保留统一入口与描述符；
- 以 MoonBit API 与 CLI 为主要交付接口，方便接入 Web（wasm）、CLI、国际化报表与语音播报场景。
