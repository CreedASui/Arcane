# the minimap button's phrases: rows for Locale.lua (en fr de es pt) and the six generated languages
import re, sys
D = sys.argv[1]
P = [
 ("Minimap button",
  dict(fr="Bouton de la minicarte", de="Minikarten-Knopf", es="Botón del minimapa", pt="Botão do minimapa",
       zh="小地图按钮", ru="Кнопка на миникарте", ja="ミニマップのボタン", ko="미니맵 버튼", pl="Przycisk na minimapie", tr="Mini harita düğmesi")),
 ("A round Arcane button on the minimap's edge: click it for this menu, right-click it to move or lock the frames, drag it along the edge to place it. /Arcane opens the menu too.",
  dict(fr="Un bouton Arcane rond au bord de la minicarte : cliquez pour ce menu, clic droit pour déplacer ou verrouiller les cadres, glissez-le le long du bord pour le placer. /Arcane ouvre aussi le menu.",
       de="Ein runder Arcane-Knopf am Rand der Minikarte: Klick öffnet dieses Menü, Rechtsklick verschiebt oder sperrt die Rahmen, am Rand entlang ziehen platziert ihn. /Arcane öffnet das Menü ebenfalls.",
       es="Un botón Arcane redondo en el borde del minimapa: haz clic para este menú, clic derecho para mover o bloquear los marcos, arrástralo por el borde para colocarlo. /Arcane también abre el menú.",
       pt="Um botão Arcane redondo na borda do minimapa: clique para este menu, clique direito para mover ou travar os quadros, arraste pela borda para posicioná-lo. /Arcane também abre o menu.",
       zh="小地图边缘的圆形 Arcane 按钮：点击打开此菜单，右键移动或锁定框体，沿边缘拖动来摆放。输入 /Arcane 也能打开菜单。",
       ru="Круглая кнопка Arcane на краю миникарты: щелчок открывает это меню, правый щелчок — двигать или закрепить рамки; перетащите её вдоль края, чтобы поставить. /Arcane тоже открывает меню.",
       ja="ミニマップの縁にある丸い Arcane ボタン：クリックでこのメニュー、右クリックでフレームの移動・固定、縁に沿ってドラッグして配置。/Arcane でもメニューを開けます。",
       ko="미니맵 가장자리의 둥근 Arcane 버튼: 클릭하면 이 메뉴, 오른쪽 클릭으로 창 이동/잠금, 가장자리를 따라 끌어 위치를 정합니다. /Arcane 로도 메뉴를 열 수 있습니다.",
       pl="Okrągły przycisk Arcane na brzegu minimapy: kliknięcie otwiera to menu, prawy przycisk przesuwa lub blokuje ramki, przeciągnij go wzdłuż brzegu, by go ustawić. /Arcane też otwiera menu.",
       tr="Mini haritanın kenarında yuvarlak bir Arcane düğmesi: tıklayınca bu menü açılır, sağ tıkla çerçeveleri taşı ya da kilitle, yerleştirmek için kenar boyunca sürükle. /Arcane de menüyü açar.")),
 ("Click: open or close the menu",
  dict(fr="Clic : ouvrir ou fermer le menu", de="Klick: Menü öffnen oder schließen", es="Clic: abrir o cerrar el menú", pt="Clique: abrir ou fechar o menu",
       zh="点击：打开或关闭菜单", ru="Щелчок: открыть или закрыть меню", ja="クリック：メニューを開く・閉じる", ko="클릭: 메뉴 열기/닫기",
       pl="Kliknięcie: otwórz lub zamknij menu", tr="Tıkla: menüyü aç ya da kapat")),
 ("Right-click: move the frames",
  dict(fr="Clic droit : déplacer les cadres", de="Rechtsklick: Rahmen verschieben", es="Clic derecho: mover los marcos", pt="Clique direito: mover os quadros",
       zh="右键：移动框体", ru="Правый щелчок: двигать рамки", ja="右クリック：フレームを移動", ko="오른쪽 클릭: 창 이동",
       pl="Prawy przycisk: przesuń ramki", tr="Sağ tık: çerçeveleri taşı")),
 ("Right-click: lock the frames",
  dict(fr="Clic droit : verrouiller les cadres", de="Rechtsklick: Rahmen sperren", es="Clic derecho: bloquear los marcos", pt="Clique direito: travar os quadros",
       zh="右键：锁定框体", ru="Правый щелчок: закрепить рамки", ja="右クリック：フレームを固定", ko="오른쪽 클릭: 창 잠금",
       pl="Prawy przycisk: zablokuj ramki", tr="Sağ tık: çerçeveleri kilitle")),
 ("Drag: slide it along the minimap's edge",
  dict(fr="Glisser : le faire glisser au bord de la minicarte", de="Ziehen: am Rand der Minikarte verschieben", es="Arrastrar: moverlo por el borde del minimapa",
       pt="Arrastar: movê-lo pela borda do minimapa", zh="拖动：沿小地图边缘移动", ru="Перетаскивание: сдвинуть вдоль края миникарты",
       ja="ドラッグ：ミニマップの縁に沿って移動", ko="끌기: 미니맵 가장자리를 따라 이동", pl="Przeciągnij: przesuń wzdłuż brzegu minimapy",
       tr="Sürükle: mini haritanın kenarında kaydır")),
 ("drag the frames, then right-click the Arcane button to lock them.",
  dict(fr="glissez les cadres, puis faites un clic droit sur le bouton Arcane pour les verrouiller.",
       de="Rahmen ziehen, dann mit Rechtsklick auf den Arcane-Knopf sperren.",
       es="arrastra los marcos y luego haz clic derecho en el botón Arcane para bloquearlos.",
       pt="arraste os quadros e depois clique com o botão direito no botão Arcane para travá-los.",
       zh="拖动框体，然后右键点击 Arcane 按钮锁定。", ru="перетащите рамки, затем щёлкните правой кнопкой по кнопке Arcane, чтобы закрепить их.",
       ja="フレームをドラッグして、Arcane ボタンを右クリックで固定。", ko="창을 끈 다음 Arcane 버튼을 오른쪽 클릭해 잠그세요.",
       pl="przeciągnij ramki, potem kliknij prawym przyciskiem przycisk Arcane, by je zablokować.",
       tr="çerçeveleri sürükle, sonra kilitlemek için Arcane düğmesine sağ tıkla.")),
 ("the minimap button stopped after an error: ",
  dict(fr="le bouton de la minicarte s'est arrêté après une erreur : ", de="der Minikarten-Knopf hat nach einem Fehler gestoppt: ",
       es="el botón del minimapa se detuvo tras un error: ", pt="o botão do minimapa parou após um erro: ", zh="小地图按钮出错后已停止：",
       ru="кнопка на миникарте остановлена после ошибки: ", ja="ミニマップのボタンがエラーで止まりました：", ko="미니맵 버튼이 오류로 멈췄습니다: ",
       pl="przycisk na minimapie zatrzymał się po błędzie: ", tr="mini harita düğmesi bir hatadan sonra durdu: ")),
]

