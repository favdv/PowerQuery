/*
This function can be used to extract the domain, the board id and the project id from a JIRA board or backlog url. 
The core input is the table and the column name of the Url's above.
The user can also provide a name for the domain column, board column and project column, which will be created, 
or if not provided, they will be defaulted to "Domain", "Project Ids" and "Board Ids" respectively.
See also the README.md file in the repository for more information on how to implement this. 
*/
(PreviousStep as table, UrlColumn as text, optional DomainColNameToCreate as nullable text, optional ProjectColNameToCreate as nullable text, optional BoardColNameToCreate as nullable text)=>

Table.AddColumn( 
    Table.AddColumn(
        Table.AddColumn( 
            PreviousStep,
            if ProjectColNameToCreate = null then "Project Ids" else ProjectColNameToCreate , 
            each Text.BetweenDelimiters(Text.Replace(Record.Field(_,UrlColumn),"/backlog",""),"/","/",6,0)
        ), 
        if BoardColNameToCreate = null then "Board Ids" else BoardColNameToCreate, 
        each Text.AfterDelimiter(Text.Replace(Record.Field(_,UrlColumn),"/backlog",""), "/", {0, RelativePosition.FromEnd})
    ),
    if DomainColNameToCreate = null then "Domain" else DomainColNameToCreate, 
    each Text.BeforeDelimiter(Record.Field(_,UrlColumn),"/",2)
)
