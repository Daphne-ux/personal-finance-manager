# 我的財務管理室｜設定與啟用

這是一個可跨電腦、手機同步的個人財務管理網頁。前端為原生 HTML/CSS/JavaScript，雲端資料庫與登入使用 Supabase。

## 功能
- Email 註冊／登入
- 多帳戶管理：類型、用途、初始餘額、即時計算目前餘額
- 收入、支出、帳戶轉帳；每筆可填日期、分類、備註、重要提醒
- 「已發生」與「預計」狀態分開，預計項目不會提前改變帳戶餘額
- 月份切換、月收入／支出／結餘與未來規劃
- 每月分類預算，對照實際支出
- 財務目標與累積進度
- 響應式版面，手機底部導覽
- Supabase Row Level Security，使用者只能讀寫自己的資料

## 1. 建立 Supabase 專案
1. 前往 https://supabase.com/ 建立帳號與新專案。
2. 在專案的 **SQL Editor** 開啟新查詢，貼上本資料夾的 `schema.sql` 全文並執行。
3. 到 **Project Settings → API**（或 Connect 面板）取得 Project URL 與 anon/public key。
4. 開啟 `index.html`，找到最下方 JavaScript 開頭的兩行：
   ```js
   const SUPABASE_URL='YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY='YOUR_SUPABASE_ANON_KEY';
   ```
   將兩個值換成你的 Project URL 與 anon/public key。
   **只能放 anon/public key，絕對不要把 service_role key 放進前端。**
5. Supabase Authentication → URL Configuration，設定網站的 Site URL 與允許的 Redirect URLs（部署後填入網站網址）。

## 2. 部署網頁
可使用 GitHub Pages、Netlify 或 Vercel 部署。若用 GitHub Pages：
1. 建立一個新的 GitHub repository。
2. 將 `index.html` 放在 repository 根目錄並 push。
3. Repository → Settings → Pages → Deploy from a branch → 選 `main` / `root`。
4. 等待 GitHub Pages 顯示網址，再將網址加入 Supabase Authentication 的 Redirect URLs。

## 3. 第一次使用建議順序
1. 註冊 Email 帳號並登入。
2. 先建立帳戶，填入各帳戶「目前的起始餘額」作為初始餘額。若之後才開始使用本工具，建議不要再把過去交易重複補登，否則會重複計算。
3. 新增當月薪資：類型選「收入」、分類填「薪資」、狀態選「已發生／已完成」，選擇薪資入帳帳戶。
4. 逐筆記錄日常收支；若只是先規劃未來，狀態選「預計／尚未發生」。
5. 建立各月份預算與目標。

## 財務計算規則
- 帳戶目前餘額 = 初始餘額 + 已完成收入 − 已完成支出 − 已完成轉出 + 已完成轉入。
- 預計交易不影響目前帳戶餘額，也不列入已發生的本月收入／支出。
- 帳戶轉帳不算收入或支出，只移動資金位置。
- 月收支結餘 = 當月已完成收入 − 當月已完成支出。
- 目標累積金額目前由使用者手動維護；可在目標編輯視窗更新。對應帳戶欄位用於標示資金放置位置，不會再次加總進帳戶餘額。

## 重要注意事項
- 此版本為可連接雲端資料庫的第一版程式碼；在完成 Supabase 專案建立、貼上 schema、填入 URL/key 並部署前，尚未真正啟用雲端同步。
- Supabase anon/public key 可用於瀏覽器，但資料安全依賴本專案提供的 RLS policies。請勿刪除或停用 RLS。
- 建議啟用 Supabase Email confirmation，並使用高強度密碼。
- 目前尚未整合銀行 API、自動對帳、CSV 匯入匯出或定期交易；信用卡帳戶若以負債管理，建議初始餘額輸入負數，但目前表單採非負數設計，需在後續版本擴充負債模型。
