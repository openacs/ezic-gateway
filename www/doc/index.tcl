ad_page_contract {

    Index to documentation of the Authorize.net Gateway, an
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

set package_name "EZIC Gateway"
set title "$package_name Package Documentation"
set package_url [apm_package_url_from_key "ezic-gateway"]
set package_id [apm_package_id_from_key "ezic-gateway"]

# Check if the package has been mounted.

set ezic_gateway_mounted [expr ![empty_string_p $package_url]]

# Check for admin privileges

set admin_p [ad_permission_p $package_id admin]

# Check if the ecommerce and the shipping service contract packages
# are installed on the system.

set ecommerce_installed [apm_package_installed_p ecommerce]
set payment_gateway_installed [apm_package_installed_p "payment-gateway"]

# Set the context bar.

set context_bar [ad_context_bar $package_name]

# Set signatory for at the bottom of the page

set signatory "torben@kappacorp.com"
