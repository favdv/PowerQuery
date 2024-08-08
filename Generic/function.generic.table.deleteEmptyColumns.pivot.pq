/* 
When this function is called, all empty columns (columns that only contain null values) will be removed from the respective table. 
In this case pivoting is used. 
See also the README.md file in the repository for more information on how to implement this. 
*/

(selectedTable as table) =>
let RemoveColsViaPivot =    
  Table.PromoteHeaders(
    Table.Transpose(Table.RemoveColumns(
      Table.SelectRows(   
        Table.AddColumn(
          Table.Transpose(Table.DemoteHeaders(selectedTable)), 
          "Custom",
           each if List.NonNullCount(Record.ToList(_))<2 then true else false
        ), 
        each [Custom] = false
      ),{"Custom"})), [PromoteAllScalars=true])
in RemoveColsViaPivot
