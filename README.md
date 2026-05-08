# dnstools
DNSSEC shell script tools for secure DNS zone deployment and process automation for plain text zone files.

 - **dnsnewserial.sh** — updates DNS zone serial
 - **dnssignzone.sh** — signs zone using actual keys set
 - **dnszskrotate.sh** — rotates zone signing keys
 - **dnstools.cf** — common settings for DNSSEC tools
 - **getsmimea.sh** — creates SMIMEA DNS record using provided X509 file

Please see this [article](https://kostikov.co/podderzhka-dnssec-i-rotaciya-klyuchej-cifrovoj-podpisi
) on details (currently available in Russian only).

 *Requires [ldns](https://www.nlnetlabs.nl/projects/ldns/) toolset*
