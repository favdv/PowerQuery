/* 
When this function is called, all expandable columns are automatically expanded in the respective table.
It is also possible to specify which columns not to expand via the ExcludedCols list.

Iterator i does not need to be provided, unless you want to start expansion from a specific column (e.g. setting it to 1 ignores the first column, 2 ignores the first 2 and so on)
See also the README.md file in the repository for more information on how to implement this. 

Implementation (if the function is called expandAll and the table you want to expand is Table1 with colE and colF to be excluded): 
newStep =expandAll(Table1,{"colE","colF"})

TIP: If you only want to expand specific columns (e.g. you only want to fully expand colE and colF), you could use e.g. 
newStep=expandAll(Table1,List.RemoveItems(Table.ColumnNames(Table1),{"colE","colF"}))

*/

let 
ExpandAllCols = (previousStep as table, optional ExcludedCols as nullable list,optional i as nullable number) => let 
 ExcludedCols = if ExcludedCols = null then {} else ExcludedCols,
 i = if i = null then 0 else i,

 columnCount = Table.ColumnCount(previousStep),
 columnNames = Table.ColumnNames(previousStep),
 processColumn = if i < columnCount then 
 if Table.RowCount(Table.SelectRows(previousStep,each 
  Value.Is(Record.Field(_,columnNames{i}),type list)=true or 
  Value.Is(Record.Field(_,columnNames{i}),type table)=true or 
  Value.Is(Record.Field(_,columnNames{i}),type record)=true)) = 0 or List.Contains(ExcludedCols,columnNames{i}) = true
 then @ExpandAllCols(previousStep,ExcludedCols,i+1)
 else let
 
 #"Expand list" = Table.ExpandListColumn(
   Table.ReplaceValue(
   previousStep,
   each Record.Field(_,columnNames{i}),
   each if Value.Is(Record.Field(_,columnNames{i}),type list)=false and 
    Value.Is(Record.Field(_,columnNames{i}),type table)=false and 
    Record.Field(_,columnNames{i}) <> null
   then {Record.Field(_,columnNames{i})} 
   else Record.Field(_,columnNames{i}) ,Replacer.ReplaceValue,{columnNames{i}}),
  columnNames{i}), 

 #"Expand record" = let convert = Table.ReplaceValue(
   #"Expand list",
   each Record.Field(_,columnNames{i}),
   each if Value.Is(Record.Field(_,columnNames{i}),type record)=false and 
               Record.Field(_,columnNames{i}) <> null
   then [#"_" = Record.Field(_,columnNames{i})] 
   else Record.Field(_,columnNames{i}) ,Replacer.ReplaceValue,{columnNames{i}}) ,
  expandRecords = let 
  //oldRecords = Record.FieldNames( Record.Combine(Table.Column(convert,columnNames{i}))),
  oldRecords = Table.RenameColumns(Table.FromList(
       Record.FieldNames(Record.Combine(
         List.RemoveNulls(
           Table.Column(convert,columnNames{i})
         ))
       ), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "old.name"}}
     ),
  newRecords = Table.AddColumn(oldRecords, "new.name", each if [old.name] = "_" then columnNames{i} else columnNames{i} &"." & [old.name]),
  expandTable = Table.ExpandRecordColumn( convert, columnNames{i}, newRecords[old.name],newRecords[new.name])
  in expandTable
    
  in expandRecords
 in @ExpandAllCols(#"Expand record",ExcludedCols,i) 
 else previousStep 
 in processColumn
in ExpandAllCols
