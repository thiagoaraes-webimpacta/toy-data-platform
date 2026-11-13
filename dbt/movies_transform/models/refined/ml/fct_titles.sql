-- Fato de títulos: grão de exatamente um título (title_key).
--
-- Medidas: nota da crítica (`rating`), total de votos (`votes`), duração em
-- minutos para filmes (`duration_minutes`; TV Show não tem duração, tem temporadas)
-- e anos entre o lançamento e a entrada na Netflix (`years_to_netflix`).
--
-- Regra de deduplicação: vem de `int_titles_attributes`, que mantém um único registro
-- representativo por título (menor `show_id` no Netflix) — a mesma regra das tabelas de
-- ponte de gênero e país, para que o grão seja "um título" e a contagem não infle ao
-- fatiar por qualquer dimensão. Na origem da crítica o desempate é a menor `release_date`.
--
-- Pergunta de negócio que motivou `added_year` / `years_to_netflix` / `catalog_age_band`:
-- "Depois de 2016 a Netflix passou a encher o catálogo com títulos antigos?
--  E esses títulos de catálogo têm nota da crítica melhor que os lançamentos?"

with critic as (

    select
        lower(trim(title)) as title_key,
        rating,
        no_of_persons_voted,
        row_number() over (
            partition by lower(trim(title)) order by release_date
        ) as rn
    from {{ ref('meta_critic') }}

),

titles as (

    select
        n.*,
        year(n.date_added) as added_year,
        -- Em TV Show o `release_year` da origem é o ano da temporada mais recente, então
        -- ele pode ser MAIOR que o ano de entrada (o teste
        -- `assert_netflix_added_after_release` mostra esses casos). Nesses casos a série
        -- já estreou na Netflix: a defasagem é zero, não negativa.
        greatest(year(n.date_added) - n.release_year, 0) as years_to_netflix
    from {{ ref('int_titles_attributes') }} n

)

select
    t.title_key,
    t.title,
    t.release_year as year_key,
    t.type as type_key,
    t.added_year,
    t.years_to_netflix,
    -- Faixas com prefixo numérico para ordenarem certo em qualquer gráfico.
    case
        when t.years_to_netflix is null then null
        when t.years_to_netflix <= 1 then '1 - Lançamento (0-1 ano)'
        when t.years_to_netflix <= 5 then '2 - Recente (2-5 anos)'
        when t.years_to_netflix <= 15 then '3 - Catálogo (6-15 anos)'
        else '4 - Clássico (16+ anos)'
    end as catalog_age_band,
    c.rating,
    c.no_of_persons_voted as votes,
    try_cast(
        nullif(regexp_extract(t.duration, '(\d+)\s*min', 1), '') as integer
    ) as duration_minutes
from titles t
inner join critic c on t.title_key = c.title_key
where c.rn = 1
