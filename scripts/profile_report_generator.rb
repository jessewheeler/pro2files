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

fields = []

description = client.describe('Profile')
description.fields.each do |field|
    fields.push(field.name)
end

query  = 'SELECT ' + fields.join(',') + ' FROM Profile'
profiles = client.query('SELECT ' + fields.join(', ') + ' FROM Profile')

CSV.open(profile_report_output, "wb") do |writer|
    writer << fields
    profiles.each do |p|
        values = [];
        fields.each do |field|
            values.push(p[field])
        end
        writer << values
    end
end


fields = ["Id", "Parent.Profile.Name", "SobjectType", "PermissionsCreate", "PermissionsDelete", "PermissionsEdit", "PermissionsModifyAllRecords", "PermissionsRead", "PermissionsViewAllRecords"]
query  = 'SELECT ' + fields.join(', ') + ' FROM ObjectPermissions LIMIT 1'
sObject_permissions = client.query(query);

CSV.open(object_permissions_report_output, "wb") do |writer|
    writer << fields
    sObject_permissions.each do |permission|
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