require "restforce"
require "json"
require "csv"

########################################################################################
# Set these variables
########################################################################################

credentials_path                 = "./environments/sandboxes/iiq-rtphase1.json"
profile_report_output            = "./output/permsets.csv"
object_permissions_report_output = "./output/ps_object_permissions.csv"

########################################################################################
# Here we go!
########################################################################################

credentials_file = File.read(credentials_path)
credentials = JSON.parse(credentials_file)

puts "Building Permission Set and SObject permission reports for " << credentials["username"] << "..."

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
description = client.describe('PermissionSet')
description.fields.each do |field|
    fields[field.name] = field.label
end

query  = 'SELECT ' + fields.keys.join(',') + ' FROM PermissionSet'
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

# Run SObject permission query
fields = { "Parent.Name" => "Permission Set Name"}
description = client.describe('ObjectPermissions')
description.fields.each do |field|
    fields[field.name] = field.label
end

query  = 'SELECT ' + fields.keys.join(', ') + ' FROM ObjectPermissions WHERE NOT Parent.Name LIKE \'X00e%\''
sObject_permissions = client.query(query).sort_by{ |permission| permission.Parent[:Name] }

CSV.open(object_permissions_report_output, "wb") do |writer|
    writer << fields.values
    sObject_permissions.each do |permission|
        values = [];
        fields.keys.each do |field|
            if field == "Parent.Name"
                values.push(permission.Parent[:Name])
            else
                values.push(permission[field])
            end
        end
        writer << values
    end
end

puts "Done!"