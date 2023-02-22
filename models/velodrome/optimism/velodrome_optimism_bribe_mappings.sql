{{
    config(
        schema = 'velodrome_optimism',
        alias='bribe_mappings',
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        unique_key = ['pool_contract', 'incentives_contract', 'allowed_rewards'],
        post_hook='{{ expose_spells(\'["optimism"]\',
                                    "project",
                                    "velodrome",
                                    \'["msilb7"]\') }}'
    ) 
}}


SELECT
  'optimism' as blockchain
, 'velodrome' AS project
, '1' as version
, pool_contract, incentives_contract, incentives_type, allowed_rewards
, evt_block_time, evt_block_number, contract_address, evt_tx_hash, evt_index

FROM (
        SELECT
        cg._pool AS pool_contract
        , ceb.output_0 AS incentives_contract
        , 'external bribe' as incentives_type
        , ceb..allowedRewards AS allowed_rewards
        , ceb..call_block_time AS evt_block_time
        , ceb..call_block_number AS evt_block_number
        , ceb..contract_address
        , ceb..call_tx_hash AS evt_tx_hash
        , 1 AS evt_index

        FROM {{ source('velodrome_optimism','BribeFactory_call_createExternalBribe') }} ceb.
        INNER JOIN {{ source('velodrome_optimism', 'GaugeFactory_call_createGauge') }} cg
                ON cg._external_bribe = ceb..existing_bribe

        WHERE ceb..call_success = true

        UNION ALL

        SELECT
        cg._pool AS pool_contract
        , cib.output_0 AS incentives_contract
        , 'internal bribe' as incentives_type
        , cib.allowedRewards AS allowed_rewards
        , cib.call_block_time AS evt_block_time
        , cib.call_block_number AS evt_block_number
        , cib.contract_address
        , cib.call_tx_hash AS evt_tx_hash
        , 1 AS evt_index

        FROM {{ source('velodrome_optimism','BribeFactory_call_createInternalBribe') }} cib
        INNER JOIN {{ source('velodrome_optimism', 'GaugeFactory_call_createGauge') }} cg
                ON cg._internal_bribe = cib.output_0

        WHERE cib.call_success = true
) a