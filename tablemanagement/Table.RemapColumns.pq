let 
    doc = [
        Documentation.Name = "Rename Columns based on Mapping Table", 
        Documentation.FunctionName = "Table.RemapColumns",
        Documentation.Description = "This function can be used to rename columns based on a mapping table.", 
        Documentation.Examples = {
            [
                Description = "Renaming the columns from a 'Source' Table from the names in a 'Department' column to the names in a 'Central' column using a mapping table in a query, called 'Lookup'.",
                Code = "FunctionName(Source,Lookup,""Department"",""Central"")",
                Result = "The column names that can be renamed are renamed and all columns that are not identified in the mapping table retain their current name."
            ],
            [
                Description = "Renaming the columns from a 'Source' Table from the names in a 'Department' column to the names in a 'Central' column using a mapping table inline in the function.",
                Code = "FunctionName(Source,Table.FromRecords({[Department=""ID"",Central=""Unique ID""],[Department=""Name"",Central=""New Name""]}),""Department"",""Central"")",
                Result = "The column names that can be renamed are renamed (e.g. a column with the name ID is renamed to Unique ID in this example and similarly Name is renamed to New Name if the column exists) and all columns that are not identified in the mapping table retain their current name."
            ]
        }
    ],
    fn = (previousStep as table, mappingTable as table, columnWithCurrentNames as text, columnWithNewNames as text) =>
let
    // Get the list of column names from the previousStep table
    PreviousColumnNames = Table.ColumnNames(previousStep),

    // Identify the column in the mappingTable that matches the current names (partial match)
    CurrentNames = 
        Table.Column(
            mappingTable, 
            Table.ColumnNames(mappingTable){
                List.PositionOf(
                    List.Transform(
                        Table.ColumnNames(mappingTable), 
                        each Text.Contains(_, columnWithCurrentNames)
                    ), true
                )
            }
        ),
    
    // Identify the column in the mappingTable that matches the new names (partial match)
    NewNames = 
        Table.Column(
            mappingTable, 
            Table.ColumnNames(mappingTable){
                List.PositionOf(
                    List.Transform(
                        Table.ColumnNames(mappingTable), 
                        each Text.Contains(_, columnWithNewNames)
                    ), true
                )
            }
        ),

    // Filter out cases where either CurrentNames or NewNames is null
    ValidPairs = List.Select(
        List.Zip({CurrentNames, NewNames}),
        each _{0} <> null and _{1} <> null
    ),

    // Filter ValidPairs to only include names that exist in PreviousColumnNames
    FinalPairs = List.Select(
        ValidPairs,
        each List.Contains(PreviousColumnNames, _{0})
    ),

    // Apply the renaming
    RenamedTable = Table.RenameColumns(previousStep, FinalPairs)
in
    RenamedTable
in 
    Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
