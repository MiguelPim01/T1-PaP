PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dbp: <http://dbpedia.org/property/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://dbpedia.org/resource/Drama_(film_and_television)>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

select distinct ?nome ?paisNascimento ?dataNascimentoFormatted ?clubeNome ?posicaoLabel ?altura ?numeroCamisa (max(?allGols) as ?gols) ?liga where {
  
  # Pegando as instâncias de SoccerPlayer e o nome do jogador.
  ?sub a dbo:SoccerPlayer .
  ?sub rdfs:label ?nome .
  FILTER (LANG(?nome) = "pt") .
  
  # Pegando o país de nascimento do jogador.
  ?sub dbo:birthPlace ?localNascimento .
  OPTIONAL { 
    ?localNascimento dbo:country ?paisNascimentoURI . 
  	?paisNascimentoURI rdfs:label ?paisNascimento .
   	FILTER (LANG(?paisNascimento) = "pt") .
  }
  
  # Pegando a data de nascimento do jogador.
  ?sub dbp:birthDate ?dataNascimento .
  
  # Pegando o clube em que o jogador está jogando.
  ?sub dbp:currentclub ?clubeAtual .
  ?clubeAtual rdfs:label ?clubeNome .
  FILTER (LANG(?clubeNome) = "pt") .
  
  # Pegando a posição em que o jogador joga.
  ?sub dbp:position ?posicao .
  ?posicao rdfs:label ?posicaoLabel .
  FILTER (LANG(?posicaoLabel) = "pt") .
  
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
  FILTER (LANG(?liga) = "pt") .
  
  
  # Filtrando variáveis que devem ser URIs.
  FILTER (isURI(?clubeAtual)) .
  FILTER (isURI(?paisNascimentoURI)) .
  
  # Transformando as datas de nascimento do formato dateTime para date.
  BIND (
    IF (datatype(?dataNascimento) = xsd:dateTime, STRDT(STR(?dataNascimento), xsd:date), ?dataNascimento)
    AS ?dataNascimentoFormatted
  )
  
} LIMIT 10000
