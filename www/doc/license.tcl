ad_page_contract {

    License information of the Authorize.net Gateway, an
    implementation of the Payment Service Contract.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @modified-by Torben Brosten <torben@kappacorp.com>
    @creation-date May 2002
    @modified-date Feb 2004

} {
} -properties {
    title:onevalue
    context_bar:onevalue
}

# Authenticate the user

set user_id [auth::require_login]

set package_name "Authorize.net Gateway"
set title "$package_name License"

# Set the context bar.

set context_bar [ad_context_bar [list . $package_name] License]

# Set signatory for at the bottom of the page

set signatory "torben@kappacorp.com"
