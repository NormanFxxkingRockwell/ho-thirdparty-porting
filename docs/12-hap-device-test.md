# Phase 5-3：HAP 高可信设备验证

定位：
- 本阶段是 `device-pass` 之上的更高可信验证，不替代 [11-cmake-build.md](./11-cmake-build.md) 中的 binary 设备测试。
- `device-pass` 证明产物可以在设备侧独立执行；`hap-device-pass` 证明 `.so` 可以被 HarmonyOS 应用通过 ArkTS -> NAPI -> native 链路加载并真实调用。
- 本阶段当前属于实验增强路径，失败或跳过不反向否定已经成立的 `build-pass`、`binary-pass`、`device-pass`，但必须如实记录。

## 输入

- `outputs/<库名>/lib/*.so*`
- `reports/<库名>/adaptation-report.md`
- `reports/<库名>/build-report.md`
- `templates/soTest-template.zip`
- 必要时使用 `signTools/hapsigner.zip`
- Phase 1 输出的 `HAP_ENV_READY` 与相关 HAP 环境状态

## 输出

- `reports/<库名>/hap-device-report.md`
- `reports/<库名>/hap-device/hap-test.patch`
- `reports/<库名>/hap-device/artifacts/`
- 任务表中的 `HAP测试状态`
- 批次汇总报告中的 `HAP测试状态`

## 标准路径

```text
准备临时 HAP 工程
-> 拷贝目标 .so、版本化 SONAME 文件和必要运行时依赖到 entry/libs/arm64-v8a/
-> 修改 NAPI bridge
-> ArkTS 页面展示 native 调用结果
-> 构建 unsigned / signed HAP
-> 必要时通过 signTools 做外部签名
-> 安装到设备
-> 启动 Ability
-> 收集 UI / 日志 / 返回数据
-> 记录 hap-device-pass / fail / skip
-> 保存 patch 与关键文件
-> 清理临时工程
```

## 临时工程规则

默认使用：

```text
tmp/hap-test/<库名>/soTest/
```

硬规则：
- 每次开始 HAP 验证前，都从 `templates/soTest-template.zip` 重新解压。
- 不允许复用上一轮修改后的 HAP 工程作为下一轮基础。
- HAP 工程目录属于临时执行目录，验证完成后默认清理。
- 必须保留本轮修改 patch、关键日志、HAP 构建产物路径和测试结论。

推荐执行：

```bash
bash scripts/prepare-hap-test-project.sh --lib-name <库名>
```

说明：
- 该脚本默认会复制 `outputs/<库名>/lib/` 下的 `*.so` 与 `*.so.*`，用于覆盖常见 SONAME 场景。
- 如果当前库还依赖额外的非系统共享库、资源文件或配置文件，AI 仍需手动补齐，不得因为 helper 已执行就默认认为 HAP 运行时依赖完整。

## HAP 验证路径选择

AI 必须先判断当前库适合哪条 HAP 验证路径，不允许把所有库都套成同一种固定逻辑。

选择前必须先盘点：
- 上游是否有 `testdata/`、`tests/inputs/`、`resources/`、示例图片、XML/INI/JSON、压缩包、字体、证书、正则输入、expected 输出等静态资源。
- Phase 5-2 的 `device-pass` 用例是否依赖静态文件、标准输入、工作目录、输出文件或 roundtrip 结果。
- 目标库 API 更适合接收内存 buffer/string、只读文件路径、目录路径，还是可写文件路径。
- HAP 中是否可以把这些资源以 `rawfile`、`resfile` 或 sandbox 文件形式稳定交给 native 代码。

优先顺序：
1. `fixture-driven HAP`：优先使用上游或 device-pass 已验证过的小型确定性资源、输入和 expected 输出，在 HAP 内完成真实解析、编码、压缩、转换、读取、写入或 roundtrip 校验。
2. `复用上游测试/示例逻辑`：当上游逻辑本质是库函数调用、依赖少、可低成本包装为 NAPI 方法时复用。
3. `最小真实 API smoke`：仅当没有可用 fixture、expected 输出或真实场景资源，或资源过大/不可分发/无法在 HAP 环境稳定访问时使用。
4. `skip`：HAP 环境缺失、签名/安装不可用，或目标库无法设计合理 HAP 调用链时使用。

