require "restforce"
require "json"
require "csv"

########################################################################################
# Set these variables
########################################################################################

credentials_path                 = "./environments/sandboxes/iiq-rtsc.json"
profile_report_output            = "./output/profiles.csv"
object_permissions_report_output = "./output/object_permissions.csv"

########################################################################################
# Here we go!
########################################################################################

credentials_file = File.read(credentials_path)
credentials = JSON.parse(credentials_file)

client = Restforce.new(
    username:       credentials["username"],
    password:       credentials["password"],
    security_token: credentials["security_token"],
    client_id:      credentials["client_id"],
    client_secret:  credentials["client_secret"],
    api_version:    credentials["api_version"],
    host:           credentials["host"],
)

# Get all profile fields and store as hash of field api name => field label
fields = {}
description = client.describe('Profile')
description.fields.each do |field|
    fields[field.name] = field.label
end

query  = 'SELECT ' + fields.keys.join(',') + ' FROM Profile'
profiles = client.query(query)

CSV.open(profile_report_output, "wb") do |writer|
    writer << fields.values # output field labels
    profiles.each do |p|
        values = [];
        fields.each do |field, label|
            values.push(p[field]) # output field api name values
        end
        writer << values
    end
end


fields = ["Id", "Parent.Profile.Name", "SobjectType", "PermissionsCreate", "PermissionsDelete", "PermissionsEdit", "PermissionsModifyAllRecords", "PermissionsRead", "PermissionsViewAllRecords"]
query  = 'SELECT ' + fields.join(', ') + ' FROM ObjectPermissions'
sObject_permissions = client.query(query);

CSV.open(object_permissions_report_output, "wb") do |writer|
    writer << fields
    sObject_permissions.each do |permission|
        if permission.Parent.Profile != nil
            values = [];
            fields.each do |field|
                if field == "Parent.Profile.Name"
                    values.push(permission.Parent.Profile["Name"])
                else
                    values.push(permission[field])
                end
            end
            writer << values
        end
    end
end