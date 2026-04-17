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
let
    removeCols =
        List.Select(
            Table.ColumnNames(selectedTable),
            (colName) => List.NonNullCount(Table.Column(selectedTable, colName)) = 0
        ),
    result = Table.RemoveColumns(selectedTable, removeCols)
in
    result

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
