create table ezic_gateway_result_log (
    transaction_id 		varchar(20) not null, -- trans_id
    txn_attempted_type  	varchar(18),
    txn_attempted_time 		timestamptz,
    response 			varchar(400),
    response_code 		varchar(2),   -- ezic status_code to AN response_code
    response_reason_code 	varchar(2),   -- ezic status_code
    response_reason_text       	varchar(100), -- ezic auth_msg
    auth_code                  	varchar(8),   -- ezic auth_code
    avs_code                   	varchar(12),  -- ezic avs_code
    cvv2_code 			varchar(2),   -- billing info verification code (new)
    ticket_code 		varchar(40),   -- approval code, no info avail (new)
    amount                     	numeric not null
);

create index ezic_gateway_result_log_transaction_id on ezic_gateway_result_log(transaction_id);

\i ezic-gateway-sc-create.sql
