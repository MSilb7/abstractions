{{ config(alias = 'l2_batch_submitters',
        tags=['static'],
        post_hook='{{ expose_spells(\'["bnb"]\',
                                    "sector",
                                    "addresses",
                                    \'["msilb7"]\') }}') }}

SELECT address AS address, protocol_name, submitter_type, role_type, version, description
FROM (VALUES
         (0xfF00000000000000000000000000000000005611, 'opBNB', 'L1BatchInbox','to_address','Bedrock','opBNB: L1BatchInbox')
        ,(0x1Fd6A75CC72f39147756A663f3eF1fc95eF89495, 'opBNB', 'L1BatchInbox','from_address','Bedrock','opBNB: L1BatchInbox')

        ,(0xD92aEF4473093C67A7696e475858152D3b2acB7c, 'opBNB', 'L2OutputOracle','to_address','Bedrock','opBNB: L2OutputOracle')
        ,(0x153CAB79f4767E2ff862C94aa49573294B13D169, 'opBNB', 'L2OutputOracleProxy','to_address','Bedrock','opBNB: L2OutputOracleProxy')
        ,(0x4ae49f1f57358c13a5732cb12e656cf8c8d986df, 'opBNB', 'L2OutputOracle','from_address','Bedrock','opBNB: L2OutputOracle')


        ) AS x (address, protocol_name, submitter_type, role_type, version, description)
