%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dominî di base
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

week(1..24).           % settimane del master

% giorni: 1=lun, 2=mar, 3=mer, 4=gic, 5=ven, 6=sab
day(1..6).

% ore nel giorno (slot da 1 ora)
hour(1..8).

% settimane full-time (lun-sab)
fulltime_week(7;16).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Insegnamenti, docenti e ore totali
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

teaching(pm).          teacher(pm,muzzetto).             hours(pm,14).   % Project Management
teaching(ict).         teacher(ict,pozzato).             hours(ict,14).  % Fondamenti ICT
teaching(markup).      teacher(markup,schifanella_r).    hours(markup,20). % Linguaggi di markup
teaching(qualita).     teacher(qualita,tomatis).         hours(qualita,10). % Qualità
teaching(client).      teacher(client,micalizio).        hours(client,20). % Ambienti client-side
teaching(grafica_int). teacher(grafica_int,terranova).   hours(grafica_int,10). % Progettazione grafica/UI

teaching(basi_dati).   teacher(basi_dati,mazzei).        hours(basi_dati,20).
teaching(social_tools). teacher(social_tools,giordani).  hours(social_tools,14).
teaching(img_static).  teacher(img_static,zanchetta).    hours(img_static,14).
teaching(access).      teacher(access,gena).             hours(access,14).
teaching(marketing).   teacher(marketing,muzzetto).      hours(marketing,10).
teaching(foto).        teacher(foto,vargiu).             hours(foto,10).
teaching(risorse).     teacher(risorse,boniolo).         hours(risorse,10).

teaching(server).      teacher(server,damiano).          hours(server,20).
teaching(tech_mark).   teacher(tech_mark,zanchetta).     hours(tech_mark,10).
teaching(intro_sm).    teacher(intro_sm,suppini).        hours(intro_sm,14).
teaching(suono).       teacher(suono,valle).             hours(suono,10).
teaching(seq_img).     teacher(seq_img,ghidelli).        hours(seq_img,20).
teaching(comunicazione). teacher(comunicazione,gabardi). hours(comunicazione,14).
teaching(semiologia).  teacher(semiologia,santangelo).   hours(semiologia,10).

teaching(crossmedia).  teacher(crossmedia,taddeo).       hours(crossmedia,20).
teaching(grafica3d).   teacher(grafica3d,gribaudo).      hours(grafica3d,20).
teaching(mobile1).     teacher(mobile1,schifanella_r).   hours(mobile1,10).
teaching(mobile2).     teacher(mobile2,schifanella_c).   hours(mobile2,10).
teaching(hr).          teacher(hr,lombardo).             hours(hr,10).
teaching(diritto).     teacher(diritto,travostino).      hours(diritto,10).

prof(P) :- teacher(_,P).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Slot orari disponibili
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Venerdì (5): 8 ore, ogni settimana
slot(W,5,H) :- week(W), H=1..8.

% Sabato (6): 6 ore, ogni settimana
slot(W,6,H) :- week(W), H=1..6.

% Settimane full-time (7 e 16): lun-ven (1..5) 8 ore
slot(W,D,H) :- fulltime_week(W), D=1..5, H=1..8.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mappatura (W,D,H) -> tempo lineare (per confronti)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

time(W,D,H,Time) :- slot(W,D,H), Time = W*100 + D*10 + H.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ausiliari: prima/ultima lezione e settimana
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

first_time(T,FT) :-
    teaching(T),
    FT = #min{ Time : lecture(T,W,D,H), time(W,D,H,Time) }.

last_time(T,LT) :-
    teaching(T),
    LT = #max{ Time : lecture(T,W,D,H), time(W,D,H,Time) }.

first_week(T,FW) :-
    teaching(T),
    FW = #min{ W : lecture(T,W,_,_) }.

last_week(T,LW) :-
    teaching(T),
    LW = #max{ W : lecture(T,W,_,_) }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scelta delle lezioni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% In ogni slot, al più un insegnamento
{ lecture(T,W,D,H) : teaching(T) } <= 1 :- slot(W,D,H).

