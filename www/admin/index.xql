<?xml version="1.0"?>
<queryset>

  <fullquery name="get_package_name">
    <querytext>
      select p.instance_name 
      from apm_packages p, apm_package_versions v
      where p.package_id = :package_id
      and p.package_key = v.package_key
      and v.enabled_p = 't'
    </querytext>
  </fullquery>

  <partialquery name="result_approved">      
    <querytext>
      response_code='1'
    </querytext>
  </partialquery>

  <partialquery name="result_declined">      
    <querytext>
      response_code='2'
    </querytext>
  </partialquery>

  <partialquery name="result_error">
    <querytext>
      response_code='3'
    </querytext>
  </partialquery>

</queryset>
