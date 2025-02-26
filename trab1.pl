:- data_source(dbpedia_jogadores,
               sparql("
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
  PREFIX dbp: <http://dbpedia.org/property/>
  PREFIX dbo: <http://dbpedia.org/ontology/>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  
  select distinct ?nome ?paisNascimento ?dataNascimentoFormatted ?clubeNome ?posicaoLabel ?altura ?numeroCamisa ?allGols ?liga where {
  
  # Pegando as instâncias de SoccerPlayer e o nome do jogador.
  ?sub rdf:type dbo:SoccerPlayer .
  ?sub rdfs:label ?nome .
  FILTER (LANG(?nome) = 'en') .
  
  # Pegando o país de nascimento do jogador.
  ?sub dbo:birthPlace ?localNascimento .
  OPTIONAL { 
    ?localNascimento dbo:country ?paisNascimentoURI . 
  	?paisNascimentoURI rdfs:label ?paisNascimento .
   	FILTER (LANG(?paisNascimento) = 'en') .
  }
  
  # Pegando a data de nascimento do jogador.
  ?sub dbp:birthDate ?dataNascimento .
  
  # Pegando o clube em que o jogador está jogando.
  ?sub dbp:currentclub ?clubeAtual .
  ?clubeAtual rdfs:label ?clubeNome .
  FILTER (LANG(?clubeNome) = 'en') .
  
  # Pegando a posição em que o jogador joga.
  ?sub dbp:position ?posicao .
  ?posicao rdfs:label ?posicaoLabel .
  FILTER (LANG(?posicaoLabel) = 'en') .
  
  # Pegando a altura do jogador.
  ?sub dbo:height ?altura .
  FILTER (datatype(?altura) = xsd:double) .
  
  # Pegando o número da camisa do jogador.
  ?sub dbp:clubnumber ?numeroCamisa .
  FILTER (datatype(?numeroCamisa) = xsd:integer) .
  
  # Pegando a lista de gols do jogador, onde apenas o máximo dessa lista representa a quantidade real de gols dele.
  ?sub dbp:goals ?allGols .
  FILTER (datatype(?allGols) = xsd:integer) .
  
  # Pegando a liga em que o jogador joga.
  ?clubeAtual dbo:league ?ligaURI .
  ?ligaURI rdfs:label ?liga .
  FILTER (LANG(?liga) = 'en') .
  
  
  # Filtrando variáveis que devem ser URIs.
  FILTER (isURI(?clubeAtual)) .
  FILTER (isURI(?paisNascimentoURI)) .
  
  # Transformando as datas de nascimento do formato dateTime para date.
  BIND (
    IF (datatype(?dataNascimento) = xsd:dateTime, STRDT(STR(?dataNascimento), xsd:date), ?dataNascimento)
    AS ?dataNascimentoFormatted
  )
  
}", [ endpoint("https://dbpedia.org/sparql") ])).



jogadores(Nome, PaisNascimento, DataNascimento, Clube, Posicao, Altura, NumeroCamisa, Gols, Liga) :- 
    dbpedia_jogadores{nome:Nome, paisNascimento:PaisNascimento,dataNascimentoFormatted:DataNascimento,
              clubeNome:Clube, posicaoLabel:Posicao, altura:Altura, numeroCamisa:NumeroCamisa,
              allGols:Gols, liga:Liga}.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em obtermos quais jogadores são conteporâneos, ou seja, que nasceram no mesmo ano.

jogadores_contemporaneos(Nome1, Nome2) :-
    jogadores(Nome1, _, DataNascimento1, _, _, _, _, _, _),
    jogadores(Nome2, _, DataNascimento2, _, _, _, _, _, _),
    Nome1 \= Nome2,
    extrair_ano(DataNascimento1, Ano),
    extrair_ano(DataNascimento2, Ano).

extrair_ano(date(Ano, _, _), Ano) :- !.
extrair_ano(Data, Ano) :-
    atom(Data),
    sub_string(Data, 0, 4, _, AnoString),
    atom_number(AnoString, Ano).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- jogadores_contemporaneos(Nome1, Nome2).
?- jogadores_contemporaneos("Hoy Phallin", Nome2).
?- jogadores_contemporaneos("Hoy Phallin", "Brian Anunga").
?- jogadores_contemporaneos("Hoy Phallin", "Reung Bunheing").

 */


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que jogam no mesmo clube.

jogadores_parceiros(Nome1, Nome2, Clube) :-
    jogadores(Nome1, _, _, Clube, _, _, _, _, _),
    jogadores(Nome2, _, _, Clube, _, _, _, _, _),
    Nome1 \= Nome2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples> 
?- jogadores_parceiros(Nome1, Nome2, Clube).
?- jogadores_parceiros(Nome1, Nome2, "Visakha FC").
?- jogadores_parceiros("Reung Bunheing", "Sa Ty", "Visakha FC").
?- jogadores_parceiros("Paul Garita", "Marius Constantin", "Hong Kong FC (football)").

 */


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que jogam no mesmo clube, que nasceram no mesmo país e que jogam
% em posições diferentes.

jogadores_super_parceiros(Nome1, Nome2, Pais) :-
    jogadores(Nome1, Pais, _, Clube, Posicao1, _, _, _, _),
    jogadores(Nome2, Pais, _, Clube, Posicao2, _, _, _, _),
    Nome1 \= Nome2,
    Posicao1 \= Posicao2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples> 
?- jogadores_super_parceiros(Nome1, Nome2, Pais).
?- jogadores_super_parceiros(Nome1, Nome2, "Cameroon").
?- jogadores_super_parceiros("Reung Bunheing", "Chrerng Polroth", "Cambodia").
?- jogadores_super_parceiros("Samuel Edoung-Biyo", "Woobens Pacius", "Canada").

 */


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que são atacantes, tem número de camisa 9 e tem mais de 50 gols.

centro_avante_goleador(Nome, Gols) :-
    jogadores(Nome, _, _, _, "Forward (association football)", _, NumeroCamisa, Gols, _),
    NumeroCamisa =:= 9,
    Gols > 50.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- centro_avante_goleador(Nome, Gols).
?- centro_avante_goleador(Nome, 50).
?- centro_avante_goleador("Abdulfattah Adam", 51).
?- centro_avante_goleador("Jelle Vossen", 100).

 */


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que são concorrentes, ou seja, jogam no mesmo clube e na mesma
% posição. Por isso, eles concorrem a posição que eles jogam.

jogadores_concorrentes(Nome1, Nome2, Posicao, Clube) :-
    jogadores(Nome1, _, _, Clube, Posicao, _, _, _, _),
    jogadores(Nome2, _, _, Clube, Posicao, _, _, _, _),
    Nome1 \= Nome2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- jogadores_concorrentes(Nome1, Nome2, Posicao, "Visakha FC").
?- jogadores_concorrentes(Nome1, Nome2, "Forward (association football)", Clube).
?- jogadores_concorrentes("Paul Ngue", "Léo (footballer, born 1992)", "Forward (association football)", "Hong Kong FC (football)").
?- jogadores_concorrentes("Paulo Victor (footballer, born 1994)", "Paul Ngue","Forward (association football)", "Visakha FC").

 */



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que são rivais, ou seja, jogam na mesma liga e em times
% diferentes.

jogadores_rivais(Nome1, Nome2, Liga) :- 
    jogadores(Nome1, _, _, Clube1, _, _, _, _, Liga),
    jogadores(Nome2, _, _, Clube2, _, _, _, _, Liga),
    Nome1 \= Nome2,
	Clube1 \= Clube2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- jogadores_rivais(Nome1, Nome2, Liga).
?- jogadores_rivais(Nome1, Nome2, "Cambodian Premier League").
?- jogadores_rivais("Sor Rotana", "Hoy Phallin", "Cambodian League 2").
?- jogadores_rivais("Keo Soksela", "Ol Ravy", "Cambodian Premier League").

 */



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 7 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar goleiros bons, ou seja, jogadores que jogam na posição goleiro, com mais
% de um 1,90 de altura e com pelo menos 1 gol.

goleiro_bom(Nome, Altura, Gols) :- 
    jogadores(Nome, _, _, _, "Goalkeeper (association football)", Altura, _, Gols, _),
    Altura >= 1.90,
    Gols >= 1.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- goleiro_bom(Nome, Altura, Gols).
?- goleiro_bom(Nome, 1.90, Gols).
?- goleiro_bom("Alin Bota", 1.93, 21).
?- goleiro_bom("Igor Dovgyallo", 1.98, 1).

 */



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REGRA 8 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esta regra consiste em achar jogadores que são camisa 10 e não tem nenhum gol. Para dar um ar mais
% humoristico a essa regra, iremos chama-la de jogadores_camisa_10_da_shoppe

jogadores_camisa_10_da_shoppe(Nome, Gols, NumeroCamisa) :- 
    jogadores(Nome, _, _, _, _, _, NumeroCamisa, Gols, _),
    Gols =:= 0,
    NumeroCamisa =:= 10.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSULTAS PRE-DEFINIDAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/** <examples>
?- jogadores_camisa_10_da_shoppe(Nome, Gols, NumeroCamisa).
?- jogadores_camisa_10_da_shoppe("Lionel Enguene", Gols, NumeroCamisa).
?- jogadores_camisa_10_da_shoppe("Alexis Meva", 0, 10).
?- jogadores_camisa_10_da_shoppe("Ol Ravy", 0, 10).

 */
