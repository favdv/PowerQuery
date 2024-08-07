/* 
This function is a jira specific pattern, which retrieves the filter id for specific boards. 
With this ID, the filter itself can be retrieved.

Ensure you modify your domain(s) to suit your specific requirements. 
The source table needs to have a column with the jira domain and one column with the Board Ids. You can also provide a new column name if you wish to do so.

Assuming the name of the function will be GetJiraBoardFilterId, the table is called Table1 and the column names DomainColumn and BoardIdColumn respectively, the function can be called via 
newStep = GetJiraBoardFilterId(Table1, "DomainColumn","BoardIdColumn")
See also the README.md file in the repository for more information on how to implement this. 
*/

(previousStep as table, Domains as text, BoardIds as text, optional NewFilterColumnName as nullable text)=>
let NewFilterColumnName = if NewFilterColumnName = null then "filter id" else NewFilterColumnName in Table.ExpandRecordColumn(
Table.ExpandRecordColumn(
    Table.AddColumn(previousStep, NewFilterColumnName, each 
    if Text.From( Record.Field(_,Domains)) = "<your domain>" 
    then 
        Json.Document(Web.Contents(
        "<your domain>",
        [RelativePath = "/rest/agile/1.0/board/" & Record.Field(_,BoardIds) & "/configuration"]
        )) 
    else null
    ), 
    NewFilterColumnName, {NewFilterColumnName}
), NewFilterColumnName, {NewFilterColumnName}, {NewFilterColumnName}
)
