ad_library {

    Procedures to implement EZIC Direct Mode 3.0 credit card transactions.

    EZIC uses following codes. Others available via documentation.

    # status_codes - ezic respond field
    #    (authorize.net equivalent response_code)
    #
    # 1: (1) successful/approved
    # T: (1) sucessful Auth-Only
    # 0: (2) failure/declined
    # D: duplicate (making this an error)
    #  : (3) error (no ezic gateway equivalent)

    # CVV2_codes - ezic gateway response field values
    #
    # M:  CVV2 match
    # N:  CVV2 does not match 
    # P:  CVV2 not processed 
    # S:  Card has CVV2, customer says it doesn't
    # U:  CVV2 data from issuer
    # _:  No CVV2 data (_ means <null character>)

    # ticket_codes - ezic gateway response field values (unknown)
    # XXXXXXXXXXXXXXX : possible response when using test credit card number.

    # tran_types - ezic gateway input field values
    #    (authorize.net equivalent)
    #
    # A: (AUTH_ONLY) authorize a card for a specific amount
    # S: (AUTH_CAPTURE) authorize a card for amount, and get money
    # C: (CREDIT) credit back money to a card, unrelated to a specific sale
    # R: (VOID) refund, refund back money from a prior sale.
    # D: (PRIOR_AUTH_CAPTURE) capture a prior (A) authorization, making i a Sale
    #  : (CAPTURE_ONLY) no ezic gateway equivalent
 
    # EZIC gateway separates billing last name from billing first name
    # The authorize.net package uses a combined $card_name
    # ecommerce and payment-gateway packages need similarly adapted.
    # This package assumes $card_name is formatted like this:
    # set card_name "$first_names   $last_name" 
    # Note: the 3 space delimiter 

    # EZIC test mode is set via the virtual terminal only.
    # the test request flag here indicates add more communication detail to server log

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004
}

ad_proc -private ezic_gateway.authorize {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_code
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to EZIC to authorize a transaction for the amount 
    given on the card given.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004
} {
    # 1. Send transaction off to gateway

    set test_request [ezic_gateway.decode_test_request]



    set field_seperator [ad_parameter field_seperator \
                     -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator \
                -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url \
             -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] referer_url]]

    # Add the Referer to the headers passed on to EZIC

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with EZIC

    # Basic secure URL and account info.

    set full_url "[ad_parameter ezic_url -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_url]]?account_id=[ns_urlencode [ad_parameter ezic_login -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_login]]]"
    # site_tag is optional when there is only one
    if {[string length [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]] > 0 } {
        append full_url "&site_tag=[ns_urlencode [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]]"
    }

    # Set the transaction type to AUTHORIZE ONLY 
    # EZIC.com will generate and return the transaction_id, which
    # will be stored in
    # the response_transaction_id. Use the response_transaction_id to
    # complete the transaction with a POST_AUTH operation.
 
    append full_url "&pay_type=C&tran_type=A&amount=[ns_urlencode [format "%0.2f" $amount]]&tax_amount=[ns_urlencode [format "%0.2f" 0]]&ship_amount=[ns_urlencode [format "%0.2f" 0]]&description=[ns_urlencode "ECommerce transaction ID: $transaction_id"]"

    # Set the credit card information.
    # EZIC requires separate first and last name fields per bank field checking
    # $card_name is hacked field pair in ecommerce to hold first_names and last_name
    # delimiter is triple space (for parsing). Defaults to put all in last name if not parsed.
    set name_delim [string first "   " $card_name]
    if {$name_delim < 0 } {
        set name_delim 0
    }
    set first_names [string trim [string range $card_name 0 $name_delim]]
    set last_name [string range $card_name [expr $name_delim + 3 ] end]
    append full_url "&card_number=[ns_urlencode $card_number]&card_expire=[ns_urlencode ${card_exp_month}${card_exp_year}]&bill_name1=[ns_urlencode $first_names]&bill_name2=[ns_urlencode $last_name]"

    # Set the billing information. The information will be sent to
    # EZIC to run an AVS check.

    append full_url "&bill_street=[ns_urlencode $billing_street]&bill_city=[ns_urlencode $billing_city]&bill_zip=[ns_urlencode $billing_zip]&bill_state=[ns_urlencode $billing_state]&bill_country=[ns_urlencode $billing_country]"

    # Contact EZIC.com and receive the delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to EZIC.com.

    if {[string equal $test_request "True"]} {
        ns_log Notice "MARK -- EZIC TEST AUTH_ONLY outbound full_url = '$full_url'"
    }
 
    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
        if {[string equal $test_request "True"]} {
            ns_log Notice "EZIC: Response is: [value_if_exists $error_message]"
        }
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes retry]
        set return(reason) "Transaction $transaction_id AUTH_ONLY failed, could not contact EZIC: $error_message"
        set return(transaction_id) $transaction_id
        return [array get return]
    } else {

        # 2. Insert into log table

        # Decode the response from EZIC.com. Not all fields are
        # of interest. See the EZIC documentation:
        # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
        # and start of this file for a list of some response codes.

        # make list of fieldname=value pairs
        # first pair is blank, because EZIC uses cgi reply
        set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

        # Check that the response from EZIC is a legimate ADC
        # response. When EZIC.com has problems the response is
        # not a character delimited list but an HTML page. An ADC
        # response has 7 elements, plus first blank element is 8.
        # Future versions might return more elements.

        set response_list_len [llength $response_list]

        if { $response_list_len < 3 || $response_list_len > 15 } {
            ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" $response 3 "" \
            "EZIC gateway might be down, the response was not a list of 7 fields." "" "" "" "" $amount
            set return(response_code) [nsv_get payment_gateway_return_codes retry]
            set return(reason) "EZIC gateway might be down, the response was not a list of 7 fields."
            set return(transaction_id) $transaction_id
            return [array get return]
        } else {

            # Ezic says they might change the order that fields are presented in response
            # so adding lsearch to set elements from arbitrary response list order.
            # EZIC uses cgi response format, so set fields to values right of "=" (value may be empty)
            # apparently EZIC returns auth_date which we ignore for now
            set response_reason_code [string range [lindex $response_list [lsearch $response_list {status_code=*}]] 12 end]
            set response_reason_text [string range [lindex $response_list [lsearch $response_list {auth_msg=*}]] 9 end]
            set response_auth_code [string range [lindex $response_list [lsearch $response_list {auth_code=*}]] 10 end]
            set response_avs_code [string range [lindex $response_list [lsearch $response_list {avs_code=*}]] 9 end]
            set response_transaction_id [string range [lindex $response_list [lsearch $response_list {trans_id=*}]] 9 end]
            set response_cvv2_code [string range [lindex $response_list [lsearch $response_list {cvv2_code=*}]] 10 end]
            set response_ticket_code [string range [lindex $response_list [lsearch $response_list {ticket_code=*}]] 12 end]

            # translate reason_code from status_code to existing authorize.net mapping
            if { $response_reason_code == 1 || $response_reason_code == "T" } {
                set response_code 1
            } elseif { $response_reason_code == "0" } {
                # for status_code values 0
                set response_code 2
            } else {
                # must be an error somewhere
                set response_code 3
            }

            ezic_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" \
            $response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $response_cvv2_code $response_ticket_code $amount

            # 3. Return result
            return [ezic_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text $amount]
        }
    }
}

