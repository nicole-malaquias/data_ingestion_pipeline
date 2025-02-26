--  Querys utilizadas para responder : Quais regiões apresentam o melhor e o pior desempenho educacional? 

WITH 
  cte_regioes AS (
    SELECT
      sigla_uf
      , CASE
        WHEN sigla_uf IN ('RO', 'AP', 'TO', 'AC', 'RR') THEN 'Norte'
        WHEN sigla_uf IN ('RN', 'PE', 'BA', 'CE') THEN 'Nordeste'
        WHEN sigla_uf IN ('MG', 'RJ', 'ES') THEN 'Sudeste'
        WHEN sigla_uf IN ('MT', 'GO', 'DF', 'MS') THEN 'Centro-Oeste'
        WHEN sigla_uf = 'SC' THEN 'Sul'
        ELSE 'Outros'
      END AS regiao
      , ano
      , desempenho_aluno
    FROM `letrus-data.baseletrus.aluno_ef_9ano_transformado`
    WHERE ano BETWEEN 1995 AND 2021
      AND desempenho_aluno IS NOT NULL
      AND desempenho_aluno NOT IN ('nan', 'null')
      AND sigla_uf IS NOT NULL
      AND sigla_uf IN ('SC','RO','AP','RN','PE','MG','TO','BA','MT','AC','GO','RJ','ES','DF','RR','CE','MS')
  )

  , performance_counts AS (
    SELECT
      regiao
      , ano
      , COUNT(*) AS total_alunos
      , SUM(CASE WHEN desempenho_aluno = 'Avançado' THEN 1 ELSE 0 END) AS cnt_avancado
      , SUM(CASE WHEN desempenho_aluno = 'Proficiente' THEN 1 ELSE 0 END) AS cnt_proficiente
      , SUM(CASE WHEN desempenho_aluno = 'Básico' THEN 1 ELSE 0 END) AS cnt_basico
      ,SUM(CASE WHEN desempenho_aluno = 'Insuficiente' THEN 1 ELSE 0 END) AS cnt_insuficiente
    FROM cte_regioes
    GROUP BY regiao, ano
  )

  , region_performance AS (
    SELECT
      regiao
      , ROUND(AVG((cnt_avancado / total_alunos) * 100), 1) AS perc_avancado
      , ROUND(AVG((cnt_proficiente / total_alunos) * 100), 1) AS perc_proficiente
      , ROUND(AVG((cnt_basico / total_alunos) * 100), 1) AS perc_basico
      -- Calcula o percentual de "Insuficiente" para fechar exatamente 100%
      ,ROUND(100 - (
        ROUND(AVG((cnt_avancado / total_alunos) * 100), 1) +
        ROUND(AVG((cnt_proficiente / total_alunos) * 100), 1) +
        ROUND(AVG((cnt_basico / total_alunos) * 100), 1)
      ), 1) AS perc_insuficiente
    FROM performance_counts
    GROUP BY regiao
  )

SELECT
  regiao
  , perc_avancado AS percentual_avancado
  , perc_proficiente AS percentual_proficiente
  , perc_basico AS percentual_basico
  , perc_insuficiente AS percentual_insuficiente
FROM region_performance
ORDER BY percentual_avancado DESC, percentual_proficiente DESC, percentual_basico ASC, percentual_insuficiente ASC;

---------------------------------------------------------------
WITH 
  cte_regioes AS (
    SELECT
      sigla_uf
      , CASE
        WHEN sigla_uf IN ('RO', 'AP', 'TO', 'AC', 'RR') THEN 'Norte'
        WHEN sigla_uf IN ('RN', 'PE', 'BA', 'CE') THEN 'Nordeste'
        WHEN sigla_uf IN ('MG', 'RJ', 'ES') THEN 'Sudeste'
        WHEN sigla_uf IN ('MT', 'GO', 'DF', 'MS') THEN 'Centro-Oeste'
        WHEN sigla_uf = 'SC' THEN 'Sul'
        ELSE 'Outros'
      END AS regiao
      , ano
      , desempenho_aluno
    FROM `letrus-data.baseletrus.aluno_ef_9ano_transformado`
    WHERE ano BETWEEN 1995 AND 2021
      AND desempenho_aluno IS NOT NULL
      AND desempenho_aluno NOT IN ('nan', 'null')
      AND sigla_uf IS NOT NULL
      AND sigla_uf IN ('SC','RO','AP','RN','PE','MG','TO','BA','MT','AC','GO','RJ','ES','DF','RR','CE','MS')
  )

  , state_performance AS (
    SELECT
      regiao
      , sigla_uf AS estado
      , COUNT(*) AS total_alunos_estado
      , SUM(CASE WHEN desempenho_aluno = 'Avançado' THEN 1 ELSE 0 END) AS cnt_avancado
      , SUM(CASE WHEN desempenho_aluno = 'Insuficiente' THEN 1 ELSE 0 END) AS cnt_insuficiente
    FROM cte_regioes
    GROUP BY regiao, sigla_uf
  )

  , state_percentage_performance AS (
    SELECT
      regiao
      , estado
      , ROUND((cnt_avancado / total_alunos_estado) * 100, 1) AS perc_avancado_estado
      , ROUND((cnt_insuficiente / total_alunos_estado) * 100, 1) AS perc_insuficiente_estado
    FROM state_performance
  )

