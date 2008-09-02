ad_page_contract {

    A place holder for access to the admin pages.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date April 2002

} {
} -properties {
    title:onevalue
    context_bar:onevalue
}

# Authenticate the user

set user_id [auth::require_login]

# Check for admin privileges

set package_id [ad_conn package_id]
set admin_p [ad_permission_p $package_id admin]

# Get the name of the package

if {[db_0or1row get_package_name {}]} {
    set title "$instance_name"
} else {
    set title "EZIC Merchant Gateway"
}

# Set the context bar.

set context [list $title]