% Totale ore per insegnamento = ore richieste
:- teaching(T), hours(T,Tot), Tot != #count{W,D,H : lecture(T,W,D,H)}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vincoli
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Vincolo: docente max 4 ore al giorno
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prof_hour(W,D,P,H) :- lecture(T,W,D,H), teacher(T,P).

:- prof(P), week(W), day(D),
   N = #count{H : prof_hour(W,D,P,H)},
   N > 4.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Vincolo: ogni insegnamento 2,3 o 4 ore nello stesso giorno
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Vietata giornata con 1 sola ora
:- teaching(T), week(W), day(D),
   1 = #count{H : lecture(T,W,D,H)}.

% Vietata giornata con più di 4 ore
:- teaching(T), week(W), day(D),
   N = #count{H : lecture(T,W,D,H)},
   N > 4.

% Le ore di uno stesso insegnamento nello stesso giorno devono formare un unico blocco contiguo
:- lecture(T,W,D,H1), lecture(T,W,D,H2), H2 >= H1 + 2, not lecture(T,W,D,H1+1).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Vincolo: il primo giorno di lezione prevede che, nelle prime due ore, vi sia la presentazione del master
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Nessuna lezione il primo venerdì, ore 1-2
:- lecture(_,1,5,1..2).
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Vincolo: almeno 6 blocchi liberi da 2 ore consecutive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

occupied(W,D,H) :- lecture(_,W,D,H).

free_block(W,D,H) :-
    slot(W,D,H),
    H2 = H+1,
    slot(W,D,H2),
    not occupied(W,D,H),
    not occupied(W,D,H2).

% almeno 6 blocchi liberi non sovrapposti (contiamo solo l'inizio di ciascun blocco)
free_block_start(W,D,H) :- free_block(W,D,H), H = 1.
free_block_start(W,D,H) :- free_block(W,D,H), H > 1, not free_block(W,D,H-1).

:- 0 { free_block_start(W,D,H) } 5.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Vincolo Project Management finisce entro settimana 7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- lecture(pm,W,_,_), W > 7.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Vincolo: Prima lezione di Access prima che termini markup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- first_time(access,FA),
   last_time(markup,LM),
   FA >= LM.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Vincolo: distanza max 8 settimane tra prima e ultima lezione
% (nessuna coppia di settimane dello stesso corso con distanza >= 9)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- teaching(T),
   week(W1), week(W2),
   W2 >= W1 + 9,
   lecture(T,W1,_,_),
   lecture(T,W2,_,_).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. Vincolo: Tecnologie server-side -> 5 blocchi da 4 ore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% vietato che server faccia esattamente 2 ore in un giorno
:- week(W), day(D),
   2 = #count{H : lecture(server,W,D,H)}.

% vietato che server faccia esattamente 3 ore in un giorno
:- week(W), day(D),
   3 = #count{H : lecture(server,W,D,H)}.

% (1 e >4 sono già esclusi dai vincoli generali; con 20 ore restano 5×4)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Vincolo: Crossmedia e Intro SM -> prima lezione in settimana 16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- first_week(crossmedia,FW), FW != 16.
:- first_week(intro_sm,FW),   FW != 16.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 10. Vincolo: Propedeuticità
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pre(ict,        client).
pre(client,     mobile1).
pre(mobile1,    mobile2).
pre(basi_dati,  server).
pre(markup,     client).
pre(pm,         marketing).
pre(marketing,  tech_mark).
pre(pm,         social_tools).
pre(pm,         grafica_int).
pre(img_static, foto).
pre(foto,       seq_img).
pre(img_static, grafica3d).

:- pre(Prev,Next),
   last_time(Prev,LP),
   first_time(Next,FN),
   FN <= LP.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#show lecture/4.

% Esegui con: clingo master-timetable-planner.lp 0              (genera tutti i modelli)
% Esegui con: clingo master-timetable-planner.lp --models=1     (genera un solo modello)