SELECT
  regiao
  , estado
  , perc_avancado_estado AS percentual_avancado
  , perc_insuficiente_estado AS percentual_insuficiente
FROM state_percentage_performance
ORDER BY regiao, percentual_avancado DESC, percentual_insuficiente ASC;


-- Querys utilizadas para responder: Como o desempenho dos alunos varia entre escolas públicas e privadas? 


WITH 
  cte_regioes AS (
    SELECT
      sigla_uf
      , CASE
        WHEN sigla_uf IN ('RO', 'AP', 'TO', 'AC', 'RR') THEN 'Norte'
        WHEN sigla_uf IN ('RN', 'PE', 'BA', 'CE') THEN 'Nordeste'
        WHEN sigla_uf IN ('MG', 'RJ', 'ES') THEN 'Sudeste'
        WHEN sigla_uf IN ('MT', 'GO', 'DF', 'MS') THEN 'Centro-Oeste'
        WHEN sigla_uf = 'SC' THEN 'Sul'
        ELSE 'Outros'
      END AS regiao
      , ano
      , CASE WHEN escola_publica = 1 THEN 'Pública' ELSE 'Privada' END AS tipo_escola
      , desempenho_aluno
    FROM `letrus-data.baseletrus.aluno_ef_9ano_transformado`
    WHERE ano BETWEEN 1995 AND 2021
      AND desempenho_aluno IN ('Avançado', 'Proficiente', 'Básico', 'Insuficiente')
      AND escola_publica IN (0, 1)
      AND sigla_uf IS NOT NULL
      AND sigla_uf IN ('SC','RO','AP','RN','PE','MG','TO','BA','MT','AC','GO','RJ','ES','DF','RR','CE','MS')
  )

  , performance_by_school_type AS (
    SELECT
      regiao
      , tipo_escola
      , COUNT(*) AS total_alunos
      , SUM(CASE WHEN desempenho_aluno = 'Avançado' THEN 1 ELSE 0 END) AS cnt_avancado
      , SUM(CASE WHEN desempenho_aluno = 'Proficiente' THEN 1 ELSE 0 END) AS cnt_proficiente
      , SUM(CASE WHEN desempenho_aluno = 'Básico' THEN 1 ELSE 0 END) AS cnt_basico
      , SUM(CASE WHEN desempenho_aluno = 'Insuficiente' THEN 1 ELSE 0 END) AS cnt_insuficiente
    FROM cte_regioes
    GROUP BY regiao, tipo_escola
  )

  , percentage_performance AS (
    SELECT
      regiao
      , tipo_escola
      , ROUND((cnt_avancado / total_alunos) * 100, 1) AS percentual_avancado
      , ROUND((cnt_proficiente / total_alunos) * 100, 1) AS percentual_proficiente
      , ROUND((cnt_basico / total_alunos) * 100, 1) AS percentual_basico
      , ROUND((cnt_insuficiente / total_alunos) * 100, 1) AS percentual_insuficiente
    FROM performance_by_school_type
  )

SELECT
  regiao
  , tipo_escola
  , percentual_avancado
  , percentual_proficiente
  , percentual_basico
  , percentual_insuficiente
FROM percentage_performance
ORDER BY regiao, tipo_escola;


---------------------------------------------------------------


WITH 
  cte_escolas AS (
    SELECT
      CASE WHEN escola_publica = 1 THEN 'Pública' ELSE 'Privada' END AS tipo_escola
      , desempenho_aluno
    FROM `letrus-data.baseletrus.aluno_ef_9ano_transformado`
    WHERE ano BETWEEN 1995 AND 2021
      AND desempenho_aluno IN ('Avançado', 'Proficiente', 'Básico', 'Insuficiente')
      AND escola_publica IN (0, 1)
  )

  , performance_by_school_type AS (
    SELECT
      tipo_escola
      , COUNT(*) AS total_alunos
      , SUM(CASE WHEN desempenho_aluno = 'Avançado' THEN 1 ELSE 0 END) AS cnt_avancado
      , SUM(CASE WHEN desempenho_aluno = 'Proficiente' THEN 1 ELSE 0 END) AS cnt_proficiente
      , SUM(CASE WHEN desempenho_aluno = 'Básico' THEN 1 ELSE 0 END) AS cnt_basico
      , SUM(CASE WHEN desempenho_aluno = 'Insuficiente' THEN 1 ELSE 0 END) AS cnt_insuficiente
    FROM cte_escolas
    GROUP BY tipo_escola
  )

  , percentage_performance AS (
    SELECT
      tipo_escola
      , ROUND((cnt_avancado / total_alunos) * 100, 1) AS percentual_avancado
      , ROUND((cnt_proficiente / total_alunos) * 100, 1) AS percentual_proficiente
      , ROUND((cnt_basico / total_alunos) * 100, 1) AS percentual_basico
      , ROUND((cnt_insuficiente / total_alunos) * 100, 1) AS percentual_insuficiente
    FROM performance_by_school_type
  )

SELECT
  tipo_escola
  , percentual_avancado
  , percentual_proficiente
  , percentual_basico
  , percentual_insuficiente
FROM percentage_performance
ORDER BY tipo_escola;

