<master>
  <property name="title">@title@</property>
  <property name="signatory">@signatory@</property>
  <property name="header_stuff"><link href="index.css" type="text/css" rel="stylesheet"></property>
  <if @admin_p@ and @ezic_gateway_mounted@>
    <property name="context_bar"><table width="100%"><tbody><tr><td align="left">@context_bar;noquote@</td><td align="right">[ <a href="@package_url@admin/">Administer</a> ]</td></tr> </tbody></table></property>
  </if>
  <else>
    <property name="context_bar">@context_bar@</property>
  </else>

<h2>Description</h2>

<p>The @package_name@ package implements the <if @payment_gateway_installed@
    eq 1><a href="/doc/payment-gateway"></if>Payment Service
    Contract<if @payment_gateway_installed@ eq 1></a></if> for the <a
    href="http://www.ezic.com">EZIC</a> on-line merchant
    services.
</p>

<p>The @package_name@ is the intermediary between OpenACS packages
    and the EZIC credit card acceptance services. This
    gateway accepts calls to the Payment Service Contract operations,
    forwards the information to the EZIC gateway and decodes the response
    before returning the outcome back to the calling package while
    keeping a log of all communication with EZIC. The log is
    accessible from the <if @ezic_gateway_mounted@><a
    href="@package_url@admin"></if>@package_name@ administration<if
    @ezic_gateway_mounted@></a></if>.
</p>

 
<h2>Background</h2>

<p>The <if @ecommerce_installed@ eq 1><a href="/doc/ecommerce"></if>ecommerce package<if @ecommerce_installed@ eq 1></a></if> 
    originally used online merchant credit-card payment fulfillment services provided by CyberCash.  
    Verisign bought Cybercash and merged it with their own PayflowPro service, leaving the 
    ecommerce package without a functioning credit card payment fulfillment service. 
</p>

<p><a href="mailto:janine@furfly.net">Janine Sisk</a> of <a
      href="http://www.furfly.net">furfly.net</a> and <a
      href="mailto:bart.teeuwisse@thecodemill.biz">Bart Teeuwisse</a>
      teamed together to produce a general purpose payment service contract
      and to create the first implementations of the contract. Janine
      developed the interface to PayflowPro the successor of CyberCash
      while Bart created the gateway to Authorize.net.
</p>

<p><a href="http://www.berklee.edu">Berklee College Of Music</a>
    sponsored the creation of the Authorize.net package and its integration
    with the <if @ecommerce_installed@ eq 1><a
    href="/doc/ecommerce"></if>ecommerce package<if
    @ecommerce_installed@ eq 1></a></if>.  <a href="http://www.kingsolar.com">King Solar</a>
    sponsored the adaption of the Authorize.net Gateway to the @package_name@.
</p>

<h2>Requirements</h2>

<p> The @package_name@ requires the <a href="http://www.aolserver.com">AOLserver</a> 
    <a href="http://www.scottg.net/webtools/aolserver/modules/nsopenssl/">nsopenssl</a> module to be installed.
    Nsopenssl provides the <tt>ns_httpsget</tt> and <tt>ns_httpspost</tt> instructions to connect to the secure ADC server. 
    Aolserver 3.x requires nsopenssl version 2.x, Aolserver 4.x requires nsopenssl version 3.x. 
    The latest revision is available from Aolserver.com's
    <a href="http://sourceforge.net/project/showfiles.php?group_id=3152&package_id=41599">download area</a>.
</p>
<p>
    Please follow the installation instructions included with the software.
</p>
<p> Oracle Admins: This release has been developed on PostgreSQL only. 
    The database queries appear to be compatible with Oracle, 
    however the files for creating the Oracle data-model and administrative reports have not been created.
    Please report any problems to package maintainer, or the bugtracker at 
    <a href="http://openacs.org/">OpenACS.org</a>. You can also contribute 
    patches there, for example to update Oracle support.
</p>
<p class="note">
      Note: The following is mentioned for your information only. No action is anticipated for these items. 
</p>
<p> EZIC saves credit card numbers in their database, so that merchants do not need to.
    Card numbers are then accessible via the transaction_id. 
    It is theoretically possible to upgrade this package with ecommerce to use the 
    Ecommerce package "SaveCreditCardDataP" parameter's feature while meeting 
    current credit card security requirements.
</p>
<p>
      <a href="http://dqd.com/~mayoff/aolserver/">Dqd_utils</a> is not required or used.
</p>
<p>
     EZIC Gateway requires cardholder first and last name to be supplied separately for AVS. 
     OpenACS uses first_names and last_name fields for the user. The Ecommerce package data model
     combines user's first_names and last_name as default value for card_name (ec_addresses.attn).
     A 3 space delimiter separates the two values in the card_name field, so that gateway packages,
     including this one, can split the field to separate names for AVS purposes. 
