# Blobfish::Ejbca demo

## EJBCA authentication credentials

Current demonstration project includes credentials (`client.cer` and `client.key`) for an user belonging to a custom Administrator Role, "Llama.pe RA application".
 
This Administrator Role have been created with **only the following Access Rules**, which restrict it as much as possible:

- **Role Template**: RA Administrators
- **Authorized CAs**: LlamaPeStandardCa
- **End Entity Rules**: 
  - Create End Entities
  - Edit End Entities
  - Revoke End Entities
  - View End Entities
- **End Entity Profiles**: LlamaPePJEndUserNoNotification_EE

Always remember that Access Rules for a client of this type should be restricted as much as possible; **credentials for a superadmin should never be used!**.