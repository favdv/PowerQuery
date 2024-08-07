/* 
When this function is called, all empty columns (columns that only contain null values) will be removed from the respective table.
In this case a loop is used. 
See also the README.md file in the repository for more information on how to implement this. 
*/

(selectedTable as table) =>
  Table.RemoveColumns(
    selectedTable, List.RemoveNulls( 
      List.Generate(()=>[i=0],each [i]<Table.ColumnCount(selectedTable), each [i=[i]+1], each let i = [i] in 
        if Table.RowCount(Table.SelectRows(selectedTable, each Record.Field(_,Table.ColumnNames(selectedTable){i})<>null)) = 0 
        then Table.ColumnNames(selectedTable){i} 
        else null
      ) 
    )
  )
