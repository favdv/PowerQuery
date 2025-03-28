let 
doc = 
  [
    Documentation.Name =  "Auto Expand columns", 
    Documentation.FunctionName = "Table.ExpandAllColumns", 
    Documentation.Description = "All columns will be expanded apart from the columns that are excluded from the respective table.", 
    Documentation.Examples = {
          [
            Description = "Expand all columns",
            Code = "FunctionName(Source)",
            Result = "All columns are expanded."
          ],
          [
            Description = "Expand all columns with exclusions",
            Code = "FunctionName(Source,{""colA"",""colE""})",
            Result = "All columns are expanded apart from columns colA and colE."
          ]
        }
    
  ],
fn = (previousStep as table, optional ExcludedCols as nullable list,optional i as nullable number) => let 
 ExcludedCols = if ExcludedCols = null then {} else ExcludedCols,
 i = if i = null then 0 else i,

 columnCount = Table.ColumnCount(previousStep),
 columnNames = Table.ColumnNames(previousStep),
 processColumn = if i < columnCount then 
 if Table.RowCount(Table.SelectRows(previousStep,each 
  Value.Is(Record.Field(_,columnNames{i}),type list)=true or 
  Value.Is(Record.Field(_,columnNames{i}),type table)=true or 
  Value.Is(Record.Field(_,columnNames{i}),type record)=true)) = 0 or List.Contains(ExcludedCols,columnNames{i}) = true
 then @fn(previousStep,ExcludedCols,i+1)
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
 in @fn(#"Expand record",ExcludedCols,i) 
 else previousStep 
 in processColumn

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