ad_proc -public ezic_gateway.chargecard {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_code
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    ChargeCard is a wrapper so we can present a consistent interface to
    the caller.  It will just pass on it's parameters to 
    ezic_gateway.postauth or ezic_gateway.authcapture, 
    whichever is appropriate for the implementation at hand. 

    PostAuth is used when there is a successful authorize transaction in 
    the ezic_gateway_result_log for transaction_id. AuthCapture will 
    be used if there is no prior authorize transaction in the log.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {

    # 1. Check for the existence of a prior auth_only for the transaction_id.

    if {[db_0or1row select_auth_only {}]} {

        # 2a. The transaction has been authorized, now mark the transaction for settlement.

        return [ezic_gateway.postauth $transaction_id $auth_code $card_number $card_exp_month $card_exp_year $card_name $amount]

    } else {

        # 2b. This is a new transaction which will be authorized and automatically marked for settlement.

        return [ezic_gateway.authcapture $transaction_id $amount $card_type $card_number $card_exp_month $card_exp_year $card_name $billing_street $billing_city $billing_state $billing_zip $billing_country]
    }
}

ad_proc -public ezic_gateway.return {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_code
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to EZIC gateway to refund the amount given to the card given. 
    The transaction id needs to reference a settled transaction performed 
    with the same card.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {

    # 1. Send transaction off to gateway

    set test_request [ezic_gateway.decode_test_request]

    set field_seperator [ad_parameter field_seperator \
                 -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator \
                -default [ad_parameter \
                          -package_id [apm_package_id_from_key ezic-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url \
             -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] referer_url]]

    # Add the Referer to the headers passed on to EZIC.com

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    if {[string length $card_number] < 2} {
        # card_number must have been deleted. Reject transaction
        set error_message "Card number not available. Credit transaction rejected."
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes failure]
        set return(reason) "Transaction $transaction_id CREDIT failed. No card number."
        set return(transaction_id) $transaction_id
        return [array get return]
    }

    # Compile the URL for the GET communication with EZIC.com

    # Basic secure URL and account info.
    set full_url "[ad_parameter ezic_url -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_url]]?account_id=[ns_urlencode [ad_parameter ezic_login -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_login]]]"
    # site_tag is optional when there is only one
    if {[string length [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]] > 0 } {
        append full_url "&site_tag=[ns_urlencode [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]]"
    }

    # Set the transaction type to CREDIT and the transaction id.
 
    append full_url "&pay_type=C&tran_type=C&amount=[ns_urlencode [format "%0.2f" $amount]]&tax_amount=[ns_urlencode [format "%0.2f" 0]]&ship_amount=[ns_urlencode [format "%0.2f" 0]]&trans_id=$transaction_id"

    # Set the credit card information.
    # EZIC requires separate first and last name fields (a bank services field checking requirement)
    # $card_name should contain a field pair in ecommerce to hold first_names and last_name
    # delimiter is triple space (for parsing).
    set name_delim [string first "   " $card_name]
    if {$name_delim < 0 } {
        set name_delim 0
    }
    set first_names [string trim [string range $card_name 0 $name_delim]]
    set last_name [string range $card_name [expr $name_delim + 3 ] end]
    append full_url "&card_number=[ns_urlencode $card_number]&card_expire=[ns_urlencode ${card_exp_month}${card_exp_year}]&bill_name2=[ns_urlencode $last_name]&bill_name1=[ns_urlencode $first_names]"

    # Contact EZIC.com and receive the delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to EZIC.

    if {[string equal $test_request "True"]} {
        ns_log Notice "MARK -- EZIC TEST CREDIT outbound full_url = '$full_url'"
    }

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
        if {[string equal $test_request "True"]} {
            ns_log Notice "EZIC: Response is: [value_if_exists $error_message]"
        }
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes retry]
        set return(reason) "Transaction $transaction_id CREDIT failed, could not contact EZIC.com: $error_message"
        set return(transaction_id) $transaction_id
        return [array get return]
    } else {

        # 3. Insert into log table

        # Decode the response from EZIC.com. Not all fields are
        # of interest. See the EZIC documentation:
        # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
        # and start of this file for a list of some response codes.

        set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

        # Check that the response from EZIC is a legimate ADC
        # response. When EZIC.com has problems the response is
        # not a character delimited list but an HTML page. An ADC
        # response has certainly 7 elements, plus first blank element is 8. Future
        # versions might return more elements.

        set response_list_len [llength $response_list]
        if { $response_list_len < 3 || $response_list_len > 15 } {
            ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" $response 3 "" \
            "EZIC gateway might be down, the response was not a list of 7 fields" "" "" "" "" $amount
            set return(response_code) [nsv_get payment_gateway_return_codes retry]
            set return(reason) "EZIC gateway might be down, the response was not a list of 7 fields."
            set return(transaction_id) $transaction_id
            return [array get return]
        } else {

            # Ezic says they might change the order that fields are presented in response
            # so adding lsearch to set elements from arbitrary response list order.
            # EZIC uses cgi response format, so set fields to values right of "=" (value may be empty)
            # apparently EZIC returns auth_date which we ignore for now
            set response_reason_code [string range [lindex $response_list [lsearch $response_list {status_code=*}]] 12 end]
            set response_reason_text [string range [lindex $response_list [lsearch $response_list {auth_msg=*}]] 9 end]
            set response_auth_code [string range [lindex $response_list [lsearch $response_list {auth_code=*}]] 10 end]
            set response_avs_code [string range [lindex $response_list [lsearch $response_list {avs_code=*}]] 9 end]
            set response_transaction_id [string range [lindex $response_list [lsearch $response_list {trans_id=*}]] 9 end]
            set response_cvv2_code [string range [lindex $response_list [lsearch $response_list {cvv2_code=*}]] 10 end]
            set response_ticket_code [string range [lindex $response_list [lsearch $response_list {ticket_code=*}]] 12 end]

            # translate reason_code from status_code to existing authorize.net mapping
            if { $response_reason_code == 1 || $response_reason_code == "T" } {
                set response_code 1
            } elseif { $response_reason_code == "0" } {
                # for status_code values 0
                set response_code 2
            } else {
                # must be an error somewhere
                set response_code 3
            }

            ezic_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" \
            $response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $response_cvv2_code $response_ticket_code $amount

            # 4. Return result

            return [ezic_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text $amount]
        }
    }
}

