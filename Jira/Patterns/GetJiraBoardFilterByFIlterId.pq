(previousStep as table, Domains as text, FilterIds as text, optional NewFilterColumnName as nullable text)=>
let NewFilterColumnName = if NewFilterColumnName = null then "jql" else NewFilterColumnName in 
	Table.ExpandRecordColumn(
	    Table.AddColumn(previousStep, NewFilterColumnName, each 
	      if Text.From( Record.Field(_,Domains)) = "<your domain>" 
	      then 
		    Json.Document(Web.Contents(
	          "<your domain>",
	          [RelativePath = "/rest/api/2/filter/" &Text.From( Record.Field(_,FilterIds))]
	        )) 
	      else null
	    ), NewFilterColumnName, {"jql"}, {NewFilterColumnName}
      )