静态资源不是降级到 smoke 的理由。对 cJSON、zlib、libpng、TinyXML2、LibTIFF、FreeType、PCRE2、Expat、libwebp、libarchive、libzip、Brotli 这类库，资源文件或输入/输出 roundtrip 往往正是高可信验证的核心。

### 静态资源承载策略

按目标 API 选择资源承载方式：
- `rawfile`：把小型只读资源放入 `entry/src/main/resources/rawfile/<库名>/...`。适合解析器、编解码器、压缩库等可以接收内存 buffer/string 的 API。ArkTS 可以读取 rawfile 后传给 NAPI；native 也可以通过 `OH_ResourceManager_InitNativeResourceManager`、`OH_ResourceManager_OpenRawFile`、`OH_ResourceManager_GetRawFileSize`、`OH_ResourceManager_ReadRawFile` 读取，CMake 需链接 `rawfile.z`。
- `resfile`：把需要只读路径或目录结构的资源放入应用资源目录，并通过应用上下文获得可访问路径。适合只能接收文件路径、但不需要写回原文件的库。
- `rawfile/resfile -> sandbox copy`：如果库 API 需要可写路径、输出文件、临时目录、原地修改或严格 POSIX 路径，先把资源复制到应用 sandbox，再把 sandbox 路径传入 NAPI。
- `hdc pushed fixture`：只有当资源不适合打入 HAP、体积过大、或必须与设备侧外部目录交互时才使用。使用时必须记录推送命令、远端路径和布局校验结果。

HAP 中推荐把验证结果压缩成可审计字符串，例如：

```text
pass=true;total=11;passed=11;failed=0;source=rawfile:cjson/inputs
```

### 资源驱动验证示例

可参考已完成库里的 device-pass 形态迁移到 HAP：
- cJSON：打包 `tests/inputs/test*` 和 `*.expected`，逐个解析并比较 `cJSON_Print()` 输出。
- zlib / Brotli / libzip / libarchive：使用小文本或二进制 fixture，执行压缩/打包 -> 解压/读取 -> 内容比较。
- Expat / TinyXML2 / inih / iniparser：打包 XML/INI fixture，解析后校验节点、字段或 expected 文本。
- libpng / libwebp / LibTIFF：打包小图片 fixture，执行 decode/encode/info 读取，并校验尺寸、格式或 roundtrip 输出。
- FreeType：打包小字体文件，加载 face/glyph 并校验可读属性。
- PCRE2：打包正则输入或最小 testdata，执行匹配并校验命中结果。

### smoke 降级规则

只有满足以下条件之一，才允许从 fixture-driven HAP 降级为最小真实 API smoke：
- 上游没有可复用资源、expected 输出、CLI roundtrip 或示例输入。
- 资源体积过大、授权不允许分发，或依赖主机/网络/进程环境，无法稳定打入 HAP。
- 目标库核心能力本身就是无输入或极小输入的 API，例如版本查询、初始化、自检类接口，且报告中说明覆盖边界。

如果上游存在小型确定性 fixture，但 HAP 仍只做最小 API smoke，报告必须明确写出为什么 fixture 不适用。不得把这种 smoke 描述成已完成资源级或场景级验证。

说明：
- 这里的 “smoke path” 不是模板默认 `add(2, 3)` 示例，也不是假数据占位。
- 它必须真实调用目标库 API，并返回可审计结果。
- HAP 阶段要证明的是 `ArkTS -> NAPI -> native -> 目标库` 这条链路成立；当库有可用静态资源或 roundtrip 语义时，还必须尽量证明真实数据路径成立。

## NAPI 适配要求

AI 需要根据当前库真实 API 修改临时工程中的：
- `entry/src/main/cpp/CMakeLists.txt`
- `entry/src/main/cpp/napi_init.cpp`
- `entry/src/main/cpp/types/libentry/Index.d.ts`
- `entry/src/main/ets/pages/Index.ets`