ad_proc -public ezic_gateway.void {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_code
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to EZIC.com to void the transaction with transaction_id.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {
    # 1. Send transaction off to gateway

    set test_request [ezic_gateway.decode_test_request]

    set field_seperator [ad_parameter field_seperator \
                 -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator \
                -default [ad_parameter \
                          -package_id [apm_package_id_from_key ezic-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url \
             -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] referer_url]]

    # EZIC refers to "VOID" as a refund.

    # Add the Referer to the headers passed on to EZIC.com

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    if {[string length $card_number] < 2} {
        # card_number must have been deleted. Reject transaction
        set error_message "Card number not available. VOID transaction rejected."
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes failure]
        set return(reason) "Transaction $transaction_id VOID failed. No card number."
        set return(transaction_id) $transaction_id
        return [array get return]
    }

    # Compile the URL for the GET communication with EZIC.com

    # Basic secure URL and account info.
    set full_url "[ad_parameter ezic_url -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_url]]?account_id=[ns_urlencode [ad_parameter ezic_login -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_login]]]"
    # site_tag is optional when there is only one
    if {[string length [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]] > 0 } {
        append full_url "&site_tag=[ns_urlencode [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]]"
    }

    # Set the transaction type to VOID (EZIC: Refund)
 
    append full_url "&pay_type=C&tran_type=R&amount=[ns_urlencode [format "%0.2f" $amount]]&tax_amount=[ns_urlencode [format "%0.2f" 0]]&ship_amount=[ns_urlencode [format "%0.2f" 0]]&orig_id=$transaction_id"

    # Set the credit card information.
    # EZIC requires separate first and last name fields per bank field checking
    # $card_name is hacked field pair in ecommerce to hold first_names and last_name
    # delimiter is triple space (for parsing).
    set name_delim [string first "   " $card_name]
    if {$name_delim < 0 } {
        set name_delim 0
    }
    set first_names [string trim [string range $card_name 0 $name_delim]]
    set last_name [string range $card_name [expr $name_delim + 3 ] end]
    append full_url "&card_number=[ns_urlencode $card_number]&card_expire=[ns_urlencode ${card_exp_month}${card_exp_year}]&bill_name2=[ns_urlencode $last_name]&bill_name1=[ns_urlencode $first_names]"

    # Contact EZIC.com and receive the delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to EZIC.com

    if {[string equal $test_request "True"]} {
        ns_log Notice "MARK -- EZIC TEST VOID outbound full_url = '$full_url'"
    }

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
        if {[string equal $test_request "True"]} {
            ns_log Notice "EZIC: Response is: [value_if_exists $error_message]"
        }
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes retry]
        set return(reason) "Transaction $transaction_id VOID failed, could not contact EZIC gateway: $error_message"
        set return(transaction_id) $transaction_id
        return [array get return]
    } else {

        # 2. Insert into log table

        # Decode the response from EZIC.com. Not all fields are
        # of interest. See the EZIC documentation:
        # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
        # and start of this file for a list of some response codes.

        set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

        # Check that the response from EZIC.com is a legimate ADC
        # response. When EZIC has problems the response is
        # not a character delimited list but an HTML page. An ADC
        # response has 7 elements, plus first blank element is 8. Future
        # versions might return more elements.

        set response_list_len [llength $response_list]
        if { $response_list_len < 3 || $response_list_len > 15 } {
            ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" $response 3 "" \
            "EZIC gateway might be down, the response was not a character delimited list" "" "" "" "" $amount
            set return(response_code) [nsv_get payment_gateway_return_codes retry]
            set return(reason) "EZIC gateway might be down, the response was not a character delimited list"
            set return(transaction_id) $transaction_id
            return [array get return]
        } else {

            # Ezic says they might change the order that fields are presented in response
            # so adding lsearch to set elements from arbitrary response list order.
            # EZIC uses cgi response format, so set fields to values right of "=" (value may be empty)
            # apparently EZIC returns auth_date which we ignore for now
            set response_reason_code [string range [lindex $response_list [lsearch $response_list {status_code=*}]] 12 end]
            set response_reason_text [string range [lindex $response_list [lsearch $response_list {auth_msg=*}]] 9 end]
            set response_auth_code [string range [lindex $response_list [lsearch $response_list {auth_code=*}]] 10 end]
            set response_avs_code [string range [lindex $response_list [lsearch $response_list {avs_code=*}]] 9 end]
            set response_transaction_id [string range [lindex $response_list [lsearch $response_list {trans_id=*}]] 9 end]
            set response_cvv2_code [string range [lindex $response_list [lsearch $response_list {cvv2_code=*}]] 10 end]
            set response_ticket_code [string range [lindex $response_list [lsearch $response_list {ticket_code=*}]] 12 end]

            # translate reason_code from status_code to existing authorize.net mapping
            if { $response_reason_code == 1 || $response_reason_code == "T" } {
                set response_code 1
            } elseif { $response_reason_code == "0" } {
                # for status_code values 0
                set response_code 2
            } else {
                # must be an error somewhere
                set response_code 3
            }

            ezic_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" \
            $response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $response_cvv2_code $response_ticket_code $amount

            # 3. Return result

            return [ezic_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text $amount]
        }
    }
}

