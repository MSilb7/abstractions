{{ config(
        tags = ['dunesql'],
        alias = alias('erc1155_transferssingle'),
        unique_key=['blockchain', 'tx_hash', 'evt_index'],
        post_hook='{{ expose_spells(\'["goerli"]\',
                                    "sector",
                                    "evms_mainnets_testnets",
                                    \'["hildobby", "msilb7"]\') }}'
        )
}}

{% set models = [
     ('mainnet', ref('evms_erc1155_transferssingle'))
     ,('testnet', ref('evms_testnets_erc1155_transferssingle'))
] %}

SELECT *
FROM (
        {% for model in models %}
        SELECT
        '{{ model[0] }}' AS chain_type
        , *
        FROM {{ model[1] }}
        {% if not loop.last %}
        UNION ALL
        {% endif %}
        {% endfor %}
        );