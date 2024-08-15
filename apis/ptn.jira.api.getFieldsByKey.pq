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
