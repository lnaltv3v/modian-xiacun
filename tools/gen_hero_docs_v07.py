# -*- coding: utf-8 -*-
"""Generate orange/red hero design docs for 墨點俠村 v0.7."""
from __future__ import annotations
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "docs" / "heroes"
OUT.mkdir(parents=True, exist_ok=True)

REDS = [
  {
    "id": "red_zhangwuji", "name": "張無記", "canon": "張無忌", "weapon": "拳腳", "rarity": "紅",
    "base_power": 48,
    "personality": "溫厚而決斷——平時忍讓，關頭敢擔；對兄弟極義氣，對權謀本能厭惡。",
    "background": "少年時身負奇症流落邊陲，後得隱世醫法同內功相濟，終成能一人擋千軍嘅神話級俠客。佢唔熱衷掌門名號，卻常被捲入正邪之爭；來到墨點俠村，只想有一處能讓人安穩食住嘅地方，順便教後進「打人唔好打殘心」。",
    "appearance": {
      "resolution": 256,
      "silhouette": "寬肩長身、白衣黑邊、長髮半束；無長兵，雙掌為主；入場時衣袂帶淡金色內息紋。",
      "palette_notes": "宣紙白＋墨黑邊＋淡金內息高光；袖口可隱青衫殘影。",
      "signature_props": ["白衣黑緣長袍", "半束長髮", "掌心淡金氣暈", "腰間無劍只有藥囊"],
      "fx_tier": "神話級：入場金波擴散、大招全屏掌影疊層、受擊時衣袂逆向飄。",
    },
    "skills": [
      {"id": "yi_yang_zhi_mo", "name": "一陽指墨", "desc": "點穴式遠近皆可：單體高傷並短暫封技；對人類首領額外壓制。"},
      {"id": "qian_kun_fan", "name": "乾坤翻掌", "desc": "短時間大幅提升格擋與反震，將所受近戰傷害部分反彈。"},
      {"id": "jiu_yang_hu", "name": "九陽護體", "desc": "開場／危急時獲得厚護盾與異常抗性；護盾破裂時震退周圍敵人。"},
      {"id": "tai_ji_rou", "name": "太極柔勁", "desc": "被動：受暴擊傷害降低；成功格擋後下一擊必附帶擊退。"},
    ],
    "growth": {"focus": "均衡生存＋爆發反打", "stat_bias": {"hp": "高", "atk": "中高", "def": "高", "spd": "中"}, "notes": "後期坦輸出雙修；適合秘境扛波同前哨壓陣。"},
  },
  {
    "id": "red_dongfang", "name": "東方唔敗", "canon": "東方不敗", "weapon": "暗器", "rarity": "紅",
    "base_power": 52,
    "personality": "孤傲、戲謔、極自信；視多數對手為「尚未入眼」。對美與速度近乎偏執，對背叛零容忍。",
    "background": "曾以一身繡花針技壓倒整代武林，隱於高山繡樓多年。江湖流傳「正面接招者皆敗」——唔係誇張，係統計。被俠村以英雄帖請出山時，只丟下一句：「有趣嘅獵物先值得落針。」",
    "appearance": {
      "resolution": 256,
      "silhouette": "紅衣長髮、單手執繡箍、針雨成扇；剪影極細長、飄帶誇張。",
      "palette_notes": "硃紅主色＋墨黑髮＋銀針高光；禁用粉嫩盤外色。",
      "signature_props": ["硃紅繡袍", "長髮及腰", "銀繡針簇", "腰間花繡箍"],
      "fx_tier": "神話級：針雨全屏斜線、大招時間減速感（幀停短促）、入場紅絲繚繞。",
    },
    "skills": [
      {"id": "xiu_hua_yu", "name": "繡花針雨", "desc": "遠程多段傷害，命中疊「刺痕」；滿層爆開額外毒傷。"},
      {"id": "hong_si_suo", "name": "紅絲鎖喉", "desc": "定身／減速單體，短時間無法接近；對刺客類額外有效。"},
      {"id": "fei_hua_cai", "name": "飛花摘葉", "desc": "瞬間位移並對路徑敵人造成切割；可取消自身硬直。"},
      {"id": "wu_di_dong", "name": "無敵東風", "desc": "終極：短暫無敵＋極高攻速針雨，結束後大硬直需隊友掩護。"},
    ],
    "growth": {"focus": "極限輸出與風箏", "stat_bias": {"hp": "低", "atk": "極高", "def": "低", "spd": "極高"}, "notes": "玻璃大炮；前哨需棍／拳腳擋前。"},
  },
  {
    "id": "red_dugu", "name": "獨孤求拜", "canon": "獨孤求敗", "weapon": "劍", "rarity": "紅",
    "base_power": 50,
    "personality": "淡泊如水，卻藏好勝之心——一生只求一敗。寡言，對後輩偶有點破，從不收徒名義。",
    "background": "劍塚隱士，歷青鋒、軟劍、重劍、木劍四境。武林無人能敗，故自號「求拜」。俠村秘境深處曾見其木劍插碑；請出後只問：「爾等可有能令我輸一招之人？」",
    "appearance": {
      "resolution": 256,
      "silhouette": "青袍負木劍、身形清瘦如竹；站姿極鬆，一出手劍勢如山。",
      "palette_notes": "青衫＋枯木褐＋劍氣淡白；木劍無鞘。",
      "signature_props": ["青袍", "背上木劍", "空石台剪影（入場）", "無華麗飾物"],
      "fx_tier": "神話級：大招簡到極致——一劍白線貫屏、餘韻長；入場石碑碎影。",
    },
    "skills": [
      {"id": "mu_jian_yi", "name": "木劍一式", "desc": "看似輕挑，實為破防真傷；無視部分防禦。"},
      {"id": "jian_zhong_yi", "name": "劍冢遺意", "desc": "切換「重／木」心法：重＝高傷慢；木＝快斬連段。"},
      {"id": "qiu_bai_shi", "name": "求敗之勢", "desc": "血量越低攻擊越高；低於三成時每擊附帶擊暈機率。"},
      {"id": "wu_zhao_sheng", "name": "無招勝有招", "desc": "被動：對持兵器敵人提升暴擊；自身無兵器加成改為全額。"},
    ],
    "growth": {"focus": "單體斬殺與破防", "stat_bias": {"hp": "中", "atk": "極高", "def": "中", "spd": "中高"}, "notes": "Boss 殺手；群戰略遜暗器／槍。"},
  },
  {
    "id": "red_saodi", "name": "掃地僧", "canon": "掃地僧", "weapon": "棍", "rarity": "紅",
    "base_power": 51,
    "personality": "謙遜到令人發毛；說話慢、掃地勤。真正動手時語氣仍溫柔，對手卻已跪。",
    "background": "藏經閣無名老僧，數十年只掃落葉。據說曾一指解兩大高手內傷之劫。俠村請帖送到時，佢先問有冇掃把——有，先來。",
    "appearance": {
      "resolution": 256,
      "silhouette": "灰僧衣、光頭、竹掃把當棍；背微駝但站定如山。",
      "palette_notes": "灰褐僧衣＋竹黃掃把＋極淡金佛光（大招先用）。",
      "signature_props": ["僧衣補丁", "竹掃把", "念珠", "落葉環繞（待機）"],
      "fx_tier": "神話級：大招掃把橫揮帶金色經文粒子；入場落葉成陣。",
    },
    "skills": [
      {"id": "luo_ye_sao", "name": "落葉橫掃", "desc": "範圍控制＋擊倒；對群怪極強。"},
      {"id": "yi_zhi_chan", "name": "一指禪定", "desc": "點中單體，大幅降低其攻擊並自身減傷。"},
      {"id": "cang_jing_hu", "name": "藏經護體", "desc": "為全隊提供短時減傷護罩。"},
      {"id": "wu_xiang_jie", "name": "無相解冤", "desc": "終極：淨化友方異常並大範圍震暈；冷卻極長。"},
    ],
    "growth": {"focus": "控場肉盾與團隊減傷", "stat_bias": {"hp": "極高", "atk": "中", "def": "極高", "spd": "低"}, "notes": "前哨核心；秘境扛 Boss。"},
  },
  {
    "id": "red_wangchongyang", "name": "王重揚", "canon": "王重陽", "weapon": "拳腳", "rarity": "紅",
    "base_power": 49,
    "personality": "堂堂正正、先天下之憂；對後輩嚴而有溫。厭邪道害人，卻肯給改過機會。",
    "background": "昔年論劍魁首，開宗立派後隱於終南。江湖尊為「中神」一檔。俠村重建需定海神針，故以英雄帖請出——答應條件只有一條：村中唔准欺壓弱小。",
    "appearance": {
      "resolution": 256,
      "silhouette": "道袍寬袖、長鬚、雙拳蓄勁如岳；站姿中正。",
      "palette_notes": "道袍青灰＋鬚白＋拳勢淡青氣。",
      "signature_props": ["道冠", "長鬚", "寬袖道袍", "腰間玉牌"],
      "fx_tier": "神話級：大招拳影如山岳疊嶂、入場青霞一閃。",
    },
    "skills": [
      {"id": "xian_tian_quan", "name": "先天拳意", "desc": "蓄力重拳，蓄滿則範圍爆炸傷害。"},
      {"id": "jin_yan_jue", "name": "金雁穿雲", "desc": "高速近身連打，收尾挑飛。"},
      {"id": "zhong_nan_qi", "name": "終南正氣", "desc": "提升全隊短暫攻擊；對邪毒類敵人額外傷害。"},
      {"id": "lun_jian_ba", "name": "論劍霸氣", "desc": "被動：開場首擊必暴；對精英／Boss 傷害提升。"},
    ],
    "growth": {"focus": "正面剛猛輸出＋隊長光環", "stat_bias": {"hp": "高", "atk": "高", "def": "中高", "spd": "中"}, "notes": "萬金油紅階；教學向「正派標竿」。"},
  },
  {
    "id": "red_huangshang", "name": "黃裳", "canon": "黃裳", "alt_name": "黃常", "weapon": "暗器", "rarity": "紅",
    "base_power": 47,
    "personality": "學者脾氣：慢熱、較真、一鑽研就廢寢忘食。對「招式結構」比對勝負更興奮。",
    "background": "帝都舊吏，因校對經卷悟出攻防循環之理，寫成駭世心法後隱姓埋名。江湖只知「九陰殘卷」來源成謎；俠村以古籍碎片換得其現身——條件係：給一間安靜書房同唔限量墨。",
    "appearance": {
      "resolution": 256,
      "silhouette": "文士長袍、袖藏短弩／鐵蓮；文弱外表對比殺招。",
      "palette_notes": "墨褐文袍＋硃砂批註色點＋鐵灰暗器。",
      "signature_props": ["書卷", "袖弩", "鐵蓮花", "墨指痕"],
      "fx_tier": "神話級：技能帶經文浮現、大招九宮格暗器陣；入場翻書一頁化刃。",
    },
    "skills": [
      {"id": "jiu_yin_can", "name": "殘卷殺機", "desc": "閱讀式詠唱後釋放高傷暗器陣；可被打斷。"},
      {"id": "gong_fang_huan", "name": "攻防輪轉", "desc": "切換攻／防姿態：攻＝傷高；防＝反彈暗器。"},
      {"id": "jing_wen_suo", "name": "經文鎖脈", "desc": "降低目標全屬性，疊加可封印大招。"},
      {"id": "shi_bu_xie", "name": "十部邪功解", "desc": "被動：對使用「毒／邪／吸」類技能敵人減傷並反噬。"},
    ],
    "growth": {"focus": "智控與陣法輸出", "stat_bias": {"hp": "中低", "atk": "高", "def": "中", "spd": "中"}, "notes": "需站樁詠唱；搭配控場棍僧。"},
  },
]

