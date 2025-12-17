% ---------- Domini e dati ----------
% Costanti utili
#const groups=8.
#const days=3.

% Gironi e giornate
group(1..groups).
day(1..days).

% Categorie
cat(seed;top;tier2;underdog).

% Continenti
cont(europe;concacaf;southamerica;asia;africa;oceania).

% 32 squadre etichettate 1..32
team(1..32).

% --- dati: continenti (10 EU, 4 CONCACAF, 8 SA, 4 AS, 4 AF, 2 OC) ---
continent( 1..10, europe).
continent(11..14, concacaf).
continent(15..22, southamerica).
continent(23..26, asia).
continent(27..30, africa).
continent(31..32, oceania).

% --- dati: categorie (8 per ciascuna) ---
category(1.. 8, seed).
category(9..16, top).
category(17..24, tier2).
category(25..32, underdog).


% ---------- 1 - Assegnazione squadre a gironi ----------
%  Scelta: ogni squadra appartiene a esattamente un girone
1 { in_group(T,G) : group(G) } 1 :- team(T).

% Esattamente UNA squadra per categoria in ogni girone
1 { in_group(T,G) : team(T), category(T,C) } 1 :- group(G), cat(C).

% ---------- 2 - Diversità continenti ----------
% In ogni girone devono essere rappresentati almeno 3 continenti
present(G,C) :- in_group(T,G), continent(T,C).
:- group(G), #count { C : present(G,C) } < 3.

% ---------- 3 - Generazione partite ----------
% Genera tutte le coppie di squadre in un girone
pair(T1,T2,G) :- in_group(T1,G), in_group(T2,G), T1 < T2. %T1 < T2 per evitare duplicati

% ---------- 4 - Pianificazione giornate ----------
% Ogni coppia gioca in una sola giornata
1 { plays(T1,T2,G,D) : day(D) } 1 :- pair(T1,T2,G).

% Una squadra non può giocare 0 o >1 partite nella stessa giornata (equivalente a "esattamente 1")
% ";" è un OR - T non può essere in più di una partita in giornata D (sia che sia prima o seconda delle coppie)
% se conteggio è 0 o >= 2, vincolo fallisce
:- in_group(T,G), day(D),
   not 1 { plays(T,T2,G,D) : pair(T,T2,G) ; plays(T1,T,G,D) : pair(T1,T,G) } 1. 

% ---------- Output ----------
#const raw = 0.     % metti -c raw=1 per mostrare anche in_group/2 e plays/4

#show skip/0.
skip :- 0 = 1.

#show in_group/2 : raw=1.
#show plays/4    : raw=1.

#script (python)
import sys
from collections import defaultdict

CAT_ABBR = {"seed": "S", "top": "T1", "tier2": "T2", "underdog": "U"}
CONT_ABBR = {
    "europe": "EU",
    "concacaf": "NA",
    "southamerica": "SA",
    "asia": "AS",
    "africa": "AF",
    "oceania": "OC",
}

RAW = 0

def friendly_team(t, cat_map, cont_map):
    cat = CAT_ABBR.get(cat_map.get(t, ""), "?")
    cont = CONT_ABBR.get(cont_map.get(t, ""), "?")
    return f"{t:02d}({cat}/{cont})"

def on_model(model):
    cat_map = {}
    cont_map = {}
    groups = defaultdict(list)
    matches = defaultdict(lambda: defaultdict(list))

    for sym in model.symbols(atoms=True):
        if sym.name == "category" and len(sym.arguments) == 2:
            t, c = sym.arguments
            cat_map[int(t.number)] = str(c)
        elif sym.name == "continent" and len(sym.arguments) == 2:
            t, c = sym.arguments
            cont_map[int(t.number)] = str(c)
        elif sym.name == "in_group" and len(sym.arguments) == 2:
            t, g = sym.arguments
            groups[int(g.number)].append(int(t.number))
        elif sym.name == "plays" and len(sym.arguments) == 4:
            t1, t2, g, d = sym.arguments
            matches[int(g.number)][int(d.number)].append((int(t1.number), int(t2.number)))

    for g in sorted(groups):
        teams = ", ".join(friendly_team(t, cat_map, cont_map) for t in sorted(groups[g]))
        print(f"\nGruppo {g}: {teams}")
        for d in sorted(matches[g]):
            day_matches = "; ".join(f"{t1:02d} vs {t2:02d}" for t1, t2 in sorted(matches[g][d]))
            print(f"  Giornata {d}: {day_matches}")

    if RAW:
        atoms = " ".join(
            [f"in_group({t},{g})" for g in sorted(groups) for t in sorted(groups[g])]
            + [
                f"plays({t1},{t2},{g},{d})"
                for g in sorted(matches)
                for d in sorted(matches[g])
                for t1, t2 in sorted(matches[g][d])
            ]
        )
        print(f"\n[raw] {atoms}\n")

def main(prg):
    global RAW
    const_raw = prg.get_const("raw")
    if const_raw is not None:
        try:
            RAW = int(const_raw.number)
        except Exception:
            pass
    prg.ground([("base", [])])
    with prg.solve(yield_=True) as handle:
        for model in handle:
            on_model(model)
#end.

% Esegui con:
%   clingo soccer-planner.lp --models=1 --quiet=1      (solo tabellone)
%   clingo soccer-planner.lp --models=1 --quiet=1 -c raw=1   (tabellone + atomi)
