require 'csv'
require 'rally_api'
require 'pp'

def clear_project(project_name) 
    
    p = find_object(:project,project_name)

    list = @rally.find do |q|
      q.type  = "story"
      q.project_scope_up = false
      q.project_scope_down = false
      q.fetch = true
      q.limit = 1000
      q.project = p
    end
    puts "deleting #{list.length} stories"
    list.each { |item|
        print item["Name"],"\n"
        item.delete
    }
    
    list = @rally.find do |q|
      q.type  = "defect"
      q.project_scope_up = false
      q.project_scope_down = false
      q.fetch = true
      q.limit = 1000
      q.project = p
    end
    puts "deleting #{list.length} defects"
    list.each { |item|
        print item["Name"],"\n"
        item.delete
    }


end

def find_object_query(type,query)
	object_query = RallyAPI::RallyQuery.new()
	object_query.type = type
	object_query.fetch = "Name,ObjectID,FormattedID,Parent"
	object_query.project_scope_up = false
	object_query.project_scope_down = true
	object_query.order = "Name Asc"
	object_query.query_string = query
	results = @rally.find(object_query)
	
	results.each do |obj|
		return obj if (obj.Name.eql?(name))
	end
	nil
end

def parse_row(row)
    
    if row["Tags"] && row["Tags"] != ""
        print "looking for tag:#{row['Tags']}\n"
        tags = find_object(:tag,row["Tags"])
        print "found tag:#{tags['ObjectID']}\n"
    end

    fields = {}
    fields["StoryID"] = row["StoryID"]
    fields["ScheduleState"] = "Initial"
    fields["Name"] = row["Name"]
    fields["Project"] = find_object(:project,row["Project Team"])
    fields["ProductCategory"] = row["Category"]
    fields["ProductSubCategory"] = row["Sub-Category"]
    fields["Description"] = row["Description"]
    fields["Notes"] = row["Notes"]
    fields["PlanEstimate"] = row["StoryPoints"]
    if (row["Release"] && row["Release"] != "")
        fields["Release"] = find_object(:release,row["Release"]) 
    end
    fields["ALMQCID"] = row["ALM_ID"]
    
    type = (row["Type"] == "defect" ? "defect" : "story")
    
    obj = create(type,fields)
    
    if (tags)
        @rally.update(type,obj["ObjectID"],{ "Tags" => [tags] })
        print obj["Tags"],"\n"
    end
    
end

def find_object(type,name)
	object_query = RallyAPI::RallyQuery.new()
	object_query.type = type
	object_query.fetch = "Name,ObjectID,FormattedID,Parent"
	object_query.project_scope_up = false
	object_query.project_scope_down = true
	object_query.order = "Name Asc"
	object_query.query_string = "(Name = \"" + name + "\")"
	results = @rally.find(object_query)
	results.each do |obj|
		return obj if (obj.Name.eql?(name))
	end
	nil
end

def create(type,fields)

  new_object = @rally.create(type, fields)
  print "Created Object:#{new_object['ObjectID']} #{new_object['FormattedID']}\n"
  new_object
    
end

headers = RallyAPI::CustomHttpHeader.new({:vendor => "Rally TAM", :name => "Backlog", :version => "1.0"})

config = {:base_url => "https://rally1.rallydev.com/slm"}
config[:username]   = ""
config[:password]   = ""
config[:workspace]  = ""
# config[:project]    = "A Team"
config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()

@rally = RallyAPI::RallyRestJson.new(config)
@workspace = find_object(:workspace,config[:workspace])

pp @workspace

pp find_object(:project,"TOA")

file=File.open('backlog (2).csv', "r:ISO-8859-1")
input = CSV.parse(file)
header = input.first #header row

rows = []
#(1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }

(1...input.size).to_a.reverse.each { |i| rows << CSV::Row.new(header, input[i]) }

clear_project("TOA")
clear_project("MWF IT")
clear_project("MWF Steering")

rows.each { |row| parse_row(row) }

# clear_project("TOA")
# clear_project("MWF IT")
# clear_project("MWF Steering")
# clear_project("Mobile Workforce Team")
