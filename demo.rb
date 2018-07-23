
require 'blobfish/ejbca'

# Copied from https://stackoverflow.com/a/1117003/320594.
def random_string(length=10)
  chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
  password = ''
  length.times { password << chars[rand(chars.size)] }
  password
end

# End entity data.
tax_number = '20202020201'
company_name = 'CONTOSO S.A.'
nid = '20202020'
surname = 'PEREZ VARGAS'
given_name = 'JUAN CARLOS'
email_address = 'jdoe@example.org'
locality = 'Lima'

# This client could be created only once and then be reused for requesting several PFX files.
ejbca_client = Blobfish::Ejbca::Client.new('https://ejbca.demo.blobfish.pe:8443/ejbca/ejbcaws/ejbcaws?wsdl', nil, 'client.cer', 'client.key', 'secret', 'LlamaPeStandardCa',  'LlamaPePJEndUserNoApproval_CP', 'LlamaPePJEndUserNoNotification_EE')

# Preparing data to be sent to EJBCA.
# NOTE that 'ejbca_username' can be anything unique, but a human readable pattern is recommended to keep it easy to inspect EJBCA records.
ejbca_username = "llama_#{tax_number}_#{nid}"
subject_dn = "CN=#{given_name} #{surname},emailAddress=#{email_address},serialNumber=#{nid},O=#{company_name},OU=#{tax_number},L=#{locality},C=PE"
subject_alt_name = "rfc822name=#{email_address}"

request_cert = lambda { |validity_days|
  pfx_random_password = random_string(8)
  puts "Requesting EJBCA side PFX generation with the following random password #{pfx_random_password} (validity: #{validity_days} days)..."
  resp = ejbca_client.request_pfx(ejbca_username, email_address, subject_dn, subject_alt_name, validity_days, pfx_random_password)

  cert = resp[:cert]
  puts 'Certificate generated successfully:'
  puts "  - Serial number: #{cert.serial_hex}"
  puts "  - Subject DN: #{cert.subject.to_s(OpenSSL::X509::Name::RFC2253)}"
  puts "  - Valid from: #{cert.not_before}"
  puts "  - Valid to: #{cert.not_after}"

  pfx_path = "#{tax_number}_#{nid}_#{validity_days}.pfx"
  pfx_bytes = resp[:pfx]
  File.binwrite(pfx_path, pfx_bytes)
  puts "PFX successfully saved in #{pfx_path}"

  puts

  return cert
}

cert_1_year = request_cert[365]
cert_2_years = request_cert[730]
cert_3_years = request_cert[1095]

puts "Requesting revocation for certificate with serial number #{cert_2_years.serial_hex}..."
ejbca_client.revoke_cert(cert_2_years.serial_hex)
puts 'Certificate revoked'
puts

puts "Listing all certs for user #{ejbca_username}..."
all_certs = ejbca_client.get_all_certs(ejbca_username)
all_certs.each do |cert|
  revocation_status = ejbca_client.get_revocation_status(cert.serial_hex)
  printf "  - #{cert.serial_hex} => "
  if revocation_status.nil?
    printf " not revoked\n"
  else
    printf " revoked on #{revocation_status[:revocation_date]}\n"
  end
end