def q(s): return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

# Locale.lua: the six interface rows after the clock's note, the error row at the end of its section
loc = open(D + "/Locale.lua", encoding="utf-8").read()
if "Minimap button" not in loc:
    def row(en, t):
        return "\t{ " + q(en) + ",\n\t\t" + ",\n\t\t".join(q(t[c]) for c in ("fr", "de", "es", "pt")) + " },\n"
    rows = "".join(row(en, t) for en, t in P[:7])
    anchor = "\t{ \"Chests on the minimap\""
    assert loc.count(anchor) == 1
    loc = loc.replace(anchor, "\t-- the minimap's button\n" + rows + anchor)
    last = "\t{ \"couldn't dress the minimap: \""
    i = loc.index(last); j = loc.index("\n", i) + 1
    loc = loc[:j] + row(*P[7]) + loc[j:]
    open(D + "/Locale.lua", "w", encoding="utf-8").write(loc)

# en_keys and the numbered dicts
HERE = sys.path[0]
kp = HERE + "/../en_keys.txt"
keys = open(kp, encoding="utf-8").read().split("\n")
new = [en for en, _ in P if en not in keys]
start = len(keys) + 1
if new:
    open(kp, "w", encoding="utf-8").write("\n".join(keys + new))
    for code in ("zh", "ru", "ja", "ko", "pl", "tr"):
        p = HERE + "/" + code + ".py"
        s = open(p, encoding="utf-8").read().rstrip()
        assert s.endswith("}")
        add = "".join("%d: %s,\n" % (start + n, q(dict(P)[en][code])) for n, en in enumerate(new))
        s = s[:-1] + add + "}\n"
        open(p, "w", encoding="utf-8").write(s)
print("added", len(new), "from", start)
