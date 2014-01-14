Devise NemID integration
========================

This module allows for "easier" integration with the danish NemID service.

In order to use this module you must be registered at NemID as service
provider ("Tjenesteudbyder").
See more at: 
https://www.nets-danid.dk/produkter/for_tjenesteudbydere/nemid_tjenesteudbyder/


Certificate
-----------
For this to work you need a certificate which is obtained after you register.
After registration you will receive an email with a link where you can
generate the certificate.
The certificate must be in PKCS12 format and must be protected by a password.

A certificate is usable only in one of the NemID environments.
Pay close attention to which environment you are generating a certificate for.

Place the certificate as follows:
  production: nemid/ocesii_danid_env_prod.p12
  preprod: nemid/ocesii_danid_env_preprod.p12
  test: nemid/ocesii_danid_env_externaltest.p12

!!!  *NEVER EVER put these files in any open repository.* !!!

If you are using git, add the following line to .gitignore
  nemid

You should only have one certificate in one instance.
But for easier testing in development, multiple files are allowed.

This module will look for the appropiate certificate file depending on the
configuration.


Configuration
-------------
The following options exists.
Each will be explained further down.

  Devise.dk_nemid_environment = 'ocesii_danid_env_prod'
  Devise.dk_nemid_certificate_pasword = 'secret'
  Devise.dk_nemid_allowed = ['otp', 'software', 'digitalsignatur']

  Devise.dk_nemid_cpr_service = 'none'
  Devise.dk_nemid_cpr_failures = 5
  Devise.dk_nemid_cpr_pid_spid = 'id'
  Devise.dk_nemid_cpr_rid_spid = 'id'

  Devise.dk_nemid_proxy = 'http://proxy:80'

The minimum required for nemid login to work is a production certificate and
password for the certifcate.

environment
  Any valid nemid environment id
  Most used are:
  ocesii_danid_env_prod - Use the production environment (default)
  ocesii_danid_env_preprod - Use the pre production environment
  ocesii_danid_env_externaltest - Use the test environment
  Read the NemId documention for more information or take a look in 
  nemid/ca for known root certificates for environments.

certificate_password
  The password for the certificate

allowed
  Which login options are supported:
  otp - Allow login with keycard (default)
  software - Allow login with hardware token
  digitalsignatur - Allow login with digital signature from local file
  The layout will adjust it self to these options.

cpr_service
  Request lookup/verification of CPR in login flow.
  See section named "Cpr Service" for further information.

cpr_failures
  See section named "Cpr Service" for further information.

cpr_pid_spid
  See section named "Cpr Service" for further information.

cpr_rid_spid
  See section named "Cpr Service" for further information.

proxy
  See section named "Cpr Service" for further information.

Cpr Service
-----------
NemId offers a PID -> CPR conversion service for private users and a RID -> 
CPR service for employees.

As a public institution you will be allowed to get the CPR from PID/RID,
without user input.

As a private company you are allowed to verify that a user given CPR match
the PID/RID from the certificate.

The configuration setting CprService can be set to none, public or private to
reflect the above.

  none = CPR is not needed for this application (default)
  public = CPR will be fetched from PID/RID service
  private = The user will be requested to input the CPR after succesfull
            NemID login, and the given CPR will be verified.
            The user will not be logged in until the CPR given is correct.

Devise.dk_nemid_cpr_failures are the maximum number of times a CPR can be
given during the login process. After this a new NemID login is required.

This process requeries a registration ID for each of these of services.
These ID's are put in cpr_pid_spid and cpr_rid_spid

  Devise.dk_nemid_cpr_pid_spid = 'your_pid_id_here'
  Devise.dk_nemid_cpr_rid_spid = 'your_rid_id_here'

If you only handle either private or employee the unused id can of course
be left blank.

The service is implemented through the user of soap operations over http.
If you need you can add a proxy server definition in dk_nemid_proxy, which
will be used when doing http soap requests.
