-- Regra da medida `years_to_netflix` no fato: nunca negativa e, quando o título tem
-- ano de entrada, sempre com uma faixa (`catalog_age_band`) atribuída.
-- Se alguém mudar o cálculo (ex.: tirar o `greatest`) ou as faixas do `case`, este
-- teste retorna as linhas inconsistentes e falha.

select
    title_key,
    year_key,
    added_year,
    years_to_netflix,
    catalog_age_band
from {{ ref('fct_titles') }}
where years_to_netflix < 0
   or (added_year is not null and catalog_age_band is null)
   or (added_year is not null and years_to_netflix is null)
