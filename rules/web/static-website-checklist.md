# 前端静态网站检查清单

> 适用于纯 HTML/CSS/JS 静态网站项目的规范化检查。每次接触静态网站项目时逐项检查。

## 一、安全（CRITICAL）

- [ ] `target="_blank"` 链接是否包含 `rel="noopener noreferrer"`（防止 tab-nabbing）
- [ ] 是否存在 `http://` 明文链接（应全部使用 `https://`）
- [ ] 第三方脚本是否异步加载（`async`/`defer`）
- [ ] 是否有硬编码的 API Key 或敏感信息

## 二、CDN & 网络（CRITICAL）

- [ ] **Google Fonts** (`fonts.googleapis.com`) → 替换为 `fonts.googleapis.cn`（谷歌中国官方镜像）
- [ ] **cdnjs.cloudflare.com** → 替换为 `cdn.bootcdn.net` 或自托管
- [ ] **cdn.jsdelivr.net** → 替换为 `cdn.bootcdn.net` 或自托管
- [ ] 其他境外 CDN（unpkg、googleapis 等）是否可用国内替代

**标准替换表：**

| 境外 CDN | 国内替代 |
|----------|---------|
| `fonts.googleapis.com` | `fonts.googleapis.cn` |
| `cdnjs.cloudflare.com` | `cdn.bootcdn.net` |
| `cdn.jsdelivr.net` | `cdn.bootcdn.net` |

## 三、备案信息（HIGH）

- [ ] 首页底部是否有 **ICP 备案号**（如 `粤ICP备2024351889号-5`）并链接到 `https://beian.miit.gov.cn`
- [ ] 首页底部是否有 **公安备案号** 并链接到 `https://beian.mps.gov.cn/#/query/webSearch?code=...`
- [ ] 公安备案是否悬挂官方警徽图标
- [ ] 备案信息是否在**所有页面**都显示（不只是首页）

**公安备案图标 URL：** `https://beian.mps.gov.cn/web/assets/logo01.6189a29f.png`

## 四、SEO & 多语言（HIGH）

- [ ] `<html lang="">` 属性是否正确设置
- [ ] `<meta charset="utf-8">` 和 `<meta name="viewport">` 存在
- [ ] `<title>` 和 `<meta name="description">` 存在且内容合理
- [ ] 每个页面有 `<link rel="canonical">`
- [ ] 多语言页面 `hreflang` 配置完整（包含 `x-default`）
- [ ] `og:type`, `og:title`, `og:description`, `og:url`, `og:locale`, `og:locale:alternate` 存在
- [ ] `twitter:card`, `twitter:title`, `twitter:description` 存在
- [ ] `sitemap.xml` 存在且 hreflang 配置完整
- [ ] `robots.txt` 存在

## 五、域名 & 品牌（HIGH）

- [ ] 页面中不存在占位域名（如 `yourdomain.com`, `example.com`）
- [ ] `<meta name="author">` 是项目实际主体
- [ ] 页脚版权信息与实际主体一致
- [ ] `README.md` 描述的是本项目而非模板信息
- [ ] `LICENSE` 文件版权归属正确

## 六、模板残留（MEDIUM）

- [ ] 是否残留 Boomerang/Webpixels/ThemeForest 等模板品牌信息
- [ ] `docs/` 目录是否是模板文档（应删除）
- [ ] 是否存在未使用的模板遗留页面（如 `homepage.html`, `sign-in.html`）
- [ ] `<meta name="author">` 是否仍是模板原作者

## 七、冗余文件（MEDIUM）

- [ ] `assets/vendor/` 是否存在大量未使用的库文件
- [ ] `assets/scss/` 源码文件是否已编译为 CSS，不再需要
- [ ] `assets/css/` 和 `assets/js/` 中是否有未引用的文件
- [ ] `assets/images/` 中是否有大量未使用的模板图片
- [ ] 图片文件是否过大（>500KB 建议压缩）
- [ ] 是否存在重复文件

## 八、其他（LOW）

- [ ] 网站有 favicon
- [ ] `.gitignore` 配置合理
- [ ] 没有 `console.log` 或调试代码残留
- [ ] 字体文件优先使用 CDN（版权考虑），避免本地存储
