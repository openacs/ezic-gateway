-- This is an EZIC Direct Mode 3.0 implementation of the PaymentGateway
-- service contract (package)

select acs_sc_impl__new(
	   'PaymentGateway',               	-- impl_contract_name
           'ezic-gateway',                      -- impl_name
	   'ezic-gateway'                       -- impl_owner_name
);


select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'ezic-gateway',			-- impl_name
	   'Authorize', 			-- impl_operation_name
	   'ezic_gateway.authorize', 	        -- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'ezic-gateway',			-- impl_name
	   'ChargeCard', 			-- impl_operation_name
	   'ezic_gateway.chargecard', 	        -- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'ezic-gateway',			-- impl_name
	   'Return', 				-- impl_operation_name
	   'ezic_gateway.return', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'ezic-gateway',			-- impl_name
	   'Void', 				-- impl_operation_name
	   'ezic_gateway.void', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

select acs_sc_impl_alias__new(
           'PaymentGateway',			-- impl_contract_name
           'ezic-gateway',			-- impl_name
	   'Info', 				-- impl_operation_name
	   'ezic_gateway.info', 		-- impl_alias
	   'TCL'    				-- impl_pl
);

-- Add the binding

select acs_sc_binding__new (
           'PaymentGateway',
           'ezic-gateway'
);

