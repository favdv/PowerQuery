let 
doc = 
  [
    Documentation.Name =  "ConvertBase64", 
    Documentation.FunctionName =  "Table.ConvertBase64", 
    Documentation.Description = "Converts base64 strings to text. Error handling includes invalid base64 strings and handling common binary file types. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace FunctionName with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Replace base64 column values with converted values",
            Code = "FunctionName(Source,""sourceColumn"")",
            Result = "The base64 strings in the ""sourceColumn"" column are replaced with the converted value and the ones that cannot be converted show an error."
          ],
          [
            Description = "Add a new column with converted values",
            Code = "FunctionName(Source,""sourceColumn"",""convertedColumn"")",
            Result = "A new column ""convertedColumn"" is added with the converted value and the ones that cannot be converted show an error. The original ""sourceColumn"" column will not be amended."
          ]
        }
    
  ],
fn = 

(source as table, columnName as text, optional newColumnName as nullable text) as table =>
let
    // Function to check if the base64 string is a known binary file format (image, PDF, DOCX, PPT, RTF, EPUB, etc.)
    GetFileType = (value as text) as text => 
        let
            BinaryData = try Binary.FromText(value, BinaryEncoding.Base64) otherwise null,
            Header = if BinaryData <> null then Binary.ToText(Binary.Range(BinaryData, 0, 8), BinaryEncoding.Base64) else null,
            FileType = if Header <> null then 
                if Text.StartsWith(Header, "iVBORw0KG") then "PNG Image"
                else if Text.StartsWith(Header, "/9j/4AAQ") then "JPEG Image"
                else if Text.StartsWith(Header, "R0lGODdh") or Text.StartsWith(Header, "R0lGODlh") then "GIF Image"
                else if Text.StartsWith(Header, "JVBERi0x") then "PDF File"
                else if Text.StartsWith(Header, "Qk") then "BMP Image"
                else if Text.StartsWith(Header, "SUkqA") or Text.StartsWith(Header, "II*") then "TIFF Image"
                else if Text.StartsWith(Header, "UEsDBBQABg") then "DOCX/XLSX/PPTX/ZIP/EPUB File"
                else if Text.StartsWith(Header, "D0CF11E0A") then "DOC/XLS/PPT File"
                else if Text.StartsWith(Header, "e1xydGY=") then "RTF File"
                else if Text.StartsWith(Header, "/+MYxAAAAAN") then "MP3 Audio"
                else if Text.StartsWith(Header, "AAAAFGZ0") then "MP4 Video"
                else if Text.StartsWith(Header, "UklGRg") then "WAV Audio"
                else "Unknown File"
            else
                "Unknown File"
        in
            FileType,
    ConvertBinaryToText = each try 
        if _ = null then null 
        else 
            let
                FileType = GetFileType(_)
            in
                if FileType <> "Unknown File" then 
                    "Error: Value is a base64 encoded " & FileType & "."
                else 
                    Text.FromBinary(Binary.FromText(_, BinaryEncoding.Base64))
        otherwise "Error: Value could not be converted.",
    // Check if newColumnName is provided
    Result = if newColumnName <> null then
        Table.AddColumn(source, newColumnName, each ConvertBinaryToText(Record.Field(_, columnName)))
    else
        Table.TransformColumns(source, {{columnName, ConvertBinaryToText}})
in
    Result

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
