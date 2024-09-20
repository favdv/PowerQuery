let 
doc = 

  [
    Documentation.Name =  "Split Jira URL", 
    Documentation.FunctionName = "Jira.SplitUrl",
    Documentation.Description = "Extracts the domain, the board id and the project id from a JIRA board or backlog url. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace "&functionName &" with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Using the function with specified column names",
            Code = functionName &"(Source, ""Url"", ""Domain Name"", ""Project Id"", ""Board Id"")",
            Result = "A table with new columns for Domain Name, Project Id, and Board Id extracted from the Url Column."
          ],
          [
            Description = "Using the Split Jira URL function with default column names",
            Code = functionName &"(Source, ""Url"")",
            Result = "A table with new columns for Domain, Project Ids, and Board Ids extracted from the Url Column since the 'to be created' columns are defaulted to these names if not provided."
          ]
        }
    
  ],

fn = 

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
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
