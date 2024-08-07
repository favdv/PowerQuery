/* 
This function is a jira specific pattern, which retrieves the keys by the domain and project names. 
It does not take board filters into account).

Ensure you modify your domain(s) to suit your specific requirements. 
The source table needs to have a column with the jira domain and one column with the Projects.

Assuming the name of the function will be GetJiraKeysByProject, the table is called Table1 and the column names DomainColumn and ProjectColumn respectively, the function can be called via 
newStep = GetJiraKeysByProject(Table1, "DomainColumn","ProjectColumn")
See also the README.md file in the repository for more information on how to implement this. 
*/

(SourceTable as table, Domains as text, Projects as text)=> 
let
  #"Get Keys" = Table.ExpandRecordColumn(
		  Table.ExpandListColumn(
		    Table.ExpandRecordColumn(
		      Table.AddColumn(SourceTable, "keys", each 
            if Record.Field(_,Domains) = "<your domain>" 
            then Json.Document(
              Web.Contents(
                "<your domain>",
                  [
                    RelativePath = "rest/api/3/search/",
                    Query = [
                      jql="project="&Record.Field(_,Projects),
                      maxResults = "10000" 
                    ]
                  ]
              )
            )
            else null
          ), 
		      "keys", {"issues"}
		    ), "issues"
		  ), 
		  "issues", {"key"}
	  )
in #"Get Keys"
