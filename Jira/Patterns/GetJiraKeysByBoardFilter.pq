/* 
This function is a jira specific pattern, which retrieves the keys by the domain and project names.
Ensure you modify your domain(s) to suit your specific requirements. 

The source table needs to have a column with the jira domain and one column with the Board Ids. THe Project column is not needed.

Assuming the name of the function will be GetJiraKeysByBoardFilter, the table is called Table1 and the column names DomainColumn and BoardColumn respectively, the function can be called via 
newStep = GetJiraKeysByBoardFilter(Table1, "DomainColumn","BoardColumn")

The 3 steps are also available as separate functions. in case partitioning is an issue or is you only with to retrieve the filter id or board filter.
See also the README.md file in the repository for more information on how to implement this. 
*/

(previousStep as table, Domains as text, BoardIds as text)=>
let 
#"Get Filter id for board" = 
	  Table.ExpandRecordColumn(
		Table.ExpandRecordColumn(
		  Table.AddColumn(previousStep, "filter id", each 
			if Text.From( Record.Field(_,Domains)) = "https://iagtech.atlassian.net" 
			then 
			  Json.Document(Web.Contents(
			   "https://iagtech.atlassian.net",
			   [RelativePath = "/rest/agile/1.0/board/" & Record.Field(_,BoardIds) & "/configuration"]
			  )) 
			else null
		  ), 
		  "filter id", {"filter"}
		), "filter", {"id"}, {"Filter Id"}
	  ),
  
	#"Get Filters for board" =
	  Table.ExpandRecordColumn(
	    Table.AddColumn(#"Get Filter id for board", "jql", each 
	      if Text.From( Record.Field(_,Domains)) = "https://iagtech.atlassian.net" 
	      then 
		    Json.Document(Web.Contents(
	          "https://iagtech.atlassian.net",
	          [RelativePath = "/rest/api/2/filter/" &Text.From( Record.Field(_,"Filter Id"))]
	        )) 
	      else null
	    ), "jql", {"jql"}, {"jql filter"}
      ),
  
	//Keeping the order by in the jql above will cause the data retrieval to fail
	
	#"Strip Order By" = 
      Table.RenameColumns(
	    Table.AddColumn(#"Get Filters for board", "Custom", each Text.BeforeDelimiter([jql filter]," ORDER BY ",0))
		,{{"Custom", "jql"}}
	  ),
  
    
	#"Get Keys via API" = 
	  Table.ExpandRecordColumn(
	    Table.ExpandListColumn(
		  Table.ExpandRecordColumn(
		    Table.AddColumn(#"Strip Order By", "keys", each 
	          if Text.From( Record.Field(_,Domains)) = "https://iagtech.atlassian.net" 
	          then 
			    Json.Document(Web.Contents(
	              "https://iagtech.atlassian.net",
	              [RelativePath = "/rest/api/2/search/",
	               Query = [
	                  jql=Text.From(Record.Field(_,"jql")) ,
					          fields="key",
                    maxResults="100000"
	               ]
	              ]
	            )) 
	          else null
	        ), "keys", {"issues"}
		  ), "issues"
		), "issues", {"key"}
	  ),

	#"RemoveFilterCols" = Table.RemoveColumns(#"Get Keys via API",{"Filter Id", "jql filter", "jql"})
in #"RemoveFilterCols"
