 {{
  config(
        schema = 'contracts_base',
        alias = 'contract_creator_project_iterated_creators',
        materialized ='table',
        unique_key='contract_address',
        partition_by = ['created_month']
  )
}}

{{contract_creator_project_iterated_creators(
    chain='base'
)}}