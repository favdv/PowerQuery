let 
doc = [
    Documentation.Name =  "Change JSON Strings to JSON (nested columns)", 
    Documentation.FunctionName = "Table.TextToJson",
    Documentation.Description = 
    "This function converts JSON strings to deep nested columns.", 
    Documentation.Examples = {
          [
            Description = "Convert all columns",
            Code = "FunctionName(Source)",
            Result = "All strings with a JSON representation in the table are converted to proper JSON. All values that cannot be parsed properly are ignored."
          ],
          [
            Description = "Converting selected columns",
            Code = "FunctionName(Source,{""col1"",""col2""})",
            Result = "All strings with a JSON representation in the specified columns are converted to proper JSON. All values that cannot be parsed properly are ignored."
          ]
        }
    
  ],

fn = (previousStep as table, optional columns as nullable list) as table =>
    let
        // Get the list of columns to transform
        ColumnsToTransform = if columns = null or List.IsEmpty(columns) then
                                Table.ColumnNames(previousStep)
                             else
                                columns,
        
        // Function to parse a single field from JSON string to nested structure if valid
        ParseField = (value as any) as any =>
            if value is text then
                try
                    Json.Document(value)
                otherwise
                    value
            else
                value,
        
        // Function to parse a single column from JSON string to nested structure
        ParseColumn = (tbl as table, col as text) =>
            Table.TransformColumns(tbl, {{col, each ParseField(_), type any}}),
        
        // Iterate over the list of columns and apply the parsing function
        Result = List.Accumulate(ColumnsToTransform, previousStep, (state, current) => ParseColumn(state, current))
    in
        Result
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
