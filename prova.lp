% fatti (dominio)
person(alice). person(bob).

% regola
friend(X,Y) :- person(X), person(Y), X != Y.