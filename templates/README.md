# HAP 验证模板

本目录保存 HAP 高可信设备验证所需的基础模板。

## 文件

- `soTest-template.zip`：基于用户本地 `D:\codeBase\soTest` 的 HarmonyOS Native C++ 模板工程生成。

## 模板用途

该模板只提供基础 ArkTS -> NAPI 工程骨架。每个三方库进入 Phase 5-3 时，AI 必须：
- 重新解压模板到 `tmp/hap-test/<库名>/soTest/`
- 拷贝本库 `.so`、版本化 SONAME 文件（`*.so.*`）以及必要的非系统运行时依赖到 `entry/libs/arm64-v8a/`
- 先判断当前库适合 `fixture-driven HAP`、`复用上游测试/示例逻辑` 还是 `最小真实 API smoke path`，不要把所有库都改成同一套固定 smoke 逻辑
- 如果上游或 device-pass 已有小型静态资源、fixture、expected 输出或 roundtrip 用例，优先把资源打入 `resources/rawfile/`、`resources/resfile/` 或复制到应用 sandbox 后再调用目标库 API
- 修改 NAPI bridge，使其真实调用目标三方库 API
- 修改 ArkTS 页面，让 UI 展示 native 调用结果
- 构建并安装 HAP，在设备侧验证调用链

说明：
- 模板工程可以只承担应用骨架职责，不强制要求自身内置 signingConfigs。
- 如果模板未内置签名配置，可按 Phase 1 输出的 `HAP_SIGNING_MODE=external-signTools`，使用仓库内 `signTools/hapsigner.zip` 对 unsigned HAP 做外部签名。
- 外部签名优先使用 `scripts/sign-hap-with-sign-tools.sh`，避免手写 Java 命令时把带空格的 key alias 拆成多个参数。
- 外部签名失败时，先按参数解析、当前目录、profile 是否匹配排查；`signAlg` 缺失类错误通常不能直接作为“Java 环境问题”结论。
- 如果上游测试入口强依赖 `main()`、测试框架或 CLI，通常不应机械搬入模板；应保留它作为 `device-pass` 证据，并在 HAP 中提炼同等语义的 API/fixture/roundtrip 调用链。
- 资源目录不是降级 smoke 的理由。cJSON、zlib、libpng、TinyXML2、LibTIFF、FreeType、PCRE2 这类库应优先使用资源驱动的 HAP 验证；只有资源不可用或不适合打包时才降级为最小真实 API smoke，并写明原因。

模板默认示例不能作为 `hap-device-pass` 依据。

## 排除内容

模板压缩包不包含本机生成物和本机环境文件：
- `.hvigor/`
- `.idea/`
- `oh_modules/`
- `entry/.cxx/`
- `**/build/`
- `local.properties`
- `.clangd`
- `.clang-format`
- `.clang-tidy`
