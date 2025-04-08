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
            ],
            [
                Description = "Renaming the columns from a 'Source' Table from the names in a 'Department' column to the names in a 'Central' column using a mapping table in a query, called 'Lookup'. Change the default suffix for reserved words, and add 'Code' to the reserved words list",
                Code = "FunctionName(Source,Lookup,""Department"",""Central"","" (disallowed)"",{""Code""})",
                Result = "The column names that can be renamed are renamed and all columns that are not identified in the mapping table retain their current name. Also replaces the default '(Reserved)' string with '(disallowed)' and an additional reserved word 'COde' is added to support any business rules."
            ],
            [
                Description = "Renaming the columns from a 'Source' Table from the names in a 'Department' column to the names in a 'Central' column using a mapping table in a query, called 'Lookup'. Change the default suffix for reserved words, and add 'Code' to the reserved words list",
                Code = "FunctionName(Source,Lookup,""Department"",""Central"",null,{""Code""})",
                Result = "The column names that can be renamed are renamed and all columns that are not identified in the mapping table retain their current name. Also adds an additional reserved word 'COde' is added to support any business rules, while the reserved word is defaulted."
            ]
        }
    ],
    fn = (previousStep as table, mappingTable as table, columnWithCurrentNames as text, columnWithNewNames as text, optional ReservedText as text, optional ReservedWords as list) =>
let
    //ReservedString
    ReservedText = if ReservedText = null or ReservedText = "" then " (Reserved)" else ReservedText,
        // Default ReservedWordsList logic
    ReservedWords = if ReservedWords = null 
                    then {"SELECT", "TABLE", "WHERE", "FROM", "JOIN"} 
                    else {"SELECT", "TABLE", "WHERE", "FROM", "JOIN"} & ReservedWords,

    // Retrieve column names from the previous table
    PreviousColumnNames = List.Transform(Table.ColumnNames(previousStep), each Text.Lower(_)), // Case-insensitive comparison

    // Function to sanitize column names by removing invalid characters
    SanitizeName = (name) => Text.Remove(Text.From(name), {"[", "]", "{", "}", "#", "."}),

    // Extract and sanitize the column for current names
    CurrentNamesColumnIndex = List.PositionOf(
        List.Transform(Table.ColumnNames(mappingTable), each Text.Contains(Text.Lower(_), Text.Lower(columnWithCurrentNames))),
        true
    ),
    CurrentNames = if CurrentNamesColumnIndex <> -1 
                   then List.Transform(Table.Column(mappingTable, Table.ColumnNames(mappingTable){CurrentNamesColumnIndex}), each Text.Trim(SanitizeName(_))) 
                   else {},

    // Extract and sanitize the column for new names
    NewNamesColumnIndex = List.PositionOf(
        List.Transform(Table.ColumnNames(mappingTable), each Text.Contains(Text.Lower(_), Text.Lower(columnWithNewNames))),
        true
    ),
    NewNames = if NewNamesColumnIndex <> -1 
               then List.Transform(Table.Column(mappingTable, Table.ColumnNames(mappingTable){NewNamesColumnIndex}), each Text.Trim(SanitizeName(_))) 
               else {},

    // Remove duplicates in NewNames by appending an index to duplicates
    UniqueNewNames = List.Accumulate(NewNames, {}, (state, current) =>
        if List.Contains(state, current) 
        then state & {current & "_" & Text.From(List.Count(state))}
        else state & {current}
    ),

    // Reserved words to avoid (example list)
    UniqueNewNamesWithoutReserved = List.Transform(UniqueNewNames, each 
        if List.Contains(List.Transform(ReservedWords, Text.Lower), Text.Lower(_)) then _ & ReservedText else _
    ),
    
    // Map current and new names, filtering out null, empty, or whitespace-only strings
    ValidPairs = List.Select(
        List.Zip({CurrentNames, UniqueNewNamesWithoutReserved}),
        each (_{0} <> null and _{0} <> "" and Text.Trim(_{0}) <> "") and (_{1} <> null and _{1} <> "" and Text.Trim(_{1}) <> "")
    ),

    // Filter to only include pairs where current name exists in previous column names
    FinalPairs = List.Select(ValidPairs, each List.Contains(PreviousColumnNames, Text.Lower(_{0}))),

    // Rename columns in the source table
    RenamedTable = Table.RenameColumns(previousStep, FinalPairs)
in
    RenamedTable
in 
    Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
