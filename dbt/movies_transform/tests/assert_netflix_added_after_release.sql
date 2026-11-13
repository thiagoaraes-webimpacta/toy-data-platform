-- Coerência temporal da origem: um título não deveria entrar na Netflix (`date_added`)
-- antes de ser lançado (`release_year`).
--
-- Este teste pegou um problema real: 14 títulos, quase todos TV Show (Fuller House,
-- BoJack Horseman, Sense8...), têm `release_year` maior que o ano de entrada. Na
-- origem, o `release_year` de série é o ano da temporada mais recente, não o da estreia.
--
-- Decisão: é uma característica conhecida da fonte, não lixo — então o teste avisa
-- (warn) enquanto os casos forem poucos e falha (error) se crescerem, o que indicaria
-- uma carga quebrada. O fato trata a defasagem negativa como zero (ver `fct_titles`).

{{ config(warn_if='>0', error_if='>20') }}

select
    show_id,
    type,
    title,
    release_year,
    date_added
from {{ ref('netflix_titles') }}
where date_added is not null
  and year(date_added) < release_year
