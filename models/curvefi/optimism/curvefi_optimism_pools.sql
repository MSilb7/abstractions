{{ config(
    alias = 'pools',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    partition_by=['pool'],
    unique_key = ['version', 'tokenid', 'token', 'pool'],
    post_hook='{{ expose_spells(\'["optimism"]\',
                                "project",
                                "curvefi",
                                \'["msilb7"]\') }}'
    )
}}

-- Original Ref - Dune v1 Abstraction: https://github.com/duneanalytics/spellbook/blob/main/deprecated-dune-v1-abstractions/optimism2/dex/insert_curve.sql
-- Start Time
-- SELECT MIN(call_block_time) FROM curvefi_optimism.StableSwap_call_coins
{% set project_start_date = '2022-01-17' %}


WITH base_pools AS (
    --Need all base pools because the meta pools reference them
    SELECT
        `arg0` AS tokenid
        , output_0 AS token
        , contract_address AS pool
    FROM {{ source('curvefi_optimism', 'StableSwap_call_coins') }}
    WHERE call_success
    GROUP BY --1,2,3 --unique
        `arg0`, output_0, contract_address --unique
)
, meta_pools AS (
    -- Meta Pools are "Base Pools" + 1 extra token (i.e. sUSD + 3pool = sUSD Metapool)
    SELECT
        tokenid
        , token
        , et.`contract_address` AS pool
    FROM
    (
        SELECT
            mp.evt_tx_hash
            , (bp.tokenid + 1) AS tokenid
            , bp.token
            , mp.evt_block_number
        FROM {{ source('curvefi_optimism', 'PoolFactory_evt_MetaPoolDeployed') }} mp
        INNER JOIN base_pools bp
            ON mp.base_pool = bp.pool
        {% if is_incremental() %}
        WHERE mp.evt_block_time >= date_trunc('day', now() - interval '1 week')
        {% endif %}
        GROUP BY --1,2,3,4 --unique
            mp.evt_tx_hash, (bp.tokenid + 1), bp.token, mp.evt_block_number --unique
    
        UNION ALL
        
        SELECT
            mp.evt_tx_hash
            , 0 AS tokenid
            , mp.`coin` AS token
            , mp.evt_block_number
        FROM {{ source('curvefi_optimism', 'PoolFactory_evt_MetaPoolDeployed') }} mp
        INNER JOIN base_pools bp
            ON mp.base_pool = bp.pool
        {% if is_incremental() %}
        WHERE mp.evt_block_time >= date_trunc('day', now() - interval '1 week')
        {% endif %}
        GROUP BY --1 ,3,4 --unique (Will throw an error if we group by 2 - since it's = 0)
            mp.evt_tx_hash, mp.`coin`, mp.evt_block_number --unique
    ) mps
    -- the exchange address appears as an erc20 minted to itself (not in the deploymeny event)
    INNER JOIN {{ source('erc20_optimism','evt_transfer') }} et
        ON et.evt_tx_hash = mps.evt_tx_hash
        AND et.`from` = '0x0000000000000000000000000000000000000000'
        AND et.`to` = et.`contract_address`
        AND et.evt_block_number = mps.evt_block_number
        {% if not is_incremental() %}
        AND et.evt_block_time >= '{{project_start_date}}'
        {% endif %}
        {% if is_incremental() %}
        AND et.evt_block_time >= date_trunc('day', now() - interval '1 week')
        {% endif %}
    GROUP BY --1,2,3
        tokenid, token, et.`contract_address` --unique

)
, basic_pools AS (
    SELECT
        pos AS tokenid
        , col AS token
        , pool
    FROM
    (
        SELECT 
            posexplode(_coins)
            , output_0 AS pool
        FROM {{ source('curvefi_optimism', 'PoolFactory_call_deploy_plain_pool') }}
        WHERE call_success
        {% if is_incremental() %}
        AND call_block_time >= date_trunc('day', now() - interval '1 week')
        {% endif %}
    ) a
    GROUP BY --1,2,3
        pos, col, pool --unique
)
SELECT
    version
    , cast( int(tokenid) as string) AS tokenid
    , token
    , pool 
FROM
(
    SELECT
        'Base Pool' AS version
        , tokenid
        , token
        , pool 
    FROM base_pools
    UNION ALL
    SELECT
        'Meta Pool' AS version
        , tokenid
        , token
        , pool
    FROM meta_pools
    UNION ALL
    SELECT
        'Basic Pool' AS version
        , tokenid
        , token
        , pool
    FROM basic_pools
) a
GROUP BY --1,2,3,4 --unique
    version, cast( int(tokenid) as string), token, pool --unique
;
