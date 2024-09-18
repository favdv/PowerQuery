let 
functionName = "Jira.GetFilterByFilterId",
doc = 
  [
    Documentation.Api = "https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-filters/#api-rest-api-2-filter-id-get",
    Documentation.Name =  "Get JIRA Filter by Filter Id", 
    Documentation.Description = "This function is a jira specific pattern, which retrieves the filter for specific filter ids. Ensure you modify your domain(s) to suit your specific requirements. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace "&functionName&" with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Retrieve Filter Ids with specified column name",
            Code = functionName&"(Source, ""DomainColumn"",""FilterId"",""Filter"")",
            Result = "A new column 'Filter' is added with the filter Id for value combination the specified columns"
          ],
          [
            Description = "Retrieve Filter Ids with default column name",
            Code = functionName&"(Source, ""DomainColumn"",""FilterId"")",
            Result = "A new column 'jql' (default column name) is added with the filter for value combination the specified columns"
          ]
	}
  ],
fn = (previousStep as table, Domains as text, FilterIds as text, optional NewFilterColumnName as nullable text)=>
let NewFilterColumnName = if NewFilterColumnName = null then "jql" else NewFilterColumnName in 
	Table.ExpandRecordColumn(
	    Table.AddColumn(previousStep, NewFilterColumnName, each 
	      if Text.From( Record.Field(_,Domains)) = "<domain>" 
	      then 
		    Json.Document(Web.Contents(
	          "<domain>",
	          [RelativePath = "/rest/api/2/filter/" &Text.From( Record.Field(_,FilterIds))]
	        )) 
	      else null
	    ), NewFilterColumnName, {"jql"}, {NewFilterColumnName}
      )

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
