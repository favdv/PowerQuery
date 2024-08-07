/* 
This function is a jira specific pattern, which retrieves the keys based on the filters for specific boards. 

Ensure you modify your domain(s) to suit your specific requirements. 

The source table needs to have a column with the jira domain and one column with the jql filter. 
Note in the function the ordering is stripped from the jql as this breaks the function.
You can also provide a new column name if you wish to do so.

Assuming the name of the function will be GetJIRAKeysByBoardFilter, the table is called Table1 and the column names DomainColumn and FilterColumn respectively, the function can be called via 
newStep = GetJIRAKeysByBoardFilter(Table1, "DomainColumn",FilterColumn")

See also the README.md file in the repository for more information on how to implement this. 
*/

(previousStep as table, Domains as text, Filters as text, optional NewKeyColumnName as nullable text)=>
let NewKeyColumnName = if NewKeyColumnName = null then "keys" else NewKeyColumnName in 
  Table.RemoveColumns(Table.ExpandRecordColumn(
	  Table.ExpandListColumn(
		  Table.ExpandRecordColumn(
		    Table.AddColumn(
	    		Table.AddColumn(previousStep, "tmpCustom", 
            each Text.BeforeDelimiter(Record.Field(_,Filters)," ORDER BY ",0)),NewKeyColumnName, each 
	            if Text.From( Record.Field(_,Domains)) = "<your domain>" 
	            then Json.Document(Web.Contents("<your domain>",
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
