(PreviousStep as table, GroupBy as list, optional GroupedColumnName as nullable text)=>
let 
    GroupedColumnName = if GroupedColumnName = null then "tmpGroupedData" else GroupedColumnName 
in 
    Table.ExpandTableColumn(
    Table.TransformColumns(
        Table.TransformColumns(
        Table.Group(
            PreviousStep, 
            GroupBy, 
            {{ GroupedColumnName, each _}}
        ), 
        {GroupedColumnName, 
        each Table.TransformColumnTypes(_, List.Transform(Table.ColumnNames(_), each {_, type text}))
        }
        ), 
        {GroupedColumnName, 
        each Table.FromColumns(
        List.Transform(
            Table.ToColumns(_), 
            each{ Text.Combine(_, ",")}
        ), 
        Table.ColumnNames(_)
        )}
    ), 
    GroupedColumnName, 
    List.RemoveItems(Table.ColumnNames(PreviousStep), GroupBy)
    )
