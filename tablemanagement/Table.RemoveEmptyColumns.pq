let 
doc = 
  [
    Documentation.Name =  "Remove Empty columns", 
    Documentation.FunctionName =  "Table.RemoveEmptyColumns", 
    Documentation.Description = "All empty columns (columns that only contain null values) will be removed from the respective table.", 
    Documentation.Examples = {
          [
            Description = "Remove Empty Columns",
            Code = "FunctionName(Source)",
            Result = "Only columns with data remain."
          ]
        }
    
  ],
fn = (selectedTable as table) =>
  Table.RemoveColumns(
    selectedTable, List.RemoveNulls( 
      List.Generate(()=>[i=0],each [i]<Table.ColumnCount(selectedTable), each [i=[i]+1], each let i = [i] in 
        if Table.RowCount(Table.SelectRows(selectedTable, each Record.Field(_,Table.ColumnNames(selectedTable){i})<>null)) = 0 
        then Table.ColumnNames(selectedTable){i} 
        else null
      ) 
    )
  )

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
