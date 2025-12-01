# Clingo Cheat Sheet

# 1) Lessico minimo
- **Atomo**: un fatto come `edge(a,b).`
- **Regola**: `head :- body.` (se `body` è vero, allora `head` deve esserlo)
- **Negazione debole**: `not p(X)` = “non risulta provato che `p(X)`”
- **Negazione forte**: `-p(X)` = “è vero il contrario di `p(X)`”
- **Vincolo (integrity constraint)**: `:- body.` (proibisce i modelli che soddisfano `body`)
- **Modello/Answer set**: un insieme di atomi vero e coerente con tutte le regole

# 2) Fatti e regole
```prolog
% fatti (dominio)
person(alice). person(bob).

% regola
friend(X,Y) :- person(X), person(Y), X != Y.
```
Esegui: `clingo file.lp`

# 3) Scelta e cardinalità
- **Regola di scelta**: permette di selezionare sottoinsiemi.
```prolog
color(red;green;blue).
node(a;b;c).

% assegna 1 colore per nodo
1 { assign(N,C) : color(C) } 1 :- node(N).
```
- Forma generale: `L { literals } U` con limiti `L`/`U` (opzionali).

# 4) Vincoli
```prolog
% vieta stesso colore su nodi adiacenti
edge(a,b). edge(b,c).
:- assign(X,C), assign(Y,C), edge(X,Y).
```

# 5) Aggregati utili
```prolog
% conta quanti nodi sono blu
blue_count(C) :- C = #count { N : assign(N,blue) }.

% vincola massimo 1 blu
:- #count { N : assign(N,blue) } > 1.
```
Aggregati comuni: `#count`, `#sum`, `#min`, `#max`.

# 6) Ottimizzazione
Due modi equivalenti:

**a) Direttive #minimize / #maximize**
```prolog
% minimizza il numero di nodi blu
#minimize { 1,N : assign(N,blue) }.
```

**b) Vincoli deboli (weak constraints)**
```prolog
:~ assign(N,blue). [1@1,N]
```
- `[peso@priorità,tuple]` → minimizza la somma dei pesi (priorità più alta = livello più importante).

Esecuzione tipica:  
`clingo model.lp --opt-mode=optN` (vai alla soluzione ottima)

# 7) Controllo dell’output
- **#show** per filtrare cosa stampare:
```prolog
#show assign/2.
```
- Senza `#show`, Clingo mostra tutto ciò che deriva.

# 8) Costanti e parametri
- Definisci in codice: `#const k=3.`
- Sovrascrivi da CLI: `clingo file.lp -c k=5`

# 9) Struttura tipica di un modello ASP
1. **Dichiarazione del dominio**: fatti base e insiemi (`node/1`, `color/1`…)
2. **Generazione**: regole di scelta per creare candidati (`{ … }`)
3. **Definizione**: regole deduttive derivate
4. **Vincoli**: `:- …` per eliminare candidati invalidi
5. **Ottimizzazione** (opzionale): `#minimize` / vincoli deboli
6. **#show** (opzionale) per pulire l’output

# 10) Comandi CLI più usati
- `clingo file.lp` — risolve e mostra i modelli
- `clingo file.lp 0` — mostra **tutti** i modelli trovati
- `--models=N` — limita il numero di modelli
- `--time-limit=SEC` — tempo massimo
- `--opt-mode=optN` — cerca soluzione ottima
- `--quiet=1` / `-q` — output più compatto
- `--outf=2` — output JSON (per integrazioni/tooling)
- `-c k=v` — imposta costante `k` (parametrizzazione)

# 11) Micro–esempio completo (colorazione 3-colori)
```prolog
node(a;b;c).
edge(a,b). edge(b,c). edge(a,c).
color(red;green;blue).

1 { assign(N,C) : color(C) } 1 :- node(N).
:- assign(X,C), assign(Y,C), edge(X,Y).

#minimize { 1,N : assign(N,blue) }.
#show assign/2.
```
Esegui:
```
clingo coloring.lp --opt-mode=optN
```

---

Se vuoi, preparo un **template di progetto** (con file separati `domain.lp`, `generate.lp`, `test.lp`) e una **task di ottimizzazione** reale (es. scheduling turni) tutta in `.lp`.