<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# addcomment
Document an analysis process through comments.

## Syntax

[`dataout = addcomments(data,comment)`](#s1)

[`dataout = addcomments(data,comment,'newline')`](#s2)

## Description
<details open>
<summary><b>
`dataout = addcomments(data,'new comment here')` - add user comment to previous function call</b>
</summary>
<a name="s1"></a> adds a comment to a drEEMdataset that describes an observation, justifies a decision, or documents any other kind of process. The comment field will be stored in the document's history and can be retreived with [`viewistory`](viewhistory.html) and [`displayhistory`](displayhistory.html) and will be exported with [`exportresults`](exportresults.html) and [`export2zip`](export2zip.html). 

By default, the function assumes that a comment is being made on a previous operation, such as noise removal, a PARAFAC fit, or similar. The comment will thus be in the same line and belong to the entry of the as the last function call. This will look as follows:

<img src="addcomment_inline.png" width="auto" height="auto" align="right"/>

As you can see above, the comment is added as a "Comments by user" in history entry number 2, i.e. it "belongs" to that function.

</details>



<details open>
<summary><b>
`dataout = addcomments(data,'new comment here','newline')` - add user comment as independent entry</b>
</summary>
 <a name="s2"></a> 

If you wish to make a comment independent of the last function call, use the `newline` attribute. 

<img src="addcomment_newline.png" width="auto" height="auto" align="right"/>

This will result in the comment being it's own, independent entry in the dataset history. Above your comment shows up as an entry in "details", not under comments by user.

</details>

## Examples
	samples=tbx.addcomment(samples,'Smart thing to say here.')

## Input arguments
<details>
    <summary><b>`data` - dataset to add comment to</b></summary>
    <i>drEEMdataset class</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>

<details open>
    <summary><b>`comment` - descriptive text</b></summary>
    <i>text of the class string or char</i>
        
A text that describes some observation, a concern, a result, a course of action or anything else worthy of documenting.

</details>

## Output arguments
<details>
    <summary><b>`dataout` - dataset with new comment</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

</details>