要求：
- NAPI 必须真实链接并调用目标三方库 `.so`。
- ArkTS 必须通过界面显示 native 调用结果。
- 不允许只保留模板里的 `add(2, 3)` 作为通过依据。
- 不允许只启动 HAP、只显示固定文案，或只验证 `.so` 文件存在。
- 如果目标库需要样例输入、资源文件、配置文件，必须一并放入 HAP 工程或设备可访问路径，并在报告中说明。
- 如果使用 `rawfile`、`resfile` 或 sandbox 资源，必须记录资源源路径、HAP 内路径、读取方式、用例数量和 expected 校验方式。

## 运行时依赖打包要求

- 不允许只拷贝顶层 `libfoo.so` 就默认认为 HAP 运行时依赖完整。
- 如果 `outputs/<库名>/lib/` 中存在 `libfoo.so.1`、`libfoo.so.1.2.3` 这类版本化 SONAME 文件，必须一并带入 HAP。
- 构建完成后，至少检查一种运行时依赖信息，例如：
  - `readelf -d <目标so>`
  - `readelf -d <构建后的 libentry.so>`
  - `objdump -p <目标so>`
  - `patchelf --print-needed <目标so>`（如果环境可用）
- 如果 `NEEDED` 中出现非系统共享库，HAP 包内必须存在同名文件；否则不得宣称 `hap-device-pass=pass`。
- 如果目标库依赖额外资源、配置文件或数据文件，也必须一并打包到 HAP 或放到设备可访问路径，并在报告中说明。

## 构建与安装

HAP 构建命令依赖本机 DevEco/Hvigor/签名环境，不在流程仓库中硬编码。

进入本阶段前应先参考 Phase 1 输出：
- `HAP_DEVECO_READY`
- `HAP_WINDOWS_BRIDGE_READY`
- `HAP_OHPM_READY`
- `HAP_OHPM_HOST`
- `HAP_HVIGOR_READY`
- `HAP_HVIGOR_HOST`
- `HAP_JAVA_READY`
- `HAP_JAVA_HOST`
- `HAP_SIGNTOOLS_READY`
- `HAP_PROJECT_SIGNING_READY`
- `HAP_SIGNING_MODE`
- `HAP_AUTOMATED_BUILD_READY`
- `HAP_SIGNING_READY`
- `HAP_DEVICE_READY`
- `HAP_ENV_READY`

说明：
- `HAP_ENV_READY=false` 时，本阶段可以记录为 `skip`，但必须说明缺失项。
- 在 WSL 场景下，DevEco Studio、`ohpm`、`hvigor`、签名配置通常在 Windows 侧；不要要求用户把这些工具安装到 WSL。
- 如果 `HAP_OHPM_HOST=windows` 或 `HAP_HVIGOR_HOST=windows`，构建命令应通过 Windows/PowerShell/DevEco 执行。
- 如果 `HAP_SIGNING_MODE=external-signTools`，允许先产出 unsigned HAP，再通过 `signTools/hapsigner.zip` 做外部签名；这条路径已经是正式允许路径，不要求回退去改工具链源码。
- 如果 `HAP_SIGNING_MODE=external-signTools` 但 `HAP_JAVA_READY=false`，不得宣称签名已可自动完成。
- 如果只是 DevEco Studio GUI 可用，但 `ohpm + hvigor` CLI 不可用，AI 不应假装可以自动构建；应记录需要用户通过 DevEco 完成构建或补齐 CLI 环境。
- 如果签名不可用，AI 不应继续伪造安装验证结果。

AI 应优先根据临时工程实际文件选择可用方式，例如：
- DevEco Studio 构建
- `ohpm install`
- `hvigorw assembleHap`
- `hvigor assembleHap`
- 工程自带 `hvigorw` / `hvigorw.bat`
- `signTools/hapsigner.zip` 的 `hap-sign-tool.jar` 外部签名

### 外部签名推荐路径

当 `HAP_SIGNING_MODE=external-signTools` 时，优先使用仓库脚本，不要手写 `java -jar hap-sign-tool.jar ...`：

```bash
bash scripts/sign-hap-with-sign-tools.sh \
  --unsigned-hap tmp/hap-test/<库名>/soTest/entry/build/default/outputs/default/entry-default-unsigned.hap \
  --bundle-name com.example.sotest \
  --workdir tmp/hap-sign/<库名>
```

