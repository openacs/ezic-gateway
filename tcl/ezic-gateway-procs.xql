<?xml version="1.0"?>

<queryset>

  <fullquery name="ezic_gateway.chargecard.select_auth_only">      
    <querytext>
      select transaction_id, auth_code
      from ezic_gateway_result_log 
      where txn_attempted_type='AUTH_ONLY' 
      and response_code='1' 
      and transaction_id=:transaction_id
    </querytext>
  </fullquery>

  <fullquery name="ezic_gateway.log_results.do-insert">      
    <querytext>
      insert into ezic_gateway_result_log 
        (transaction_id, txn_attempted_type, txn_attempted_time, response, response_code, 
          response_reason_code, response_reason_text, auth_code, avs_code, cvv2_code, ticket_code, amount) 
        values 
        (:transaction_id, :txn_attempted_type, :txn_attempted_time, :response, :response_code, 
         :response_reason_code, :response_reason_text, :auth_code, :avs_code, :cvv2_code, :ticket_code, :amount)
    </querytext>
  </fullquery>

  <fullquery name="ezic_gateway.info.get_package_version">
    <querytext>
      select version_name
      from apm_package_versions 
      where enabled_p = 't' 
      and package_key = 'ezic-gateway'
    </querytext>
  </fullquery>

  <fullquery name="ezic_gateway.info.get_package_name">
    <querytext>
      select instance_name 
      from apm_packages p, apm_package_versions v 
      where p.package_key = v.package_key 
      and v.enabled_p = 't' 
      and p.package_key = 'ezic-gateway'
    </querytext>
  </fullquery>

</queryset>
