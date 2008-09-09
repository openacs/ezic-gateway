# presents log results for one transaction

# Authenticate the user
set user_id [auth::require_login]

# Check for admin privileges
set package_id [ad_conn package_id]
set admin_p [ad_permission_p $package_id admin]

# get transaction log comments. 
db_1row get_transaction_comments "select response_reason_text, avs_code
      from ezic_gateway_result_log 
      where transaction_id = :transaction_id and amount = :amount and (substr(txn_attempted_type,1,9) = 'AUTH_ONLY' or substr(txn_attempted_type,1,12) = 'AUTH_CAPTURE') and response_reason_text is not null and avs_code is not null order by txn_attempted_time desc limit 1"

if { [info exists response_reason_text] && [info exists avs_code] } {
    # decode left most avs_code. Second character is card CVV2/CVC2/CID code response
    set avs_text [ezic_gateway.expand_avs [string range $avs_code 0 0]]
    set code_text "CID: [string range $avs_code 1 1]"
} else {
    set response_reason_text ""
    set avs_text ""
    set code_text ""
}



