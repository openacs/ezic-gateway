select acs_sc_binding__delete(
    'PaymentGateway',
    'ezic-gateway'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'ezic-gateway',
    'Authorize'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'ezic-gateway',
    'ChargeCard'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'ezic-gateway',
    'Return'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'ezic-gateway',
    'Void'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'ezic-gateway',
    'Info'
);

select acs_sc_binding__delete(
    'PaymentGateway',
    'ezic-gateway'
);

select acs_sc_impl__delete(
    'PaymentGateway',
    'ezic-gateway'
);

