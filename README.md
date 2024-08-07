# The repository
This repository is used to store snippets of Power Query that other Power BI developers might also find of interest.

Note that some snippets can be copied and used immediately, while others need some minor tweaking for your specific environment. For example: API calls using the Web.Contents function must have the domain hard coded, otherwise auto-refresh will not work.  

# Repo structure
The repository is split between:
- generic functions (as in they can be used for all kinds of scenarios)
- functions and patterns relating specific tools (e.g. retrieving data from tool specific APIs)

## Functions
 Functions can be used without any user amendments and they should work immediately if used properly.

## Patterns
Patterns require some user updating before they can be used. Typical example is functions calling APIs since the Web.Contents function in PowerBi requires the domain to be hardcoded.  

_**Note:** While it might not be obvious that this is needed in PowerBI desktop, the functions are written in a way so it will also ensure auto-refresh works once published._
