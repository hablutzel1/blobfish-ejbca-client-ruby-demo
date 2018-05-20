require 'blobfish/ejbca'

# Copiado de https://stackoverflow.com/a/1117003/320594.
def random_string(length=10)
  chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
  password = ''
  length.times { password << chars[rand(chars.size)] }
  password
end

# Este cliente puede ser creado una sola vez y luego ser reutilizado para la solicitud de varios archivos PFX.
cliente_ejbca = Blobfish::Ejbca::Client.new('https://ejbca.demo.blobfish.pe:8443/ejbca/ejbcaws/ejbcaws?wsdl', 'superadmin_llama.cer', 'superadmin_llama.key', 'secret', 'LlamaPeStandardCa',  'LlamaPePJEndUserNoApproval_CP', 'LlamaPePJEndUserNoNotification_EE')

# Nótese que el nombre de usuario en el EJBCA será construido a partir del RUC y el DNI.
ruc = '20202020201'
razon_social = 'CONTOSO S.A.'
dni = '20202020'
apellidos = 'PEREZ VARGAS'
nombres = 'JUAN CARLOS'
correo_electronico = 'jdoe@example.org'
departamento = 'Lima'
contrasena_aleatoria_para_pfx = random_string(8)

puts 'Solicitando generación de PFX del lado del EJBCA con la siguiente contraseña aleatoria ' + contrasena_aleatoria_para_pfx
pfx_en_bytes = cliente_ejbca.request_pfx(ruc, razon_social, dni, apellidos, nombres, correo_electronico, departamento, contrasena_aleatoria_para_pfx)
ruta_pfx = ruc + '_' + dni + '.pfx'
File.binwrite(ruta_pfx, pfx_en_bytes)
puts 'El PFX fue guardado correctamente en ' + ruta_pfx