ORANGES = [
  {"id": "orange_yangguo", "name": "楊菓", "canon": "楊過", "weapon": "拳腳", "rarity": "橙", "base_power": 36,
   "personality": "性情決烈、重情義；吃過苦所以更護短。嘴硬心軟，對權威天然不服。",
   "background": "少年歷盡欺凌與奇遇，一臂雖失仍練成驚世掌力。浪跡天涯後應俠村之邀暫駐，只求有處可安置「想過平淡日子」嘅心願——當然，平淡總被打斷。",
   "appearance": {"resolution": 128, "silhouette": "黑衣披風、缺右袖／義肢護臂、左掌為主；身形矯健帶孤傲。", "palette_notes": "墨黑衣＋硃紅披風裏＋護臂鐵灰。", "signature_props": ["黑衣", "單臂護甲", "披風", "腰間玉蜂小囊"], "fx_tier": "絕學級：掌風玄色涟漪、大招黯然殘影連打。"},
   "skills": [
     {"id": "an_ran_zhang", "name": "黯然殘掌", "desc": "情緒越高傷害越高；低血時附加吸血。"},
     {"id": "xuan_tie_yi", "name": "玄鐵餘勁", "desc": "重擊破防，短暫降低目標防禦。"},
     {"id": "yu_feng_ci", "name": "玉蜂軟刺", "desc": "遠程騷擾並減速（暗器輔助向）。"},
     {"id": "ku_lian_xin", "name": "苦戀心魔", "desc": "被動：隊友倒下時短暫狂暴。"},
   ],
   "growth": {"focus": "爆發近戰", "stat_bias": {"hp": "中", "atk": "高", "def": "中", "spd": "高"}, "notes": "後期可衝紅階體驗；適合亂山／毒沼速清。"}},
  {"id": "orange_guojing", "name": "郭靚", "canon": "郭靖", "weapon": "拳腳", "rarity": "橙", "base_power": 38,
   "personality": "愚直忠誠、為國為民；反應不快但打實。對承諾死守。",
   "background": "大漠長大，學成降龍一路拳意後守城無數。俠村請其坐鎮前哨時，佢只問：「啲村民食唔食得飽？」答得飽，就留下。",
   "appearance": {"resolution": 128, "silhouette": "壯碩、勁裝、雙拳如龍；臉憨厚。", "palette_notes": "土褐勁裝＋龍氣金黃（特效）＋腰帶銅扣。", "signature_props": ["寬腰帶", "護腕", "樸素勁裝", "無華飾"], "fx_tier": "絕學級：降龍氣柱、大招龍形拳影。"},
   "skills": [
     {"id": "xiang_long_shi", "name": "降龍十八式（節）", "desc": "連續重拳，收尾範圍震地。名用「節」示意原創改編，唔用原著全稱。"},
     {"id": "fei_long_zai", "name": "飛龍在天影", "desc": "跳躍砸擊，對群獸高效。"},
     {"id": "kang_long_you", "name": "亢龍有悔意", "desc": "蓄力越久傷越高；可取消為防禦姿。"},
     {"id": "xia_yi_gu", "name": "俠義骨", "desc": "被動：守護低血隊友時自身減傷。"},
   ],
   "growth": {"focus": "正面群戰與守點", "stat_bias": {"hp": "高", "atk": "高", "def": "高", "spd": "低"}, "notes": "前哨首選橙階。"}},
  {"id": "orange_linghuzhong", "name": "令狐忠", "canon": "令狐沖", "weapon": "劍", "rarity": "橙", "base_power": 35,
   "personality": "瀟灑不羈、重義輕名；喝酒比練劍勤——但劍一出仍驚四座。",
   "background": "華山棄徒出身，得隱世劍法真傳後笑傲江湖。俠村茶寮常客；接委託前要先問有冇好酒。",
   "appearance": {"resolution": 128, "silhouette": "青衫負劍、衣襟鬆散、笑意；劍勢隨意卻無破綻。", "palette_notes": "青衫＋酒葫蘆褐＋劍光銀白。", "signature_props": ["酒葫蘆", "青衫", "長劍", "散髮"], "fx_tier": "絕學級：劍花連綿、大招無招劍網。"},
   "skills": [
     {"id": "xiao_ao_jian", "name": "笑傲劍意", "desc": "連斬提升攻速，可閃避一次攻擊。"},
     {"id": "du_gu_jiu", "name": "獨孤九式影", "desc": "破兵器特效：對持械敵人額外傷害。"},
     {"id": "zui_xian", "name": "醉仙步", "desc": "位移＋短暫無敵幀。"},
     {"id": "yi_qi", "name": "義氣相挺", "desc": "被動：鄰近友方暴擊率微升。"},
   ],
   "growth": {"focus": "靈活劍客", "stat_bias": {"hp": "中", "atk": "高", "def": "中低", "spd": "高"}, "notes": "PvE 清場佳；生存靠走位。"}},
  {"id": "orange_qiaofeng", "name": "喬風", "canon": "喬峰", "weapon": "拳腳", "rarity": "橙", "base_power": 39,
   "personality": "豪邁剛烈、恩怨分明；認準嘅理撞牆都唔讓。對兄弟可托生死。",
   "background": "丐幫舊主，一掌鎮北地。身世糾葛令其浪跡，俠村以「真兄弟席」邀之——席上無人問出身，只問酒量。",
   "appearance": {"resolution": 128, "silhouette": "高大、短褐、龍抓手勢；氣勢壓場。", "palette_notes": "丐幫褐＋綠袋（可簡）＋拳勁土黄。", "signature_props": ["布袋", "短褐", "寬掌", "項鍊骨飾（可選）"], "fx_tier": "絕學級：擒龍抓；大招拋投震屏。"},
   "skills": [
     {"id": "xiang_long_zhuo", "name": "擒龍神抓", "desc": "抓住敵人砸地，強控。"},
     {"id": "pai_yun_zhang", "name": "排雲雙掌", "desc": "雙掌推山，直線穿透。"},
     {"id": "bei_ming_jie", "name": "北地豪氣", "desc": "短時提升全隊士氣（攻擊）。"},
     {"id": "en_yuan", "name": "恩怨分明", "desc": "被動：對曾擊倒友方之敵傷害提升。"},
   ],
   "growth": {"focus": "剛猛控場", "stat_bias": {"hp": "高", "atk": "極高", "def": "中高", "spd": "中"}, "notes": "人類首領剋星。"}},
  {"id": "orange_zhangsanfeng", "name": "張三風", "canon": "張三丰", "weapon": "拳腳", "rarity": "橙", "base_power": 40,
   "personality": "仙風道骨、笑看勝負；指點後進如春風。極少動真怒。",
   "background": "武當開山祖師，太極一出剛柔相濟。難得下山，只因俠村「宣紙墨點」勾起其書畫興致——順便教兩手防身。",
   "appearance": {"resolution": 128, "silhouette": "道袍、長鬚、太極圓轉姿勢；白髮如雪。", "palette_notes": "道袍白／青＋鬚白＋太極陰陽特效（克制使用）。", "signature_props": ["拂塵（可選）", "道袍", "長鬚", "太極圖背影"], "fx_tier": "絕學級：圓轉氣場、大招陰陽環爆炸。"},
   "skills": [
     {"id": "tai_ji_quan", "name": "太極圈手", "desc": "化勁減傷並反彈部分傷害。"},
     {"id": "mian_zhang", "name": "綿掌三叠", "desc": "三連柔掌，層層加力。"},
     {"id": "chun_yang", "name": "純陽指點", "desc": "治療／強化單體友方。"},
     {"id": "wu_dang_feng", "name": "武當遺風", "desc": "被動：隊伍內劍／拳腳職業微加暴擊。"},
   ],
   "growth": {"focus": "化勁輔助與反制", "stat_bias": {"hp": "高", "atk": "中高", "def": "高", "spd": "中"}, "notes": "團隊引擎。"}},
  {"id": "orange_fengqingyang", "name": "風青羊", "canon": "風清揚", "weapon": "劍", "rarity": "橙", "base_power": 37,
   "personality": "隱逸、厭爭鬥；被逼出手時乾脆利落。對「有招無招」有執念。",
   "background": "思過崖隱士，劍法已入無招之境。俠村英雄帖送到崖上，被風吹落三次——第四次佢自己下來：「煩。」",
   "appearance": {"resolution": 128, "silhouette": "灰袍、清瘦、劍在鞘多過出；眼神銳。", "palette_notes": "灰青袍＋白髮＋劍氣極簡白線。", "signature_props": ["灰袍", "長劍", "崖風披肩", "簡陋草鞋"], "fx_tier": "絕學級：無華一劍、大招殘影三段。"},
   "skills": [
     {"id": "wu_zhao_jian", "name": "無招之劍", "desc": "無法被預判格擋的一擊（機制上降敵格擋率）。"},
     {"id": "si_guo_feng", "name": "思過風", "desc": "加速自身並清除減速。"},
     {"id": "po_gang", "name": "破罡一刺", "desc": "對護盾／覇體額外傷害。"},
     {"id": "yin_shi", "name": "隱士之心", "desc": "被動：脫戰回復加速。"},
   ],
   "growth": {"focus": "精準刺殺", "stat_bias": {"hp": "中", "atk": "極高", "def": "中", "spd": "高"}, "notes": "教令狐忠向上相容。"}},
  {"id": "orange_huangyaoshi", "name": "黃藥獅", "canon": "黃藥師", "weapon": "暗器", "rarity": "橙", "base_power": 36,
   "personality": "奇傲、聰明絕頂、厭世俗禮教；對有才者惜，對偽善者毒。",
   "background": "東海桃花島主，琴棋書畫毒皆精。俠村請其改進丹房配方，交換條件係：島上琴譜副本一份。",
   "appearance": {"resolution": 128, "silhouette": "青衫文士、執簫、袖藏石子；儒雅含殺氣。", "palette_notes": "青綠衫＋桃花粉點（克制）＋簫褐。", "signature_props": ["玉簫", "青衫", "桃花瓣（特效）", "棋子暗器"], "fx_tier": "絕學級：音刃波、大招落英暗器雨。"},
   "skills": [
     {"id": "bi_hai_xiao", "name": "碧海潮生曲影", "desc": "音波範圍傷＋混亂機率。"},
     {"id": "tan_zhi_shen", "name": "彈指神通意", "desc": "遠程破甲石子。"},
     {"id": "qi_ju", "name": "奇門布陣", "desc": "地面陷阱區，敵進入減速。"},
     {"id": "ao_gu", "name": "傲骨文人", "desc": "被動：對「偽君子／門派敵」傷害提升。"},
   ],
   "growth": {"focus": "法術型暗器", "stat_bias": {"hp": "中低", "atk": "高", "def": "中", "spd": "中高"}, "notes": "毒沼相性佳。"}},
  {"id": "orange_ouyangfeng", "name": "歐陽峰", "canon": "歐陽鋒", "weapon": "棍", "rarity": "橙", "base_power": 37,
   "personality": "狠辣、執拗、為達目的不擇手段；顛倒練法後神智時清時亂，戰力反而更怪。",
   "background": "西域毒傑，白駝山主。俠村以「解毒需知毒」為由請其坐鎮醫館顧問——村民又敬又怕。",
   "appearance": {"resolution": 128, "silhouette": "白衣披髮、蛇杖、眼白可翻（狂態）；詭異。", "palette_notes": "白衣＋蛇鱗綠＋毒紫霧（盤內梵紫）。", "signature_props": ["蛇杖", "白衣", "毒囊", "披髮"], "fx_tier": "絕學級：毒霧、逆行關節打擊、大招蟾震。"},
   "skills": [
     {"id": "ham_gong", "name": "蛤蟆功影", "desc": "蓄力彈射衝撞，擊退＋毒。"},
     {"id": "she_zhang", "name": "靈蛇杖法", "desc": "棍技連打，附帶中毒。"},
     {"id": "ni_yun", "name": "逆運經脈", "desc": "短時自傷換極高攻擊。"},
     {"id": "xi_du", "name": "西部毒王", "desc": "被動：毒傷加深；己方醫館效率對其隊伍微升（設定向）。"},
   ],
   "growth": {"focus": "毒控與爆發", "stat_bias": {"hp": "中", "atk": "高", "def": "中", "spd": "中"}, "notes": "毒沼王牌；注意自傷風險。"}},
  {"id": "orange_hongqigong", "name": "洪喫公", "canon": "洪七公", "weapon": "棍", "rarity": "橙", "base_power": 38,
   "personality": "貪吃、豪爽、疾惡如仇；收徒看人品同廚藝。",
   "background": "丐幫老前輩，打狗棒法聞名。俠村酒樓一開，佢聞香而至——條件係每日有叫化雞。",
   "appearance": {"resolution": 128, "silhouette": "老丐、打狗棒、綠袋；笑容可掬。", "palette_notes": "丐褐＋綠袋＋棒木色。", "signature_props": ["打狗棒", "綠袋", "雞腿（待機彩蛋）", "破衣"], "fx_tier": "絕學級：棒影如狗躍、大招滿屏棒花。"},
   "skills": [
     {"id": "da_gou_bang", "name": "打狗棒法影", "desc": "控場連打，克制群匪。"},
     {"id": "xiang_long_jie", "name": "降龍半式", "desc": "傳予後輩的半套重拳（棍尾也可砸）。"},
     {"id": "jiao_hua_ji", "name": "叫化雞氣", "desc": "吃飽狀態：短時全屬性提升（需酒樓）。"},
     {"id": "ji_e_ru_chou", "name": "嫉惡如仇", "desc": "被動：對山賊／叛軍傷害提升。"},
   ],
   "growth": {"focus": "控場與教學光環", "stat_bias": {"hp": "高", "atk": "高", "def": "中高", "spd": "中"}, "notes": "與郭靚互補。"}},
  {"id": "orange_yideng", "name": "一登大師", "canon": "一燈大師", "weapon": "拳腳", "rarity": "橙", "base_power": 36,
   "personality": "慈悲、沉穩、前朝帝王心性仍在；出手點到即止，除非救眾生。",
   "background": "南帝出家後隱於石林。俠村醫館缺「一陽真氣」療傷法，故遠迎之。",
   "appearance": {"resolution": 128, "silhouette": "金紅袈裟、光頭、單指蓄光；慈眉。", "palette_notes": "袈裟紅金＋指尖暖光。", "signature_props": ["袈裟", "念珠", "指光", "蒲團影子"], "fx_tier": "絕學級：指光療傷／殺傷雙形態、大招佛光罩。"},
   "skills": [
     {"id": "yi_yang_zhi", "name": "一陽指墨光", "desc": "可切治療或傷害形態。"},
     {"id": "liu_mai_qi", "name": "六脈餘氣", "desc": "遠程氣勁連射（簡化）。"},
     {"id": "ci_bei", "name": "慈悲願", "desc": "強療瀕死友方（冷卻長）。"},
     {"id": "nan_di", "name": "南帝遺澤", "desc": "被動：醫館相關回復效果對全隊微增。"},
   ],
   "growth": {"focus": "治療與點穴", "stat_bias": {"hp": "中", "atk": "中高", "def": "中", "spd": "中"}, "notes": "珍稀輔助橙。"}},
  {"id": "orange_zhoubotong", "name": "周伯同", "canon": "周伯通", "weapon": "拳腳", "rarity": "橙", "base_power": 35,
   "personality": "老頑童：貪玩、怕悶、打架當遊戲；心地不壞。",
   "background": "全真老前輩，左右互搏玩出花。俠村練功場一建成，佢自己鑽進去：「借位玩兩日。」結果住咗半年。",
   "appearance": {"resolution": 128, "silhouette": "白髮童顏、雙臂各干各嘅；表情嬉笑。", "palette_notes": "道袍淺色＋白髮＋雙影殘像。", "signature_props": ["雙殘影", "道袍", "頑童表情", "無兵器"], "fx_tier": "絕學級：左右分身連打、大招雙手互搏亂舞。"},
   "skills": [
     {"id": "zuo_you_bo", "name": "左右互搏影", "desc": "同時打兩個目標或雙倍攻速對單體。"},
     {"id": "kong_ming_quan", "name": "空明拳意", "desc": "化勁＋反打。"},
     {"id": "wan_tong", "name": "老頑童", "desc": "嘲諷敵人攻擊自己，降低其命中。"},
     {"id": "hao_qi", "name": "好玩之心", "desc": "被動：戰鬥越久攻速越高（有上限）。"},
   ],
   "growth": {"focus": "趣味連打", "stat_bias": {"hp": "中", "atk": "高", "def": "中", "spd": "極高"}, "notes": "清雜兵快樂組。"}},
  {"id": "orange_miejueshitai", "name": "滅絕師態", "canon": "滅絕師太", "weapon": "劍", "rarity": "橙", "base_power": 36,
   "personality": "剛烈、護短門派、嫉惡如仇到近乎極端；對魔教零容忍。",
   "background": "峨眉掌門，倚天劍意凌厲。俠村請其鎮魔教餘孽時一口答應——順便訓村中後輩「心要正、劍要狠」。",
   "appearance": {"resolution": 128, "silhouette": "尼袍、長劍、眉目嚴峻；劍勢直取中宮。", "palette_notes": "青灰尼袍＋劍寒光＋硃砂戒疤。", "signature_props": ["戒刀／長劍", "尼袍", "頭巾", "嚴正面孔"], "fx_tier": "絕學級：劍氣直線、大招滅字斬（原創字形特效）。"},
   "skills": [
     {"id": "mie_jian", "name": "滅劍三式", "desc": "高傷連斬，對邪道額外傷害。"},
     {"id": "e_mei_ci", "name": "峨眉刺", "desc": "突進刺擊，短暫封印治療。"},
     {"id": "hu_men", "name": "護門意志", "desc": "為友方承擔一次致命傷害。"},
     {"id": "jie_lv", "name": "戒律如鐵", "desc": "被動：對暗器／毒系敵人抗性提升。"},
   ],
   "growth": {"focus": "剛烈輸出與護短", "stat_bias": {"hp": "中", "atk": "高", "def": "中高", "spd": "中"}, "notes": "對魔教／刺客樓關卡加成。"}},
]


