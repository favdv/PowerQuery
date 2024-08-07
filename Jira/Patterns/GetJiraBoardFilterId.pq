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
    NewFilterColumnName, {"filter"}
), "filter", {"id"}, {NewFilterColumnName}
)
