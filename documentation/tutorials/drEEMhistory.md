<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# The dataset history

Since version 2.0.0, drEEM keeps a detailed record of operations it performs on a dataset. All major operations involved in the processing are fully implemented in methods no matter how simple they theoretically are (e.g. blank subtraction). How does it keep this record?

***With the `drEEMhistory` property!***

It is one one of the properties (i.e. a field in a Matlab structure) of the [`drEEMdataset`](dreemdataset.html) object, so you'll find a history in each dataset you'll work with.

The history will give you basic information on a dataset even if it has been years since you've worked on it. For example, when *did* you last work on it? What *has* actually already been done on it?

Though very helpful in itself, the history gets even more useful in conjunction with the dataset status ([`drEEMstatus`](drEEMstatus.html) object). And the best thing is that you can add information to the history yourself with the [`addcomment` ](addcomment.html) method! 

> ***Remember***: The more information you add to the history when running an analysis, the more reprodicible your workflow will be. For everybody else, but also for yourself when you return to an old dataset.

The idea behind the history is that you need not much know about it; the history is takes care of itself and gets exported with [`export2zip`](export2zip.hmtl) or [`exportresults`](exportresults.html). So it always stays with the dataset, even after an export.

> **Note**: The history is also how the toolbox knows about signal scaling or scatter treatment. Certain methods search the history and use the information stored in it.

The history has a (hidden) property called `details`. Here, the optional input arguments to any function are stored. In this way, you'll always know excactly how the function was applied. Though hidden, [`viewhistory`](viewhistory.html) can restore the details to the workspace and you could apply the same options to another dataset with a tiny bit of work on your end.


The history has a (hidden) property `previous`. Though strickly limited to keep file sizes reasonable, the toolbox uses this functionality when e.g. scaling signals: The unscaled EEMs are kept in as the previous version of the dataset. Any call to [`subdataset`](subdataset.html) or [`zapnoise`](zapnoise.html) will search the `previous` dataset and apply the operation to the unscaled dataset kept in the history. This version of the dataset is then used to reverse the scaling when `scalesamples(data,'reverse')` would be called.




## Properties
You can see above that there are tons of properties (i.e. variables) in the object. Many of these could be familiar from previous use of drEEM or DOMFluor, but many are also new. We will run through them.

* **timestamp**: A date/time stamp marking the time when the function completed its modification on the dataset.
* **fname**: The name of the drEEM function that was modifying the dataset.
* **fmessage**: A short message with basic information about what was done.
* **usercomment**: If you use `addcomment`, this is where your message will be stored. It will be associated with the last function by default since comments often refer to something that the last function was doing (or failed to do). Use `addcomment(data,'___','newline')` to make a separate observation that stands alone by itself and is not associated with another function.

 
# Hidden properties

* **details**: If a function uses name-value pair input arguments or option structures, all of that will be put in here.
* **backup**: Unused. Disabled to reduce dataset size, but theoretically could store backups.
* **previous**: In certain cases (e.g. [`scalesamples`](scalesamples.html)) an unmodified version of the dataset will be stored here. This property is used to then later undo this operation.
