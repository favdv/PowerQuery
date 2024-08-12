/* 
This function is a jira specific pattern, which retrieves the board filter based on the filter id for specific boards. 

Ensure you modify your domain(s) to suit your specific requirements. 
The source table needs to have a column with the jira domain and one column with the Filter Ids. 
You can also provide a new column name for the newly created filter column if you wish to do so.

Assuming the name of the function will be GetJiraBoardFilterId, the table is called Table1 and the column names DomainColumn and FilterIdColumn respectively, the function can be called via 
newStep = GetJiraBoardFilterByFIlterId(Table1, "DomainColumn","FilterIdColumn")

See also the README.md file in the repository for more information on how to implement this. 
*/

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
