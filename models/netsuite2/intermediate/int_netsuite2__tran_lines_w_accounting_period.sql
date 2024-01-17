{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with transactions as (
    select * 
    from {{ var('netsuite2_transactions') }}
), 

transaction_lines as (
    select * 
    from {{ ref('int_netsuite2__transaction_lines') }}
),

transaction_lines_w_accounting_period as ( -- transaction line totals, by accounts, accounting period and subsidiary
  select
    transaction_lines.transaction_id,
    transaction_lines.transaction_line_id,
    transaction_lines.subsidiary_id,
    transaction_lines.account_id,

    {% if var('netsuite2__multibook_accounting_enabled', false) %}
    transaction_lines.accounting_book_id,
    transaction_lines.accounting_book_name,
    transaction_lines.source_relation,
    {% endif %}
    
    transactions.accounting_period_id as transaction_accounting_period_id,
    transactions.source_relation,
    coalesce(transaction_lines.amount, 0) as unconverted_amount
  from transaction_lines

  join transactions 
    on transactions.transaction_id = transaction_lines.transaction_id
    and transactions.source_relation = transaction_lines.source_relation

  where lower(transactions.transaction_type) != 'revenue arrangement'
    and transaction_lines.is_posting
)

select * 
from transaction_lines_w_accounting_period