脚本输出中的 `SIGNED_HAP` 是后续安装路径，`SIGN_RUN_DIR` 可以传给 artifact 收集脚本：

```bash
bash scripts/collect-hap-test-artifacts.sh \
  --lib-name <库名> \
  --extra-artifact <SIGN_RUN_DIR>
```

外部签名执行约束：
- 在 WSL 会话中，优先使用 WSL 的 `java` 执行上述脚本。
- 不要在 PowerShell 的 UNC 当前目录（例如 `\\wsl.localhost\...`）里直接执行签名命令；PowerShell 对 UNC 当前目录支持不稳定，容易把路径问题误判为签名问题。
- 如果确实需要 Windows PowerShell，必须先进入 Windows 本地盘路径或映射盘路径，再执行命令。
- `signTools/hapsigner.zip` 解压后通常会出现 `hapsigner/` 子目录；脚本会自动定位 `hap-sign-tool.jar`，手写命令时必须进入包含该 jar、`OpenHarmony.p12`、`OpenHarmonyApplication.pem` 的实际目录。

签名前的 profile 处理规则：
- 如果本轮修改了 `UnsgnedDebugProfileTemplate.json` 的 `bundle-name`、权限或 ACL，必须重新执行 `sign-profile` 生成新的 `ohos_provision_debug.p7b`。
- 如果没有修改 profile 模板，且签名目录中已有 `ohos_provision_debug.p7b`，可以先直接执行 `sign-app` 验证签名链路，不应因为 `sign-profile` 参数错误立即记为 `skip`。
- 如果不确定 profile 是否匹配，先核对模板中的 `bundle-info.bundle-name` 与 HAP 工程 `AppScope/app.json5` 的 `bundleName`。

如果必须手写 Java 命令：
- 必须先进入签名工具目录，即包含 `hap-sign-tool.jar`、`OpenHarmony.p12`、`OpenHarmonyApplication.pem` 的目录。
- 带空格的 `keyAlias` 必须作为单个参数传入，例如 `"OpenHarmony Application Profile Debug"`、`"openharmony application release"`。
- 不要把 `OpenHarmony Application Profile Debug` 拆成多个 token，也不要用反斜杠写在 Markdown 报告里再复制到不同 shell。
- 如果出现 `Param {-key value} must in pairs`、`signAlg` 被认为不可识别、或类似参数解析错误，优先检查 `keyAlias` 引用和参数是否成对，而不是先判定 Java 环境不支持 `signAlg`。

等价手写命令形态如下：

```bash
cd <sign-run-dir>/hapsigner
java -jar hap-sign-tool.jar sign-profile \
  -mode localSign \
  -keyAlias "OpenHarmony Application Profile Debug" \
  -keyPwd 123456 \
  -inFile UnsgnedDebugProfileTemplate.json \
  -outFile ohos_provision_debug.p7b \
  -keystoreFile OpenHarmony.p12 \
  -keystorePwd 123456 \
  -signAlg SHA256withECDSA \
  -profileCertFile OpenHarmonyProfileDebug.pem

java -jar hap-sign-tool.jar sign-app \
  -keyAlias "openharmony application release" \
  -signAlg SHA256withECDSA \
  -mode localSign \
  -appCertFile OpenHarmonyApplication.pem \
  -profileFile ohos_provision_debug.p7b \
  -inFile entry-default-unsigned.hap \
  -keystoreFile OpenHarmony.p12 \
  -outFile signApp.hap \
  -keyPwd 123456 \
  -keystorePwd 123456
```

外部签名失败分类：
- `Param {-key value} must in pairs`
- `Param {signAlg} is required, but can not be found`
- `signAlg` 被报告缺失或不可识别

出现上述错误时，默认先按“命令参数解析失败”处理，而不是按“Java 环境问题”处理。记录 `skip` 前至少完成：
1. 使用 `scripts/sign-hap-with-sign-tools.sh` 重试一次。
2. 确认 `keyAlias` 含空格值没有被 shell 拆开。
3. 确认当前目录是实际签名目录或使用了脚本自动解压目录。
4. 如果已有 `ohos_provision_debug.p7b` 且 profile 未变，尝试直接执行 `sign-app`。
5. 保存完整签名日志到 artifacts。

