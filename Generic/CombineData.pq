/* 
When this function is called, the data from the table is grouped by the GroupBy list, and all data within the grouped table converted into a single comma-seperated line.
Essentially, this function enables deduplicaiton of a larger dataset (based on the GroupBy list) without losing data. The same number of columns is retained.
Note that all nested columns are converted to text columns.
See also the README.md file in the repository for more information on how to implement this. 
*/

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
