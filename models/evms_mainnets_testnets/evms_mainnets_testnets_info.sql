{{ config(
        tags = ['dunesql', 'static'],
        alias = alias('info', timestamp ),
        post_hook='{{ expose_spells(\'["goerli"]\',
                                    "sector",
                                    "emvs_mainnets_testnets",
                                    \'["hildobby", "msilb7]\') }}')
}}

{% set models = [
     ('mainnet', ref('emvs_info'))
     ,('testnet', ref('emvs_testnets_info'))
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