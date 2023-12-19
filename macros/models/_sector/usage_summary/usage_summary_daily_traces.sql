{% macro usage_summary_daily_traces( chain, days_forward=365 ) %}

WITH check_date AS (
  SELECT
  {% if is_incremental() %}
    MAX(block_date) AS base_time FROM {{this}}
  {% else %}
    MIN(block_time) AS base_time FROM {{ source( chain , 'transactions') }}
  {% endif %}
)

  SELECT
    '{{chain}}' as blockchain
  , block_date
  , DATE_TRUNC('month', block_date ) AS block_month
  , a.to AS address
  ---
  , COUNT(DISTINCT block_number) AS num_trace_to_blocks
  , COUNT(DISTINCT tx_hash) AS num_trace_to_txs
  , COUNT(*) AS num_trace_to_calls
  ---
  , COUNT(DISTINCT tx_from) AS num_trace_to_tx_senders
  , COUNT(DISTINCT "from") AS num_trace_to_call_senders
  ---
  , SUM(a.gas_used) AS sum_trace_to_gas_used
  /* maybe add the trace gas with subtraces removed here? */
  , SUM(CASE WHEN trace_to_number = 1 THEN tx_gas_used ELSE 0 END) AS sum_trace_to_tx_gas_used

  FROM (
      SELECT r.block_date, r.block_number
        , COALESCE(r.to, 0x) AS to, r.tx_hash, t."from" AS tx_from, r."from"
        , r.gas_used, t.gas_used as tx_gas_used
        , ROW_NUMBER() OVER (PARTITION BY r.tx_hash) AS trace_to_number --reindex trace to ensure single count

        FROM {{ source(chain,'traces') }} r
        cross join check_date cd
        INNER JOIN  {{ source(chain,'transactions') }} t 
          ON t.hash = r.tx_hash
          AND t.block_number = r.block_number
          AND t.block_date = r.block_date
          AND {{ incremental_base_forward_predicate('t.block_date', 'cd.base_time', days_forward ) }}
        
        WHERE 1=1
          AND r.type = 'call'
          AND r.success AND r.tx_success
          AND {{ incremental_base_forward_predicate('t.block_date', 'cd.base_time', days_forward ) }}
          AND {{ incremental_base_forward_predicate('r.block_date', 'cd.base_time', days_forward ) }}
      GROUP BY 1,2,3,4,5,6,7,8
    ) a
  GROUP BY 1,2,3,4

{% endmacro %}