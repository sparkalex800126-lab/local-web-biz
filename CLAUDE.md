# Local Web Biz — 本地店家網站建設

## 專案目標
為新竹/竹北本地店家（首攻托嬰中心）快速建設高品質一頁式網站 demo。

## 設計規範

### 風格定位
溫暖、專業、現代。讓家長一看就覺得「這裡安全、值得信任」。
**禁止 AI slop**：不要 Inter/Roboto、不要紫色漸層、不要 generic card UI。

### 配色系統
每家店要有獨特配色，但共享溫暖基調：
- 主背景：暖白色系（#FFF8F0 ~ #FAFAF5）
- 強調色：依店家品牌調整（柔粉、柔綠、暖橘、天藍）
- 文字：深灰 #1A1A1A，次要 #6B6B6B
- 木質色點綴

### Typography
- 標題：Noto Serif TC（權威感）
- 內文：Noto Sans TC（易讀）
- 英文搭配：不用 Inter，選有個性的（例如 DM Sans, Outfit, Sora）
- Line-height: 1.8 body, 1.4 headings

### 頁面結構（一頁式標準模板）
1. **Hero** — 大圖 + 中心名稱 + slogan + CTA「預約參觀」
2. **關於我們** — 簡短理念（2-3 句）
3. **服務特色** — 3-4 張特色卡片（icon + 標題 + 描述）
4. **環境展示** — 照片 gallery（Unsplash placeholder）
5. **家長見證** — 2-3 則 testimonial
6. **聯絡/預約** — 地址、電話、Google Maps 嵌入、LINE 預約按鈕、簡易表單

### 技術要求
- 純 HTML + CSS + JS（不用 framework）
- 手機優先響應式（breakpoints: 480px, 768px, 1024px）
- Scroll-reveal 動畫（IntersectionObserver）
- Sticky navbar + smooth scroll
- Google Fonts via CDN
- Unsplash 免費圖片（嬰幼兒/托育相關）
- 所有文案繁體中文，像真實網站
- 可直接部署 GitHub Pages / Cloudflare Pages

### LINE 整合
每個 CTA 按鈕都要有 LINE 連結選項：
```html
<a href="https://line.me/R/ti/p/@{LINE_ID}" class="btn-line">LINE 預約</a>
```

## AI Design Skills
`.claude/skills/` 有 76 個 skills from ai-design-components。
建站時務必讀取相關 SKILL.md：
- `designing-layouts` — 響應式 grid
- `theming-components` — design tokens
- `assembling-components` — 元件組裝
- `managing-media` — 圖片優化、gallery
- `implementing-navigation` — navbar、anchor
- `performance-engineering` — Core Web Vitals

## 輸出位置
每家店的 demo 放在 `demos/{store-slug}/`：
```
demos/
├── eton-kids/        ← 伊頓（已完成）
├── libaoer/          ← 立寶兒
├── home-me/          ← 禾米
└── ...
```

## 驗證
完成後必須：
1. `ls -la` 確認檔案存在且 >5KB
2. HTML 結構完整（DOCTYPE, head, body, closing tags）
3. 手機版 viewport meta tag 存在
4. 所有圖片 URL 可訪問
5. 繁體中文，零簡體字
