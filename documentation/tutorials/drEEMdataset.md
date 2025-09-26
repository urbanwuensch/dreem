<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# The drEEMdataset object

Processing of multidimensional data can be a mess. Decisions on how to organize the data need to be made, variable names set, and conventions made. Often, functions don't work as intended because the input they were provided with isn't formatted as expected.

Another problem arises when considering the need for tracability. When loading a dataset, it's not clear what it's status is. Have blanks been subtracted? Who performed the spectral correction (was it even done?)? What about inner-filter effects?

Meet the `drEEMdataset object`!

Starting in drEEM 2, we made the decision to define what's known as a `class` in Matlab notation. We call this the `drEEMdataset`. It has a defined number of properties (i.e. variables). Nothing else is allowed to be added. And anytime a function is called, the dataset get's validated to avoid errors.

You can still manually modify the data of course if you wish to do so! But when you intend to work with drEEM, you must work with datasets of the custom `drEEMdataset` class.

This page aims to show the properties, highlight some ways to work with it, and demonstrate its advantages.

First, let's look at all the properties of the `drEEMdataset`. You can see these by simply calling the class. This results in an empty dataset being created.

	>> drEEMdataset

	ans = 

  	drEEMdataset with properties:

            history: [0×1 drEEMhistory]
                  X: []
                abs: []
        suppSpectra: []
           filelist: {0×1 cell}
                  i: [0×1 double]
                 Ex: [0×1 double]
                 Em: [0×1 double]
                nEx: 0
                nEm: 0
            absWave: [0×1 double]
    suppSpectraAxis: [0×1 double]
            nSample: 0
             models: [0×1 drEEMmodel]
           metadata: [0×0 table]
    opticalMetadata: [0×0 table]
              split: [0×0 drEEMdataset]
             status: [1×1 drEEMstatus]
           userdata: []
     instrumentInfo: [0×0 struct]
    measurementInfo: [0×0 struct]
        toolboxdata: []	

## Properties
You can see above that there are tons of properties (i.e. variables) in the object. Many of these could be familiar from previous use of drEEM or DOMFluor, but many are also new. We will run through them.

* **history**: This is an object of it's own class (sorry to be complicated here). But you don't really need to know much about other than it keeps a memory about the history of the dataset. Every time you call a drEEM function, it creates an entry, saves it's options there, perhaps makes a function message, and stores backups in a few cases. This object gets exported along with the dataset to let everybody know what happened to the dataset. This is also the place where your own comments get stored.
* **X**: The fluorescence dataset (samples x emission x excitation).
* **abs**: The absorbance dataset (samples x absorbance)
* **suppSpectra**: Mostly a placeholder ("supplemental spectra"). You could store other kinds of spectra in here to do some cool stuff like data fusion. For example, mass spectra could go here!
* **filelist**: This is a cell array of characters. The toolbox uses this variable to know what to call your samples. I.e. file names, sample names, sample IDs (whatever you'd call it)
* **i**: The sample identifier. This starts out as a simple vector with as many numbers as you have samples. But when you delete samples, i=2 might disappear from the list. Don't work with indexes, work with .i to avoid ambiguity in your programming. `data.i==2` will always work as intented, `data.X(2,:,:)` will refer to different samples if you change stuff!
* **Ex**: The excitation wavelengths, stored as a column vector. Always stored as increasing numbers.
* **Em**: The emission wavelengths, stored as a column vector. Always stored as increasing numbers.
* **nEx**: The number of excitation wavelengths, stored as an integer. 
* **nEm**: The number of emission wavelengths, stored as an integer. 
* **absWave**: The absorbance wavelengths, stored as a column vector. Always stored as increasing numbers.
* **suppSpectraAxis**: The axis information for the variable `suppSpectra`, stored as a column vector. Not actively used by the drEEM toolbox as of version 2.0.0
* **nSample**: The number of samples. Equal to `size(X,1)` and `size(abs,1)`.
* **models**: Yet another class of it's own. This is where potential PARAFAC models get stored. All of the model's properties are stored in here. No need to know much about it, because you'll access the object with e.g. [viewmodels](viewmodels.html)
* **metadata**: A table containing relevant metadata. Could be anything, temperature, salinity, location, lat/lon, analysis date, sampling date, person handling the samples, replicate #. You name it. The toolbox knows about this table and will offer the data in functions where it's relevant.
* **opticalMetadata**: A table dedicated to Cople peaks ([pickpeaks](pickpeaks.html)) and CDOM absorbance slopes ([fitslopes](fitslopes)). If you want to analyze them, just extract this table from the dataset.
* **split**: Here's where the split datasets will reside when you create them. They are each their own drEEMdataset objects and work in the same way as the parent dataset.
* **status**. This is a read-only variable. It stores the information about the status of the dataset:
		>> drEEMstatus

		ans = 
		
		  drEEMstatus with properties:
		
		    spectralCorrection: "unknown"
		         IFEcorrection: "unknown"
		      blankSubtraction: "unknown"
		     signalCalibration: "unknown"
		      scatterTreatment: "unknown"
		         signalScaling: "unknown"
		        absorbanceUnit: "unknown"
	As you could guess from the names, each of these entries informs the toolbox about the dataset's status in regard to certain aspects. The functions will actually check and stop you from performing something if it makes no sense. The only way to change the status is through calling `drEEMtoolbox.changestatus()`. The GUI will give you valid options and you will have to chose what's appropriate. Any drEEM function that changes the status of the dataset will also change the status object!
	This information will be exported along with the data or PARAFAC results.

* **userdata**. Not maintained by the toolbox and simply a placeholder. You could use this variable as a container for any data you'd want to imagine. It's there for you. If we didn't provide it but you'd want to make it yourself, Matlab would throw an error. Better have it and not need it...
* **instrumentInfo**: An unused placeholder. Room for future developments!
* **toolboxdata**: An unused placeholder. Room for future developments!