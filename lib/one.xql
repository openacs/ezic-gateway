<?xml version="1.0"?>
<queryset>
  <fullquery name="get_transaction_commnets">      
    <querytext>
      select response_reason_text, avs_code
      from ezic_gateway_result_log 
      where transaction_id = :transaction_id and amount = :amount and (substr(txn_attempted_type,1,9) = 'AUTH_ONLY' or substr(txn_attempted_type,1,12) = 'AUTH_CAPTURE')
    </querytext>
  </fullquery>
</queryset>