def write_one(h: dict) -> None:
    skills_md = "\n".join(f"- **{s['name']}**（`{s['id']}`）：{s['desc']}" for s in h["skills"])
    app = h["appearance"]
    alt = h.get("alt_name", "")
    alt_line = f"\n- **別名候選**：{alt}" if alt else ""
    md = f"""# {h['name']}（{h['rarity']}）

> 影射設定文檔｜墨點俠村｜招式皆原創改編名，唔用原著全稱。

## 基本
- **id**：`{h['id']}`
- **影射名**：{h['name']}
- **原聯想**：{h['canon']}{alt_line}
- **兵種**：{h['weapon']}
- **稀有**：{h['rarity']}
- **基礎戰力**：{h['base_power']}
- **性格**：{h['personality']}

## 背景（粵語繁中）
{h['background']}

## 外觀特徵（給美術）
- **目標解像**：{app['resolution']}×{app['resolution']}
- **剪影**：{app['silhouette']}
- **色盤備註**：{app['palette_notes']}
- **招牌道具**：{', '.join(app['signature_props'])}
- **特效階**：{app['fx_tier']}

## 技能（2–4）
{skills_md}

## 成長傾向
- **定位**：{h['growth']['focus']}
- **屬性偏向**：生命 {h['growth']['stat_bias']['hp']}／攻擊 {h['growth']['stat_bias']['atk']}／防禦 {h['growth']['stat_bias']['def']}／速度 {h['growth']['stat_bias']['spd']}
- **備註**：{h['growth']['notes']}

## 美術／演出備註
- 稀有度愈高愈華麗、特徵愈鮮明；紅階 256、橙階 128。
- 硬邊墨點、宣紙底、嚴格色盤；禁止寫實／盤外色／柔邊。
- 技能攻擊特效跟稀有度誇張度：橙明顯、紅神話級。
"""
    (OUT / f"{h['id']}.md").write_text(md, encoding="utf-8")
    with open(OUT / f"{h['id']}.json", "w", encoding="utf-8") as f:
        json.dump(h, f, ensure_ascii=False, indent=2)


def main() -> None:
    for h in REDS + ORANGES:
        write_one(h)
    index = {
        "version": 1,
        "red_count": len(REDS),
        "orange_count": len(ORANGES),
        "reds": [h["id"] for h in REDS],
        "oranges": [h["id"] for h in ORANGES],
        "note": "每俠客一份 .md + .json；招式原創名。",
    }
    with open(OUT / "index.json", "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    (OUT / "README.md").write_text(
        "# 俠客完整設定（橙／紅）\n\n"
        "Lemon 要求：橙同紅每位獨立認真設計——背景、性格、外觀、技能、成長。\n\n"
        "| 階 | 人數 | 解像目標 |\n|----|------|----------|\n"
        "| 紅 | 6 | 256×256 |\n| 橙 | 12 | 128×128 |\n\n"
        "檔名：`{id}.md`（人讀）＋ `{id}.json`（工具）。招式名皆原創改編，唔抄原著全稱。\n\n"
        "見 `index.json` 總表。\n",
        encoding="utf-8",
    )
    print(f"OK {len(REDS)} red + {len(ORANGES)} orange → {OUT}")


if __name__ == "__main__":
    main()
