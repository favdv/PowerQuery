let 
functionName = "Jira.GetBoardFilterIdByBoardId",
doc = 
  [
    Documentation.Name =  "Get JIRA Filter ID from Board Ids", 
    Documentation.Description = "This function is a jira specific pattern, which retrieves the filter id for specific boards (by board id). Once the Filter ID is retrieved, the filter itself can be retrieved via a subsequent api call. Ensure you modify your domain(s) to suit your specific requirements. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace "&functionName &" with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Retrieve Filter Ids with specified column name",
            Code = functionName &"(Source, ""DomainColumn"",""BoardIdColumn"",""FilterId"")",
            Result = "A new column 'FilterId' is added with the filter Id for value combination the specified columns"
          ],
          [
            Description = "Retrieve Filter Ids with default column name",
            Code = functionName &"(Source, ""DomainColumn"",""BoardIdColumn"")",
            Result = "A new column 'Filter id' (default column name) is added with the filter Id for value combination the specified columns"
          ]
        }
    
  ],
fn = (previousStep as table, Domains as text, BoardIds as text, optional NewFilterColumnName as nullable text)=>
let NewFilterColumnName = if NewFilterColumnName = null then "filter id" else NewFilterColumnName in Table.ExpandRecordColumn(
Table.ExpandRecordColumn(
    Table.AddColumn(previousStep, NewFilterColumnName, each 
    if Text.From( Record.Field(_,Domains)) = "<domain>" 
    then 
        Json.Document(Web.Contents(
        "<domain>",
        [RelativePath = "/rest/agile/1.0/board/" & Record.Field(_,BoardIds) & "/configuration"]
        )) 
    else null
   ), 
   NewFilterColumnName,{"filter"}, {NewFilterColumnName}
 ), NewFilterColumnName, {"id"},{NewFilterColumnName}
)

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