ad_proc -public ezic_gateway.info {
} {
    Return information about EZIC.com implementation of the
    payment service contract. Returns the package_key, version, package name
    cards accepted and a list of return codes.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {

    array set info [list \
            package_key ezic-gateway \
            version [db_string get_package_version {}] \
            package_name [db_string get_package_name {}] \
            cards_accepted [ad_parameter CreditCardsAccepted \
                        -default [ad_parameter \
                              -package_id [apm_package_id_from_key ezic-gateway] CreditCardsAccepted]] \
            success [nsv_get payment_gateway_return_codes success] \
            failure [nsv_get payment_gateway_return_codes failure] \
            retry [nsv_get payment_gateway_return_codes retry] \
            not_supported [nsv_get payment_gateway_return_codes not_supported] \
            not_implemented [nsv_get payment_gateway_return_codes not_implemented]]
    return [array get info]
}

# These stubs aren't exposed via the API - they are called only by ChargeCard.

ad_proc -private ezic_gateway.postauth {
    transaction_id
    auth_code
    card_number
    card_exp_month
    card_exp_year
    card_name
    amount
} {
    Connect to EZIC gateway to PRIOR_AUTH_CAPTURE the transaction with transaction id. 
    The transaction needs to have been AUTH_ONLY before calling this procedure.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {
    # 1. Send transaction off to gateway

    set test_request [ezic_gateway.decode_test_request]

    set field_seperator [ad_parameter field_seperator \
                 -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator \
                -default [ad_parameter \
                          -package_id [apm_package_id_from_key ezic-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url \
             -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] referer_url]]

    # Add the Referer to the headers passed on to EZIC gateway

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    if {[string length $card_number] < 2} {
        # card_number must have been deleted. Reject transaction
        set error_message "Card number not available. PRIOR_AUTH_CAPTURE transaction rejected."
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" $error_message 3 "" $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes failure]
        set return(reason) "Transaction $transaction_id PRIOR_AUTH_CAPTURE failed. No card number."
        set return(transaction_id) $transaction_id
        return [array get return]
    }

    # Compile the URL for the GET communication with EZIC gateway

    # Basic secure URL and account info.
    set full_url "[ad_parameter ezic_url -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_url]]?account_id=[ns_urlencode [ad_parameter ezic_login -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_login]]]"
    # site_tag is optional when there is only one
    if {[string length [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]] > 0 } {
        append full_url "&site_tag=[ns_urlencode [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]]"
    }

    # Set the transaction type to PRIOR_AUTH_CAPTURE, the transaction_id
    # to the id of the transaction that has been authorized and the
    # auth_code to the authorization code of that transaction.
 
    append full_url "&pay_type=C&tran_type=D&amount=[ns_urlencode [format "%0.2f" $amount]]&tax_amount=[ns_urlencode [format "%0.2f" 0]]&ship_amount=[ns_urlencode [format "%0.2f" 0]]&orig_id=$transaction_id"

    # Set the credit card information.
    # EZIC requires separate first and last name fields per bank field checking
    # $card_name is hacked field pair in ecommerce to hold first_names and last_name
    # delimiter is triple space (for parsing).
    set name_delim [string first "   " $card_name]
    if {$name_delim < 0 } {
        set name_delim 0
    }
    set first_names [string trim [string range $card_name 0 $name_delim]]
    set last_name [string range $card_name [expr $name_delim + 3 ] end]
    append full_url "&card_number=[ns_urlencode $card_number]&card_expire=[ns_urlencode ${card_exp_month}${card_exp_year}]&bill_name2=[ns_urlencode $last_name]&bill_name1=[ns_urlencode $first_names]"

    # Contact EZIC.com and receive the delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to EZIC.com

    if {[string equal $test_request "True"]} {
        ns_log Notice "MARK -- EZIC TEST PRIOR_AUTH_CAPTURE outbound full_url = '$full_url'"
    }

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
        if {[string equal $test_request "True"]} {
            ns_log Notice "EZIC: Response is: [value_if_exists $error_message]"
        }
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" $error_message 3 "" \
        $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes retry]
        set return(reason) "Transaction $transaction_id failed, could not contact EZIC gateway: $error_message"
        set return(transaction_id) $transaction_id
        return [array get return]
    } else {

        # 2. Insert into log table

        # Decode the response from EZIC.com. Not all fields are
        # of interest. See the EZIC documentation:
        # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
        # and start of this file for a list of some response codes.

        set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

        # Check that the response from EZIC.com is a legimate ADC
        # response. When EZIC has problems the response is
        # not a character delimited list but an HTML page. An ADC
        # response has 7 elements, plus first blank element is 8. Future
        # versions might return more elements.

        set response_list_len [llength $response_list]
        if { $response_list_len < 3 || $response_list_len > 15 } {
            ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" $response 3 "" \
            "EZIC gateway might be down, the response was not a character delimited list" "" "" "" "" $amount
            set return(response_code) [nsv_get payment_gateway_return_codes retry]
            set return(reason) "EZIC gateway might be down, the response was not a character delimited list"
            set return(transaction_id) $transaction_id
            return [array get return]
        } else {

            # Ezic says they might change the order that fields are presented in response
            # so adding lsearch to set elements from arbitrary response list order.
            # EZIC uses cgi response format, so set fields to values right of "=" (value may be empty)
            # apparently EZIC returns auth_date which we ignore for now
            set response_reason_code [string range [lindex $response_list [lsearch $response_list {status_code=*}]] 12 end]
            set response_reason_text [string range [lindex $response_list [lsearch $response_list {auth_msg=*}]] 9 end]
            set response_auth_code [string range [lindex $response_list [lsearch $response_list {auth_code=*}]] 10 end]
            set response_avs_code [string range [lindex $response_list [lsearch $response_list {avs_code=*}]] 9 end]
            set response_transaction_id [string range [lindex $response_list [lsearch $response_list {trans_id=*}]] 9 end]
            set response_cvv2_code [string range [lindex $response_list [lsearch $response_list {cvv2_code=*}]] 10 end]
            set response_ticket_code [string range [lindex $response_list [lsearch $response_list {ticket_code=*}]] 12 end]

            # translate reason_code from status_code to existing authorize.net mapping
            if { $response_reason_code == 1 || $response_reason_code == "T" } {
                set response_code 1
            } elseif { $response_reason_code == "0" } {
                # for status_code values 0
                set response_code 2
            } else {
                # must be an error somewhere
                set response_code 3
            }

            ezic_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" \
            $response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $response_cvv2_code $response_ticket_code $amount

            # 3. Return result

            return [ezic_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code \
            $response_reason_text $amount]
        }
    }
}

ad_proc -private ezic_gateway.authcapture {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_code
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to EZIC gateway to authorize and schedule the transaction for automatic 
    settling. No further action is needed to complete the transastion. 

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {
    # 1. Send transaction off to gateway

    set test_request [ezic_gateway.decode_test_request]

    set field_seperator [ad_parameter field_seperator \
                 -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator \
                -default [ad_parameter \
                          -package_id [apm_package_id_from_key ezic-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url \
             -default [ad_parameter \
                       -package_id [apm_package_id_from_key ezic-gateway] referer_url]]

    # Add the Referer to the headers passed on to EZIC gateway

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with EZIC gateway

    # Basic secure URL and account info.
    set full_url "[ad_parameter ezic_url -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_url]]?account_id=[ns_urlencode [ad_parameter ezic_login -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_login]]]"
    # site_tag is optional when there is only one
    if {[string length [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]] > 0 } {
        append full_url "&site_tag=[ns_urlencode [ad_parameter ezic_sitetag -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] ezic_sitetag]]]"
    }

    # Set the transaction type to AUTH_CAPTURE
    # EZIC will generate the transaction id 
    # and return. The EZIC gateway transaction id will be stored in
    # the response_transaction_id. 
 
    append full_url "&pay_type=C&tran_type=S&amount=[ns_urlencode [format "%0.2f" $amount]]&tax_amount=[ns_urlencode [format "%0.2f" 0]]&ship_amount=[ns_urlencode [format "%0.2f" 0]]&description=[ns_urlencode [ad_parameter "description"]]"

    # Set the credit card information.
    # EZIC requires separate first and last name fields per bank field checking
    # $card_name is hacked field pair in ecommerce to hold first_names and last_name
    # delimiter is triple space (for parsing).
    set name_delim [string first "   " $card_name]
    if {$name_delim < 0 } {
        set name_delim 0
    }
    set first_names [string trim [string range $card_name 0 $name_delim]]
    set last_name [string range $card_name [expr $name_delim + 3 ] end]
    append full_url "&card_number=[ns_urlencode $card_number]&card_expire=[ns_urlencode ${card_exp_month}${card_exp_year}]&bill_name2=[ns_urlencode $last_name]&bill_name1=[ns_urlencode $first_names]"

    # Set the billing information. The information will be sent to
    # EZIC to run an AVS check.

    append full_url "&bill_street=[ns_urlencode $billing_street]&bill_city=[ns_urlencode $billing_city]&bill_zip=[ns_urlencode $billing_zip]&bill_state=[ns_urlencode $billing_state]&bill_country=[ns_urlencode $billing_country]"

    # Contact EZIC.com and receive the delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to EZIC.com.

    if {[string equal $test_request "True"]} {
        ns_log Notice "MARK -- EZIC TEST AUTH_CAPTURE outbound full_url = '$full_url'"
    }

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
        if {[string equal $test_request "True"]} {
            ns_log Notice "EZIC: Response is: [value_if_exists $error_message]"
        }
        ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" $error_message 3 "" \
        $error_message "" "" "" "" $amount
        set return(response_code) [nsv_get payment_gateway_return_codes retry]
        set return(reason) "Transaction $transaction_id failed, could not contact EZIC gateway: $error_message"
        set return(transaction_id) $transaction_id
        return [array get return]
    } else {

        # 2. Insert into log table

        # Decode the response from EZIC.com. Not all fields are
        # of interest. See the EZIC documentation:
        # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
        # and start of this file for a list of some response codes.

        set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

        # Check that the response from EZIC is a legimate ADC
        # response. When EZIC.com has problems the response is
        # not a character delimited list but an HTML page. An ADC
        # response has 7 elements, plus first blank element is 8. Future
        # versions might return more elements.

        set response_list_len [llength $response_list]
        if { $response_list_len < 3 || $response_list_len > 15 } {
            ezic_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" $response 3 "" \
            "EZIC gateway must be down, the response was not a character delimited list" "" "" "" "" $amount
            set return(response_code) [nsv_get payment_gateway_return_codes retry]
            set return(reason) "EZIC gateway must be down, the response was not a character delimited list"
            set return(transaction_id) $transaction_id
            return [array get return]
        } else {

            # Ezic says they might change the order that fields are presented in response
            # so adding lsearch to set elements from arbitrary response list order.
            # EZIC uses cgi response format, so set fields to values right of "=" (value may be empty)
            # apparently EZIC returns auth_date which we ignore for now
            set response_reason_code [string range [lindex $response_list [lsearch $response_list {status_code=*}]] 12 end]
            set response_reason_text [string range [lindex $response_list [lsearch $response_list {auth_msg=*}]] 9 end]
            set response_auth_code [string range [lindex $response_list [lsearch $response_list {auth_code=*}]] 10 end]
            set response_avs_code [string range [lindex $response_list [lsearch $response_list {avs_code=*}]] 9 end]
            set response_transaction_id [string range [lindex $response_list [lsearch $response_list {trans_id=*}]] 9 end]
            set response_cvv2_code [string range [lindex $response_list [lsearch $response_list {cvv2_code=*}]] 10 end]
            set response_ticket_code [string range [lindex $response_list [lsearch $response_list {ticket_code=*}]] 12 end]

            # translate reason_code from status_code to existing authorize.net mapping
            if { $response_reason_code == 1 || $response_reason_code == "T" } {
                set response_code 1
            } elseif { $response_reason_code == "0" } {
                # for status_code values 0
                set response_code 2
            } else {
                # must be an error somewhere
                set response_code 3
            }

            authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" \
            $response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

            # 3. Return result

            return [ezic_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text $amount]
        }
    }
}

ad_proc -private ezic_gateway.decode_response {
    transaction_id
    response_transaction_id
    response_code
    response_reason_code
    response_reason_text
    amount
} {
    Decode the response from EZIC gateway. 
    Map EZIC gateway Direct Mode 3 response codes to standardized payment service
    contract response codes.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004
} {
    # decode the response code and the reason code.

    switch -exact $response_code {
        "1" {
            set return(response_code) [nsv_get payment_gateway_return_codes success]
            set return(reason) "Transaction $response_transaction_id has been approved."
            set return(transaction_id) $response_transaction_id
            return [array get return]
        }
        "2" {
            set return(response_code) [nsv_get payment_gateway_return_codes failure]
            set return(reason) "Transaction $response_transaction_id has been declined: $response_reason_text"
            set return(transaction_id) $transaction_id
            return [array get return]
        }
        "3" {

            # Some of the transactions that encounter an 
            # error while being processed can be retried in a
            # little while. See the EZIC documentation:
            # https://secure.ezic.com/public/docs/merchant/public/directmode/directmode3.html 
            # and start of this file for a list of some response codes.

            # skipping this part (No error re-try codes from EZIC)

            # All other transactions failed indefinitely.

            set return(response_code) [nsv_get payment_gateway_return_codes failure]
            set return(reason) "There has been an error processing transaction $response_transaction_id: $response_reason_text"
            set return(transaction_id) $transaction_id
            return [array get return]
        }
        default {
            set return(response_code) [nsv_get payment_gateway_return_codes not_implemented]
            set return(reason) "EZIC gateway returned an unknown response_code: $response_reason_code"
            set return(transaction_id) $transaction_id
            return [array get return]
        }
    }
}

ad_proc -private ezic_gateway.decode_test_request {
} {
    Set test_request to True/False based on the test_request parameter of the
    package. This prevents errors due to incorrect values of the test_request
    parameter

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date March 2002
} {

    switch -exact [string tolower [ad_parameter test_request \
                       -default [ad_parameter -package_id [apm_package_id_from_key ezic-gateway] test_request]]] {
        "0" -
        "n" -
        "no" -
        "false" { 
            set test_request "False"
        }
        "1" -
        "y" -
        "yes" - 
        "true" {
            set test_request "True"
        }
        default {
            set test_request "False"
        }
    }
    return $test_request
}

ad_proc -private ezic_gateway.log_results {
    transaction_id
    txn_attempted_time
    txn_attempted_type
    response
    response_code
    response_reason_code
    response_reason_text
    auth_code
    avs_code
    cvv2_code
    ticket_code
    amount
} {
    Write the results of the current operation to the database.  If it fails,
    log it but don't let the user know about it.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @author revised by Torben Brosten <torben@dekka.net>
    @revision-date January 2004

} {
    set ezic_url [ad_parameter ezic_url \
               -default [ad_parameter \
                     -package_id [apm_package_id_from_key ezic-gateway] \
                     ezic_url]]
    # catch non nulls as zero so errors can be logged.
    if {[string length $transaction_id] <= 1} {
        set $transaction_id 999999
    }
    if {[string length $amount] == 0} {
        set amount 0.00
    }

    # now filter and process

    if {[string length $response] > 400} {
        ns_log Notice "Response from $ezic_url exceeds database field length. Trimming response '$response' to 400 characters."
        set response [string range $response 0 399]
    }
    if {[string length $response_reason_text] > 100} {
        ns_log Notice "Response reason text from $ezic_url exceeds database field length. Trimming response reason text '$response_reason_text' to 100 characters."
        set response_reason_text [string range $response_reason_text 0 99]
    }
    
    if {[string length $response_code] > 2} {
        ns_log Error "re: $ezic_url response_code=${response_code} --too long for ezic_gateway_result_log transaction_id ${transaction_id}"
        set response_code [string range $response_code 0 1]
    }
    if {[string length $response_reason_code] > 2} {
        ns_log Error "re: response_reason_code=${response_reason_code} --too long for ezic_gateway_result_log transaction_id ${transaction_id}"
        set response_reason_code [string range $response_reason_code 0 1]
    }
    if {[string length $cvv2_code] > 2} {
        ns_log Error "re: cvv2_code=${cvv2_code} --too long for ezic_gateway_result_log transaction_id ${transaction_id}"
        set cvv2_code [string range $cvv2_code 0 1]
    }


    if [catch {db_dml do-insert "
	insert into ezic_gateway_result_log
	(transaction_id, txn_attempted_time, txn_attempted_type, response, response_code, response_reason_code, response_reason_text, auth_code, avs_code, cvv2_code, ticket_code, amount) 
	values 
	(:transaction_id, :txn_attempted_time, :txn_attempted_type, :response, :response_code, :response_reason_code, :response_reason_text, :auth_code, :avs_code, :cvv2_code, :ticket_code, :amount)"} errmsg] {
        ns_log Error "Was not able to insert into ezic_gateway_result_log for transaction_id ${transaction_id}; error was ${errmsg}"
    }
}

ad_proc -private ezic_gateway.expand_avs {
    {avs_code ""}
} {
    Convert AVS code to text response.

    @creation-date September 2008
} {
    # this is not going into a db table because this data rarely changes, the package is a service, and the only access should be via the api anyway.
    switch -exact -- $avs_code {
        D -
        F -
        J -
        M -
        Q -
        V -
        X -
        Y { set avs_text "Address and ZIP code match" }
        L -
        W -
        Z { set avs_text "ZIP code matches, address does not" }
        A -
        B -
        O -
        P { set avs_text "Address matches, ZIP code does not" }
        K -
        N { set avs_text "No Match on Address (Street) or ZIP" }
        U { set avs_text "No data from issuer / bank network" }
        R { set avs_text "Retry - System unavailable or timed out" }
        S { set avs_text "Service not supported by issuer" }
        E { set avs_text "Error, AVS not supported for your business." }
        C { set avs_text "(Int'l) Invalid address and ZIP format" }
        I { set avs_text "(Int'l) Address not verifiable" }
        G { set avs_text "(Int'l) Global non-verifiable address" }
        default { set avs_text "Unrecognized code or no AVS data available" }
    }
    # default covers:
    # ?:   Unrecognized code (none of the above) 
    # _:   No AVS data (_ means <null character>)
    return $avs_text
}
