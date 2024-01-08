
/*
Tutaj zdefiniuj schemę `reporting`
*/
CREATE SCHEMA IF NOT EXISTS reporting;
/*
Tutaj napisz definicję widoku reporting.flight, która:
- będzie usuwać dane o lotach anulowanych `cancelled = 0`
- będzie zawierać kolumnę `is_delayed`, zgodnie z wcześniejszą definicją tj. `is_delayed = 1 if dep_delay_new > 0 else 0` (zaimplementowana w SQL)

Wskazówka:
- SQL - analiza danych > Dzień 4 Proceduralny SQL > Wyrażenia warunkowe
- SQL - analiza danych > Przygotowanie do zjazdu 2 > Widoki
*/
CREATE OR REPLACE VIEW reporting.flight AS
SELECT
    id,
    origin_airport_id,
    dest_airport_id,
    name,
    destination_city_name,
    year,
    month,
    day_of_week,
    dep_delay,
    cancelled,
    CASE WHEN dep_delay > 0 THEN 1 ELSE 0 END AS is_delayed
FROM
    public.flight
WHERE
    cancelled = 0
;
/*
Tutaj napisz definicję widoku reporting.top_reliability_roads, która będzie zawierała następujące kolumny:
- `origin_airport_id`,
- `origin_airport_name`,
- `dest_airport_id`,
- `dest_airport_name`,
- `year`,
- `cnt` - jako liczba wykonananych lotów na danej trasie,
- `reliability` - jako odsetek opóźnień na danej trasie,
- `nb` - numerowane od 1, 2, 3 według kolumny `reliability`. W przypadku takich samych wartości powino zwrócić 1, 2, 2, 3... 
Pamiętaj o tym, że w wyniku powinny pojawić się takie trasy, na których odbyło się ponad 10000 lotów.

Wskazówka:
- SQL - analiza danych > Dzień 2 Relacje oraz JOIN > JOIN
- SQL - analiza danych > Dzień 3 - Analiza danych > Grupowanie
- SQL - analiza danych > Dzień 1 Podstawy SQL > Aliasowanie
- SQL - analiza danych > Dzień 1 Podstawy SQL > Podzapytania
*/
CREATE OR REPLACE VIEW reporting.top_reliability_roads AS
SELECT
    f.origin_airport_id,
    al1.name AS origin_airport_name,
    f.dest_airport_id,
    al2.name AS dest_airport_name,
    f.year,
    COUNT(f.id) AS cnt,
    ROUND(COUNT(CASE WHEN f.dep_delay > 0 THEN 1 ELSE NULL END) / CAST(COUNT(f.id) AS NUMERIC), 2) AS reliability,
    DENSE_RANK() OVER (ORDER BY ROUND(COUNT(CASE WHEN f.dep_delay > 0 THEN 1 ELSE NULL END) / CAST(COUNT(f.id) AS NUMERIC), 2) DESC) AS nb
FROM
    public.flight AS f
JOIN
    public.airport_list AS al1 ON f.origin_airport_id = al1.origin_airport_id
JOIN
    public.airport_list AS al2 ON f.dest_airport_id = al2.origin_airport_id
WHERE
    f.cancelled = 0
GROUP BY
    f.origin_airport_id,
    al1.name,
    f.dest_airport_id,
    al2.name,
    f.year
HAVING
    COUNT(f.id) > 10000
;
/*
Tutaj napisz definicję widoku reporting.year_to_year_comparision, która będzie zawierał następujące kolumny:
- `year`
- `month`,
- `flights_amount`
- `reliability`
*/
CREATE OR REPLACE VIEW reporting.year_to_year_comparision AS
SELECT
    year,
    month,
    COUNT(id) AS flights_amount,
    round(count(case when dep_delay > 0 then 1 else null end)/ cast(count(id) as numeric), 2) as reliability
FROM
    public.flight
WHERE cancelled = 0
GROUP BY
    year,
    month
;
/*
Tutaj napisz definicję widoku reporting.day_to_day_comparision, który będzie zawierał następujące kolumny:
- `year`
- `day_of_week`
- `flights_amount`
*/ 
CREATE OR REPLACE VIEW reporting.day_to_day_comparision AS
SELECT
    year,
    day_of_week,
    COUNT(id) AS flights_amount
FROM
    public.flight
WHERE cancelled = 0
GROUP BY
    year,
    day_of_week
;
/*
Tutaj napisz definicję widoku reporting.day_by_day_reliability, ktory będzie zawierał następujące kolumny:
- `date` jako złożenie kolumn `year`, `month`, `day`, powinna być typu `date`
- `reliability` jako odsetek opóźnień danego dnia

Wskazówki:
- formaty dat w postgresql: [klik](https://www.postgresql.org/docs/13/functions-formatting.html),
- jeśli chcesz dodać zera na początek liczby np. `1` > `01`, posłuż się metodą `LPAD`: [przykład](https://stackoverflow.com/questions/26379446/padding-zeros-to-the-left-in-postgresql),
- do konwertowania ciągu znaków na datę najwygodniej w Postgres użyć `to_date`: [przykład](https://www.postgresqltutorial.com/postgresql-date-functions/postgresql-to_date/)
- do złączenia kilku kolumn / wartości typu string, używa się operatora `||`, przykładowo: SELECT 'a' || 'b' as example

Uwaga: Nie dodawaj tutaj na końcu srednika - przy używaniu split, pojawi się pusta kwerenda, co będzie skutkowało późniejszym błędem przy próbie wykonania skryptu z poziomu notatnika.
*/

CREATE OR REPLACE VIEW reporting.day_by_day_reliability AS
SELECT
    TO_DATE(CONCAT(year, LPAD(month::text, 2, '0'), LPAD(day_of_week::text, 2, '0')), 'YYYYMMDD') AS date,
    ROUND(COUNT(CASE WHEN dep_delay > 0 THEN 1 ELSE NULL END) / CAST(COUNT(id) AS NUMERIC), 2) AS reliability
FROM
    public.flight
WHERE
    cancelled = 0
GROUP BY
    year,
    month,
    day_of_week