# 墨點俠村 · 設計重點（短版）

完整計劃書另見 Cursor Page／計劃書文件。此處只記骨架對齊點。

## 核心循環（獵魔村式）
建築服務俠客 → 俠客變強 → 派遣出征帶回資源 → 升級村莊 → 再開建築。

## 開局
- 六綠俠：刀客阿鐵、劍客阿青、槍客阿長、棍僧大力、暗衛阿針、拳師阿牛
- 建築：村長府、客棧、鐵匠鋪、醫館、練功場、懸賞榜

## 技術
- 引擎：**Godot 4.3+**
- 主場景：`res://scenes/main/main.tscn`
- Autoload：`GameState`、`SaveManager`
- 系統腳本：`BuildingSystem` / `HeroSystem` / `DispatchSystem` / `ResourceLoop`

## Prototype 驗收
主畫面可顯示銀兩／木材／俠客數；「派遣」約 3 秒後加資源；「建客棧」扣資源升等級。
