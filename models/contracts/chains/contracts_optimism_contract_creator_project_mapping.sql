 {{
  config(      
        schema = 'contracts_optimism',
        alias = 'creator_project_mapping',
        materialized ='incremental',
        file_format ='delta',
        incremental_strategy='merge',
        unique_key='contract_address',
        partition_by = ['created_month']
  )
}}

{{contract_creator_project_mapping_by_chain(
    chain='optimism'
)}}