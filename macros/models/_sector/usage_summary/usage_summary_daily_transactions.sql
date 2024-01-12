{% macro usage_summary_daily_transactions( chain, days_forward=365 ) %}

WITH check_date AS (
  SELECT
  {% if is_incremental() %}
    MAX(block_date) AS base_time FROM {{this}}
  {% else %}
    MIN(time) AS base_time FROM {{ source( chain , 'blocks') }}
  {% endif %}
)

SELECT
    '{{chain}}' as blockchain
  , block_date
  , DATE_TRUNC('month', block_date ) AS block_month
  , COALESCE(t.to, 0x) AS address
  , COUNT(DISTINCT block_number) AS num_tx_to_blocks
  , COUNT(*) AS num_tx_tos
  , COUNT(DISTINCT "from") AS num_tx_to_senders
  , SUM(gas_used) AS sum_tx_to_gas_used
  , SUM(bytearray_length(t.data)) AS sum_tx_to_calldata_bytes
  , SUM(
    {{ evm_get_calldata_gas_from_data('t.data') }}
  ) AS sum_tx_to_calldata_gas
  FROM {{ source(chain,'transactions') }} t
  cross join check_date cd

  WHERE 1=1
    AND {{ incremental_days_forward_predicate('t.block_date', 'cd.base_time', days_forward, 'day') }}
    AND t.success
  GROUP BY 1,2,3,4

{% endmacro %}