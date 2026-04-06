# Clash Royale Clone - Unity 6

لعبة بطاقات متعددة اللاعبين مبنية بـ Unity 6 مستوحاة من Clash Royale.

## هيكل المشروع

```
Assets/Scripts/
├── Towers/
│   └── Tower.cs          ← الأبراج (HP، هجوم، تدمير)
├── Units/
│   ├── Unit.cs           ← إحصائيات الوحدة
│   └── UnitAI.cs         ← حركة الوحدة واختيار الهدف
├── Cards/
│   ├── CardData.cs       ← ScriptableObject لتعريف البطاقة
│   └── CardManager.cs    ← اليد، السحب، الإطلاق
└── Managers/
    ├── GameManager.cs    ← المؤقت، التيجان، الفوز/الخسارة
    └── ElixirManager.cs  ← نظام الإكسير
```

## الإعداد في Unity 6

### 1. إعداد المشهد
- أنشئ مشهداً جديداً وأضف الكائنات التالية:
  - `GameManager` (GameObject فارغ) → أضف `GameManager.cs` + `ElixirManager.cs`
  - `KingTower_P1`, `KingTower_P2` → أضف `Tower.cs` (isKingTower = true)
  - `GuardTower_P1_L`, `GuardTower_P1_R` → أضف `Tower.cs`
  - `CardManager` (Canvas) → أضف `CardManager.cs`

### 2. إنشاء البطاقات
في Project window: **Create > Game > Card** لكل بطاقة من البطاقات الثماني.

| البطاقة | النوع | التكلفة | HP | ضرر |
|---------|-------|---------|-----|-----|
| Knight  | Unit  | 3       | 600 | 100 |
| Archers | Unit  | 3       | 300 | 60  |
| Giant   | Unit  | 5       |2000 | 80  |
| Minions | Unit  | 3       | 250 | 70  |
| Fireball| Spell | 4       | -   | 400 |
| Arrows  | Spell | 3       | -   | 250 |
| Cannon  | Building | 3   | 400 | 90  |
| Bomb Tower | Building | 4 | 500 | 50 |

### 3. Prefab الوحدة
لكل وحدة (مثلاً Knight):
1. أنشئ Sprite → أضف `Unit.cs` + `UnitAI.cs`
2. أضف `Rigidbody2D` (Gravity Scale = 0)
3. أضف `CircleCollider2D`
4. احفظه كـ Prefab واسحبه لـ CardData.prefab

## الخطوات القادمة
- [ ] إضافة Photon Fusion 2 للمتعددين
- [ ] تصميم رسومات الساحة والأبراج
- [ ] إضافة animations للوحدات
- [ ] نظام matchmaking
