ad_page_contract {

    A place holder for access to the admin pages.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @modified-by Torben Brosten <torben@kappacorp.com>
    @creation-date April 2002
    @modified-date Feb 2004

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

if {[db_0or1row get_package_name "
    select p.instance_name 
    from apm_packages p, apm_package_versions v
    where p.package_id = :package_id
    and p.package_key = v.package_key
    and v.enabled_p = 't'"]} {
    set title "$instance_name"
} else {
    set title "EZIC Gateway package"
}

# Set the context bar.

set context_bar [ad_context_bar]