只有在上述检查后仍无法生成 signed HAP，才允许记录 `hap-device-pass=skip` 或 `fail`，并必须说明卡在 `sign-profile`、`sign-app` 还是环境前置项。

设备安装与启动优先使用 `harmonyos-dev-mcp`。

如果当前会话没有可用 MCP，再 fallback 到 `hdc`，但必须记录：
- 使用的安装命令
- 使用的启动命令
- 设备序列号
- HAP 路径
- Ability 名称
- 关键日志或 UI 结果

如果 fallback 到 `hdc`，并且实际调用的是 Windows `hdc.exe`：
- 不要把 WSL 相对路径直接传给 `hdc.exe file send`
- 优先使用 `wslpath -w` 转成 Windows / UNC 本地路径
- 远端路径显式写到目标文件名，不要只写目录
- 发送完成后，用 `hdc shell ls -al <远端目录>` 校验远端布局，再继续 `chmod` / 启动

## 成功标准

同时满足以下条件才可判定 `hap-device-pass=pass`：
- HAP 构建成功。
- HAP 成功安装到设备。
- 应用 Ability 成功启动。
- ArkTS 成功调用 NAPI。
- NAPI 成功调用目标三方库 `.so` 的真实 API。
- UI 或日志中出现可审计的结果，且结果来自目标三方库调用。
- 结果中应包含明确成功标记，例如 `pass=true`，或等价的可验证输出。
- 如果选择 `fixture-driven HAP`，结果中应包含用例总数、通过数、失败数、资源来源和至少一类 expected 校验依据。

## 失败与跳过规则

记录值统一为：
- `pass`
- `fail`
- `skip`
- `待处理`

判定规则：
- HAP 环境缺失、没有可用签名、无法安装应用：记录 `skip` 或 `fail`，并说明原因。
- NAPI 未真实调用目标库：不得记录 `pass`。
- 只跑模板默认 `add` 示例：不得记录 `pass`。
- 只启动应用但没有 UI / 日志结果：不得记录 `pass`。
- 有小型确定性 fixture 但未使用，且报告没有说明不适用原因：不得把结果描述为高可信资源验证；只能记录为受限 smoke，并说明覆盖不足。
- 如果目标库 API 无法合理设计 HAP 验证路径，记录 `skip`，但必须说明为什么现有 `device-pass` 已经是本轮最高可信结果。

## 报告要求

`reports/<库名>/hap-device-report.md` 必须记录：
- `hap-device-pass`
- HAP 验证策略：`fixture-driven HAP` / `复用上游测试逻辑` / `最小真实 API smoke` / `skip`
- 未直接复用上游测试入口的原因
- 模板来源
- 临时工程路径
- 接入的 `.so` 路径
- 修改的 HAP 工程文件
- NAPI 调用链说明
- 运行时依赖与资源处理
- 静态资源来源、承载方式：`rawfile` / `resfile` / `sandbox copy` / `hdc pushed fixture` / `none`
- 资源文件清单或数量、HAP 内路径、设备侧路径或 sandbox 路径
- 用例总数、通过数、失败数、expected 校验方式
- 如果使用 smoke，为什么没有使用 fixture/resource/roundtrip 验证
- ArkTS UI 展示说明
- HAP 构建命令和结果
- 签名模式与签名命令结果
- 安装命令和结果
- 启动命令和结果
- 关键 UI / 日志输出
- signed HAP 路径
- patch 路径
- 清理结果

收集执行：

```bash
bash scripts/collect-hap-test-artifacts.sh --lib-name <库名>
```

如果 signed HAP 或 `.p7b` 不在临时工程目录下，例如位于临时 `sign-run/` 目录，则补充：

```bash
bash scripts/collect-hap-test-artifacts.sh --lib-name <库名> --extra-artifact <signed-hap-or-sign-dir>
```

## 下一步

HAP 验证完成后进入 [13-delivery-archive.md](./13-delivery-archive.md)。
