<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <partialquery name="transaction_last_24hours">      
    <querytext>
      txn_attempted_time + '1 days'::interval > now()
    </querytext>
  </partialquery>

  <partialquery name="transaction_last_week">      
    <querytext>
      txn_attempted_time + '7 days'::interval > now()
    </querytext>
  </partialquery>

  <partialquery name="transaction_last_month">      
    <querytext>
      txn_attempted_time + '1 months'::interval > now()
    </querytext>
  </partialquery>

<fullquery name="result_select">      
    <querytext>
      select transaction_id, to_char(txn_attempted_time, 'MM-DD-YYYY HH24:MI:SS') as txn_time, txn_attempted_type, response, response_code, response_reason_code, response_reason_text, auth_code, avs_code, amount 
      from ezic_gateway_result_log 
      where '1'='1' [ad_dimensional_sql $dimensional] [ad_order_by_from_sort_spec $orderby $table_def]
    </querytext>
  </fullquery>

</queryset>