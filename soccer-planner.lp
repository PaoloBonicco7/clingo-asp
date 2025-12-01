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


% ---------- Assegnazione squadre a gironi ----------
% Scelta: ogni squadra appartiene a esattamente un girone
1 { in_group(T,G) : group(G) } 1 :- team(T).

% Esattamente UNA squadra per categoria in ogni girone
1 { in_group(T,G) : team(T), category(T,C) } 1 :- group(G), cat(C).

% ---------- Diversità continenti ----------
% In ogni girone devono essere rappresentati almeno 3 continenti
present(G,C) :- in_group(T,G), continent(T,C).
:- group(G), #count { C : present(G,C) } < 3.

% ---------- Generazione partite ----------
pair(T1,T2,G) :- in_group(T1,G), in_group(T2,G), T1 < T2. %T1 < T2 per evitare duplicati

% ---------- Pianificazione giornate ----------
% Ogni coppia gioca in una sola giornata
1 { plays(T1,T2,G,D) : day(D) } 1 :- pair(T1,T2,G).

% Una squadra non può giocare 0 o >1 partite nella stessa giornata (equivalente a "esattamente 1")
:- in_group(T,G), day(D),
   not 1 { plays(T,T2,G,D) : pair(T,T2,G) ; plays(T1,T,G,D) : pair(T1,T,G) } 1.

% ---------- Output ----------
#show in_group/2.
#show plays/4.

% Pretty-print opzionale
#show pretty_group/2.
pretty_group(G,T) :- in_group(T,G)
.
#show pretty_match/5.
pretty_match(G,D,T1,T2,vs) :- plays(T1,T2,G,D).

% Esegui con: clingo soccer-planner.lp --models=1 --quiet=1,1