/* 
This function is a jira specific pattern, which retrieves the fields based on keys. 

Ensure you modify your domain(s) to suit your specific requirements. 

The source table needs to have a column with the jira domain and one column with the keys either individual or prouped keys. 

The fields to retrieve are to be listed in list format

Assuming the name of the function will be GetJIRAKFields, the table is called Table1 and the column names DomainColumn and KeyColumn respectively, the function can be called via 
newStep = GetJIRAFields(Table1, "DomainColumn","KeyColumn",{"field1","field2"})

If you have stored the field names in a parameter, you can also create the fieldlist via Text.Split(<parameter>,",")

See also the README.md file in the repository for more information on how to implement this. 
*/

(SourceTable as table, Domains as text,keys as text,fieldsToRetrieve as list)=> 
Table.ExpandRecordColumn(
    Table.ExpandListColumn(
        Table.ExpandRecordColumn(
            Table.AddColumn(SourceTable, "keys", each 
                if Record.Field(_,Domains) = "<domain>" 
                then  
                    Json.Document(
                        Web.Contents(
                            "<domain>",
                            [
                                RelativePath = "rest/api/3/search/",
                                Query = [
                                    jql="key IN (" & Record.Field(_,keys) &")", 
                                    fields = Text.Combine( fieldsToRetrieve,","),
                                    expand="renderedFields",
                                    maxResults = 
                                        Text.From(
                                            List.Max( 
                                                Table.AddColumn(
                                                    Table.FromList(Table.Column(SourceTable,keys),Splitter.SplitByNothing(), null, null, ExtraValues.Error), 
                                                    "Custom", 
                                                    each List.Count(Text.Split([Column1],",")))[Custom]
                                            )
                                        ) 
                                ]
                            ]
                        )
                    )
                else null
            ), "keys", {"issues"}
        ), "issues"
    ), "issues", {"key", "renderedFields", "fields"}
)
