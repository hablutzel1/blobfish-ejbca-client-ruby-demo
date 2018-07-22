require 'blobfish/ejbca'

# Copied from https://stackoverflow.com/a/1117003/320594.
def random_string(length=10)
  chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
  password = ''
  length.times { password << chars[rand(chars.size)] }
  password
end

# This client could be created only once and then be reused for requesting several PFX files.
ejbca_client = Blobfish::Ejbca::Client.new('https://192.168.2.3:8443/ejbca/ejbcaws/ejbcaws?wsdl', 'ca-certificates.crt', 'superadmin_llama.cer', 'superadmin_llama.key', 'secret', 'LlamaPeStandardCa',  'LlamaPePJEndUserNoApproval_CP', 'LlamaPePJEndUserNoNotification_EE')

# Note that EJBCA's username will be constructed from the tax number and NID.
tax_number = '20202020201'
organization_name = 'CONTOSO S.A.'
nid = '20202020'
last_name = 'PEREZ VARGAS'
name = 'JUAN CARLOS'
email = 'jdoe@example.org'
locality = 'Lima'
pfx_random_password = random_string(8)

puts 'Requesting EJBCA side PFX generation with the following random password ' + pfx_random_password
pfx_bytes = ejbca_client.request_pfx(tax_number, organization_name, nid, last_name, name, email, locality, pfx_random_password)
pfx_path = tax_number + '_' + nid + '.pfx'
File.binwrite(pfx_path, pfx_bytes)
puts 'PFX successfully saved in ' + pfx_path
