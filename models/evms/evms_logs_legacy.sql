{{ config(
        alias = alias('logs', legacy_model=True),
        unique_key=['blockchain', 'tx_hash'],
        post_hook='{{ expose_spells(\'["ethereum", "polygon", "bnb", "avalanche_c", "gnosis", "fantom", "optimism", "arbitrum", "celo"]\',
                                    "sector",
                                    "evms",
                                    \'["hildobby"]\') }}'
        )
}}

{% set logs_models = [
     ('ethereum', source('ethereum', 'logs'))
     , ('polygon', source('polygon', 'logs'))
     , ('bnb', source('bnb', 'logs'))
     , ('avalanche_c', source('avalanche_c', 'logs'))
     , ('gnosis', source('gnosis', 'logs'))
     , ('fantom', source('fantom', 'logs'))
     , ('optimism', source('optimism', 'logs'))
     , ('arbitrum', source('arbitrum', 'logs'))
     , ('celo', source('celo', 'logs'))
] %}

SELECT *
FROM (
        {% for logs_model in logs_models %}
        SELECT
        '{{ logs_model[0] }}' AS blockchain
        , *
        FROM {{ logs_model[1] }}
        {% if not loop.last %}
        UNION ALL
        {% endif %}
        {% endfor %}
        );