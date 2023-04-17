/* 
 * Projeto em SQL contendo os dados sobre a Covid-19 no mundo todo desde fevereiro de 2020 até abril de 2021
 * última data registrada na nossa base utilizada no projeto
 * Podemos encontrar a quantidade de pessoas infectadas, vacinadas e mortas por país, continente e dia.
 * Antes de realizarmos as queries foi necessário ajustar a o campo de data, pois o arquivo CSV trouxe as
 * datas desconfiguradas mesmo reimportando e configuração de acordo com o padrões americano ou brasileiro.
 * As datas estavam no formato ano/mês/dia, porém sem os "zeros à esquerda", com padrões de tamanho de 
 * 8,9 ou 10 caracteres.
*/

ALTER TABLE CovidDeaths ADD COLUMN _data TEXT;


---CRIEI UMA NOVA COLUNA DE DATA NO FORMATO ANO/MÊS/DIA (YYYY/MM/DD) UTILIZANDO OS COMANDOS
---CASE WHEN e SUBSTR:

UPDATE CovidDeaths SET _data = 
CASE 
  WHEN length(dt_ref) = 8 THEN 
   substr(dt_ref,5,4) || '-' || '0' || substr(dt_ref,1,1) || '-0' || substr(dt_ref,3,1)
  WHEN length(dt_ref) = 9 AND substr(dt_ref,2,1) = '/' THEN 
    substr(dt_ref,6,4) || '-0' || substr(dt_ref,1,1) || '-'||substr(dt_ref,3,2)
  WHEN length(dt_ref) = 9 AND substr(dt_ref,3,1) = '/' THEN 
    substr(dt_ref,6,4) || '-' || substr(dt_ref,1,2) || '-0' || substr(dt_ref,4,1)
  WHEN length(dt_ref) = 10 THEN 
    substr(dt_ref,7,4) || '-' || substr(dt_ref, 1,2) || '-' || substr(dt_ref,4,2)
  ELSE 
    NULL
END;

/* Seleção (01):
 * Selecione o total de mortes, total de casos, novos casos, novas mortes por data e por país.
 */

SELECT _data, location, new_cases, total_cases, new_deaths, total_deaths 
FROM CovidDeaths;

/* Seleção (02):
 * Mostre a probabilidade de morrer se contrair covid em cada país, por mês 
 * (quantidade de mortes/quantidade de infectados).
 */

WITH tb_total_mensal AS (
 SELECT
  location,
  STRFTIME ('%Y/%m', _data) AS ano_mes,
  SUM(new_cases) AS total_casos,
  SUM(new_deaths) AS total_mortes 
 FROM CovidDeaths
 GROUP BY location, ano_mes)
SELECT 
 location,
 ano_mes,
 ROUND(100*total_mortes/total_casos, 2) || '%' AS probabilidade_morte_percentual
FROM tb_total_mensal;

---usamos um WITH para realizar o cálculo da probabilidade através dos resultados obtidos na 
---primeira consulta (primeiro SELECT)

/* Seleção (03):
 * Selecione o total de casos e o total de população por país e por dia. 
 */

SELECT location, population, total_cases, STRFTIME('%d/%m/%Y', _data) as _data
FROM CovidDeaths;

/* Seleção (04):
 * Mostre a probabilidade de se infectar com Covid (a cada mil habitantes)
 * por país e por mês (quantidade de infectados/população).
 */

SELECT 
 STRFTIME ('%Y/%m', _data) AS ano_mes,
 location,
 MAX(1000*total_cases/population) AS taxa_infeccao_por_mil
FROM CovidDeaths
GROUP BY location, ano_mes;

/* Seleção (05):
 * Quais são os países com maior taxa de infecção a cada mil habitantes?
 */

SELECT 
 location,
 MAX(1000*total_cases/population) AS taxa_infeccao_por_mil
FROM CovidDeaths
GROUP BY location
ORDER BY taxa_infeccao_por_mil DESC;

/* Seleção (06):
 * Quais são os países com maior taxa de morte?
 */

SELECT
 *,
 round(total_mortes/total_casos * 100,4) AS taxa_mortalidade
 FROM( 
 SELECT 
  location,
  SUM(new_cases) AS total_casos,
  SUM(new_deaths) AS total_mortes
 FROM CovidDeaths
 GROUP BY location
)
ORDER BY taxa_mortalidade DESC;

/* Seleção (07):
 * Mostre os continentes com a maior taxa de morte.
 */

SELECT
 *,
 round(total_mortes/total_casos * 100,4) || '%' AS taxa_mortalidade
 FROM( 
 SELECT 
  continent,
  SUM(new_cases) AS total_casos,
  SUM(new_deaths) AS total_mortes
 FROM CovidDeaths
 WHERE continent IN ('Oceania', 'Europe', 'North America', 'South America', 'Africa', 'Asia')
 GROUP BY continent 
)
ORDER BY taxa_mortalidade DESC;

/*
 foi usado um filtro IN na cláusula WHERE, porque o continente também era encontrado no campo 
 “location” e, consequentemente, ficava em branco na coluna “continent”. 
 Neste caso, preferi usar o filtro, mas uma outra solução plausível seria a limpeza dos dados, 
 excluindo os registros que continham o continente informado na coluna destinada ao país.
 */


/* Seleção (08):
 * Criar uma view de uma consulta que mostre a porcentagem da população que recebeu pelo menos uma 
 * dose da vacina contra a Covid-19, contendo o dia, país, quantidade de pessoas vacinadas, população 
 * e porcentagem de pessoa vacinadas dia a dia.
*/

CREATE VIEW vacinados AS
SELECT
 cv.location,
 STRFTIME('%d/%m/%Y', cv._data) AS dia,
 cv.people_vaccinated,
 cd.population,
 ROUND((CAST(100*cv.people_vaccinated AS FLOAT))/cd.population,4) || '%' AS taxa_vacinada
FROM covidvaccinations AS cv
INNER JOIN coviddeaths AS cd
ON (
 cv.iso_code = cd.iso_code
 AND cv._data = cd._data 
);

/* foi feita a junção de 2 tabelas através do comando INNER JOIN e foi passado como referência 2 
campos (por garantia) em comum das tabelas (iso_code e _data).
Foi criada a view denominada vacinados para armazenar a consulta para quando quisermos visualizá-la 
novamente, bastando acessar o comando SELECT * FROM vacinados;
*/
