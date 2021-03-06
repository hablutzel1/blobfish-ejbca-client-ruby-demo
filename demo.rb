
require 'blobfish/ejbca'

# Copied from https://stackoverflow.com/a/1117003/320594.
def random_string(length=10)
  chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
  password = ''
  length.times { password << chars[rand(chars.size)] }
  password
end

def gen_sample_csr
  priv_key = OpenSSL::PKey::RSA.generate(2048, 65537)
  req = OpenSSL::X509::Request.new
  req.subject = OpenSSL::X509::Name.parse("/CN=dummy")
  req.public_key = priv_key.public_key
  req.sign(priv_key, OpenSSL::Digest::SHA256.new)
  req.to_pem
end

def print_cert_info(cert)
  puts 'Certificate generated successfully:'
  puts "  - Serial number: #{cert.serial_hex}"
  puts "  - Issuer DN: #{cert.issuer.to_s(OpenSSL::X509::Name::RFC2253)}"
  puts "  - Subject DN: #{cert.subject.to_s(OpenSSL::X509::Name::RFC2253)}"
  puts "  - Valid from: #{cert.not_before}"
  puts "  - Valid to: #{cert.not_after}"
end

# Importing method with a shorter name.
e = Blobfish::Ejbca::Client.method(:escape_dn_attr_value)

# End entity data.
tax_number = '20202020201'
company_name = 'CONTOSO S.A.'
title = 'General manager'
nid = '20202020'
surname = 'PEREZ VARGAS'
given_name = 'JUAN CARLOS'
email_address = 'jdoe@example.org'
street_address = 'Av. Los Corales 123, San Isidro'
locality = 'Lima'
validated_by = 'Validated by XYZ'

# This client could be created only once and then be reused for requesting several certificates.
# TODO try make these arguments overridable to be able to modify them for alternative development environments.
ejbca_client = Blobfish::Ejbca::Client.new('https://localhost:8443/ejbca/ejbcaws/ejbcaws?wsdl', 'cacerts_localhost.pem', 'client.cer', 'client.key', 'secret')

# Preparing data to be sent to EJBCA.
ca_name = 'MyCertificationAuthority'
cert_profile = 'MyCertProfile'
ee_profile = 'MyEndEntityProfile'
# NOTE that 'ejbca_username' can be anything unique, but a human readable pattern is recommended to keep it easy to inspect EJBCA records.
ejbca_username = "#{tax_number}_#{nid}"
subject_dn = "CN=#{e[given_name]} #{e[surname]},emailAddress=#{e[email_address]},serialNumber=#{e[nid]},O=#{e[company_name]},OU=#{e[tax_number]},OU=#{e[validated_by]},T=#{e[title]},L=#{e[locality]},street=#{e[street_address]},C=PE"
subject_alt_name = "rfc822name=#{email_address}"
pfx_friendly_name = tax_number + '_' + nid

write_to_file = lambda { |data, ext, validity_type, validity_value|
  path = "#{tax_number}_#{nid}_#{validity_type}_#{validity_value.to_s.gsub(/[^\w.]/, '_')}.#{ext}"
  File.binwrite(path, data)
  puts ".#{ext} successfully saved in #{path}"
}

request_pfx_demo = lambda {|validity_type, validity_value|
  pfx_random_password = random_string(8)
  puts "Requesting EJBCA side PFX generation with the following random password #{pfx_random_password} (Validity: #{validity_type} #{validity_value})..."
  resp = ejbca_client.request_pfx(ca_name, cert_profile, ee_profile, ejbca_username, email_address, subject_dn, subject_alt_name, validity_type, validity_value, pfx_random_password, pfx_friendly_name)
  cert = resp[:cert]
  print_cert_info(cert)
  write_to_file[resp[:pfx], 'pfx', validity_type, validity_value]
  puts
  return cert
}

request_from_csr_demo = lambda {|pem_csr, validity_type, validity_value|
  puts "Requesting EJBCA certificate signature for existing CSR (Validity: #{validity_type} #{validity_value})..."
  cert = ejbca_client.request_from_csr(ca_name, cert_profile, ee_profile, pem_csr, ejbca_username, email_address, subject_dn, subject_alt_name, validity_type, validity_value)
  print_cert_info(cert)
  write_to_file[cert.to_pem, 'cer', validity_type, validity_value]
  puts
  return cert
}

cert_1_year = request_pfx_demo[:days_from_now, 365]
cert_2_years = request_pfx_demo[:days_from_now, 730]
cert_3_years = request_pfx_demo[:days_from_now, 1095]

cert_1_year_from_csr = request_from_csr_demo[gen_sample_csr, :days_from_now, 365]

puts "Requesting revocation for certificate with serial number #{cert_2_years.serial_hex} issued by #{cert_2_years.issuer.to_s(OpenSSL::X509::Name::RFC2253)}..."
ejbca_client.revoke_cert(cert_2_years)
puts 'Certificate revoked'
puts

# Requesting reissue for the certificate previously revoked
reissued_cert_2_years = request_pfx_demo[:fixed_not_after, cert_2_years.not_after]

puts "Listing all certs for user #{ejbca_username}..."
all_certs = ejbca_client.get_all_certs(ejbca_username)
all_certs.each do |cert|
  revocation_status = ejbca_client.get_revocation_status(cert)
  printf "  - #{cert.issuer.to_s(OpenSSL::X509::Name::RFC2253)}, #{cert.serial_hex} => "
  if revocation_status.nil?
    printf " not revoked\n"
  else
    printf " revoked on #{revocation_status[:revocation_date]}\n"
  end
end
puts
