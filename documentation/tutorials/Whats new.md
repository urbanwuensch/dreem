<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# What's new

drEEM version 2 introduces a set of new functionality, workflows, object-oriented programming, visualizations, and graphical user interfaces that aim to make the processing of fluorescence EEMs straightforward for users with limited programming experience. We should not need to be Matlab experts to process fluorescence data.

Please head over to the section [Toolbox setup](dreem_workflow.html) to learn how to work with version 2. If you're used to [DOMFluor](https://doi.org/10.4319/lom.2008.6.572b) or [drEEM 0.1-0.6.x](https://doi.org/10.1039/C3AY41160E), things have changed considerably and there are lots of "breaking changes". But luckly we have tutorials that should help.


<!--<details>
<summary><b>Take a tour of the new toolbox (video on page)</b>
</summary>



 <p align="center">
<div class="responsive-iframe-container">
 <iframe width="80%" height="400" allowfullscreen="true"
src="https://www.youtube.com/embed/N_M8hMbKJFA?autoplay=0&mute=1&hl=en&cc_lang_pref=en&cc_load_policy=1" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</iframe>
</p> 

</details>
-->
## Version 2.25.07


### New features

* Object-oriented programming. `tbx=drEEMtoolbox;` assigns the toolbox to an object, and then you call `tbx.___` to use any function (use the TAB key to get suggestions!)
* A standardized CDOM dataset object called [`drEEMdataset`](dreemdataset.html): A class object that stores fluorescence and absorbance data. Read more in the [documentation](dreemdataset.html)
* Detailed information regarding the status of processing for `drEEMdataset` objects with the  [status property](dreemdataset.html). Loading a dataset from 5 years ago and wondering if IFE corrections had been done? The dataset would tell you from now on.
* [`drEEMhistory`](drEEMhistory.html): A class object that keeps a record of modifications by toolbox functions including their settings, date-time information, and comments if provided. Users can also add comments to the history independent from the toolbox to document the workflow.
* A new PARAFAC engine, courtesy of [Prof. Rasmus Bro](https://scholar.google.com/citations?user=gW_FGdQAAAAJ), that speeds up nonnegative PARAFAC by a factor of 4-5!
* Interactive tool to define scatter treatment options. Read more about [`handlescatter`](handlescatter.html).
* New data export functionalities. Open Science is amazing and we are fully committed to supporting you in this regard!

### General improvements

* Rewrites of all drEEM functions with `arguments` input validation. For the user, this means smart input argument suggestions and quick and helpful input validation. Hitting the tab-key during scripting is extremely helpful from now.
* Entirely new documentation with collapsing sections and nice formatting. The documentation is enriched with videos that walk you through the process.
* Data processing steps are implemented as **standalone** functions. No more custom code for vital standard operations (e.g. raman normalization or IFE correction). This also generally reduces the skills required for Matlab.
* Reduction in Addon Product dependencies. We've done our best to cut down the costly additional Matlab products requirements.
* Renamed functions to help occasional users remember / find functionality. For example, any function that primarily visualizes data starts with `view...` (e.g. `vieweems`)