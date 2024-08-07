(previousStep as table, Domains as text, Filters as text, optional NewKeyColumnName as nullable text)=>
let NewKeyColumnName = if NewKeyColumnName = null then "keys" else NewKeyColumnName in 
	  Table.RemoveColumns(Table.ExpandRecordColumn(
	    Table.ExpandListColumn(
		  Table.ExpandRecordColumn(
		    Table.AddColumn(Table.AddColumn(previousStep, "tmpCustom", each Text.BeforeDelimiter(Record.Field(_,Filters)," ORDER BY ",0)),NewKeyColumnName, each 
	          if Text.From( Record.Field(_,Domains)) = "<your domain>" 
	          then 
			    Json.Document(Web.Contents(
	              "<your domain>",
	              [RelativePath = "/rest/api/2/search/",
	               Query = [
	                  jql=Text.From(Record.Field(_,Filters)) ,
					          fields="key",
                    maxResults="100000"
	               ]
	              ]
	            )) 
	          else null
	        ), NewKeyColumnName, {"issues"}
		  ), "issues"
		), "issues", {"key"}, {NewKeyColumnName}
	  ),"tmpCustom")
