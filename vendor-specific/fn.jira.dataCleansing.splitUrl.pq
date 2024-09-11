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
