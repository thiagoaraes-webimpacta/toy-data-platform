{{ config(materialized='ephemeral') }}

-- Um título por linha, com os atributos multi-valor (gênero, país) ainda como lista.
--
-- Esta é a fonte única do grão "um título" para o fato e para as tabelas de ponte:
-- a mesma regra de deduplicação (menor `show_id` no Netflix) precisa valer nos dois
-- lugares, senão a contagem de títulos infla ao fatiar por gênero ou por país.
--
-- `date_added` (data em que o título entrou no catálogo da Netflix) passa adiante
-- para o fato calcular a "idade do título ao entrar no catálogo".

with deduped as (

    select
        lower(trim(title)) as title_key,
        title,
        type,
        release_year,
        date_added,
        duration,
        listed_in,
        country,
        row_number() over (
            partition by lower(trim(title)) order by show_id
        ) as rn
    from {{ ref('netflix_titles') }}

)

select
    title_key,
    title,
    type,
    release_year,
    date_added,
    duration,
    listed_in,
    country
from deduped
where rn = 1
