let 
functionName = "",
doc = [
    Documentation.Name =  "...", 
    Documentation.Description = "...", 
    Documentation.Examples = {
          [
            Description = "...",
            Code = functionName & "...",
            Result = "..."
          ],
          [
            Description = "...",
            Code = functionName & "...",
            Result = "..."
          ]
        }
    
  ],
  fn = (previousStep as table, ...) => 

//Copy your function here

""

//End of your function  

​ in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
