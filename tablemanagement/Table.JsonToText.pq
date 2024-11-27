let 
doc = [
    Documentation.Name =  "Change Nested Columns to JSON Strings", 
    Documentation.FunctionName = "Table.JsonToText",
    Documentation.Description = 
    "This function converts deep nested columns into strings (e.g. the ADF format from Atlassion). Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace FunctionName with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Convert all columns",
            Code = "FunctionName(Source)",
            Result = "All nested tables, records and lists in the whole table are converted to strings with a JSON representation. All fields that are not lists, records or tables are ignored."
          ],
          [
            Description = "Converting all columns",
            Code = "FunctionName(Source,{""col1"",""col2""})",
            Result = "All nested tables, records and lists for the specified columns (her col1 and col2) are converted to strings with a JSON representation. All fields that are not lists, records or tables are ignored. "
          ]
        }
    
  ],

fn = (previousStep as table, optional columns as nullable list) as table =>
    let
        // Function to check if a value is a nested record or list
        IsNested = (value as any) as logical =>
            if value is record or value is list  or value is table then true else false,
        
        // Get the list of columns to transform
        ColumnsToTransform = if columns = null or List.IsEmpty(columns) then
                                Table.ColumnNames(previousStep)
                             else
                                columns,
        
        // Function to convert a single field from JSON record to JSON string if it is nested
        ConvertField = (value as any) as any =>
            if IsNested(value) then
                Text.FromBinary(Json.FromValue(value), TextEncoding.Utf8)
            else
                value,
        
        // Function to convert a single column from JSON record to JSON string
        ConvertColumn = (tbl as table, col as text) =>
            Table.TransformColumns(tbl, {col, each ConvertField(_), type text}),
        
        // Iterate over the list of columns and apply the conversion function
        Result = List.Accumulate(ColumnsToTransform, previousStep, (state, current) => ConvertColumn(state, current))
    in
        Result
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