</p>
<h2>Configuration</h2>
<p>The @package_name@ needs to be configured before it can connect
    to EZIC.com and access your account with EZIC.com
    Configuration is via <if @ezic_gateway_mounted@><a
    href="/admin/site-map/parameter-set?package%5fid=@package_id@&section%5fname=all"></if>@package_name@
    parameters<if @ezic_gateway_mounted@></a></if>. The package
    has 8 parameters:
</p>

<ol>
  <li>

      <h3>CreditCardsAccepted</h3>

      <p>A list of credit cards accepted by your EZIC.com 
	account. Calling applications can use this list or overwrite
	it with their own list so that applications can choose to
	accept only a subset of the cards your EZIC account
	can handle.</p>
  </li>
  <li>
      <h3>test_request</h3>

      <p>EZIC package test mode. When true, adds communication 
         send data to the aolserver log. Does *not* put
         EZIC.com's gateway in transaction test mode. The default is
         'false'. EZIC response data is noted on the admin page.
      </p>
      <p class="note">Note: For EZIC Transaction Test mode see EZIC.com :Account config :Credit cards - Optional Test Mode from the EZIC website Merchant access control pages.
      </p>

  </li>
  <li>

      <h3>ezic_url</h3>

      <p>The location (URL) of the EZIC.com Gateway. Unless you
	received a different location from EZIC, there is no
	need to change the default value. </p>

  </li>
  <li>

      <h3>referer_url</h3>

      <p>The location (full URL formal) of your web site where the communication
	with  originates from. This URL will be used in the post header to EZIC.
      </p>
      <p class="note">EZIC uses ip number filtering. Be sure to include the ip number
        of your server in the appropriate EZIC.com security field.
      </p>

  </li>
  <li>
      <h3>ezic_login</h3>

      <p>Your EZIC merchant or agent Account ID (not SiteID)
      </p>
  </li>
  <li>
      <h3>ezic_sitetag</h3>

      <p>Your EZIC merchant or agent Site Tag. This is optional if merchant
         has only configured one site in the EZIC.com merchant access area. The
         sitetag is defined in the EZIC ':Setup :Website config' menu area.
      </p>
  </li>
  <li>

    <h3>field_encapsulator</h3>

    <p>The field encapsulation character in the Automated Direct
      Connect (ADC) settings of EZIC.com. Currently, EZIC does not use
      this feature, so leave it blank. The code is grandfathered into
      this package from Authorize.net package, to make it easier to
      adapt to this feature, should EZIC require it at some point.
    </p>

  </li>
  <li>

    <h3>field_seperator</h3>

    <p>The field seperator in Automated Direct Connect (ADC)
      EZIC Direct Mode.  This is the character that delimits (separates)
      the elements in the response from EZIC.com. As of Jan. 2004, this
      value is not changeable. Leave as is. Default is '&amp;'.
    </p>

  </li>
</ol>
<h2>Glossary</h2>
<ul>
    <li>
     ADC - Automated Direct Connect, another way of stating EZIC Direct Mode
    </li>
    <li>
     AVS - Address Verification System
    </li>
    <li>
    package key - For this package: ezic-gateway
    </li>
  </ul>

  <h2>API Reference</h2>

  <p>The <if @payment_gateway_installed@ eq 1><a
      href="/doc/payment-gateway"></if>Payment Service Contract<if
    @payment_gateway_installed@ eq 1></a></if> explains the API to other
  packages in detail.</p>
  
  <p>Visit the <a href="https://secure.ezic.com/public/docs/merchant/public/directmode/">EZIC
    Direct Mode documentation</a> for in-depth documentation of the
    EZIC Direct Mode API that this package interfaces with. Be sure to review
    the additional security measures available via the EZIC 
    merchant access control area and virtual terminal.
  </p>

  <h2>Credits</h2>

  <p>The @package_name@ was adapted by 
      <a href="mailto:torben@kappacorp.com">Torben Brosten</a> for 
      <a href="http://kingsolar.com">King Solar</a> from the
      Authorize-Gateway Package, which was originally designed and written by
      <a href="mailto:bart.teeuwisse@thecodemill.biz">Bart Teeuwisse</a>
      for <a href="http://www.berklee.edu">Berklee College Of
      Music</a> while working as a subcontractor for <a
      href="http://www.furfly.net">furfly.net</a>.
  </p>
  <p>The @package_name@ is free software; you can redistribute it
    and/or modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.
  </p>
  <p>The @package_name@ is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.
  </p>
  <p>A <a href="license">copy of the GNU General Public License</a> is
    included. If not write to the Free Software Foundation, Inc., 59
    Temple Place, Suite 330, Boston, MA 02111-1307 USA
  </p>







