<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# The dataset status

Since version 2.0.0, drEEM keeps a detailed record of operations it performs on a dataset. To be able to do this meaningful, the toolbox first needs to know some details about your dataset. After that, it can assist as much as possible with doing things properly. And the best thing is that since it knows about your dataset, it can document the dataset details and fully prepare your dataset for an Open Science repository such as Pangaea.

How do we do this? ***With the `drEEMstatus` property.***

It is one one of the properties (i.e. a field in a Matlab structure) of the [`drEEMdataset`](dreemdataset.html) object, so you'll find a status field in each dataset you'll work with.

> **Note:** The status property of each dataset is protected. It can only be changed with the [`changestatus`](changestatus.html) GUI during import or by the appropriate drEEM functions that modify the data and thus need to modify the dataset status. This is to support tracability.

The changestatus GUI looks as follows: 
<img src="changestatus_example.png" width="auto" height="auto" align="justify"/>


The status will give you all the important information on a dataset regarding important processing steps, namely:


<details open>
<summary>
**Spectral Correction:** Have spectral biases of the instrument been compensated?
</summary>

Possible values are:

* unknown
* not applied
* applied by instrument software
* applied by toolbox

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `applied by instrument software`.

</details>

<details open>
<summary>
**Inner-filter effect correction:** Have Inner-filter effects been corrected?
</summary>

Possible values are:

* unknown
* not applied
* applied by instrument software
* applied by toolbox
* deemed unnecessary

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `not applied`.


</details>

<details open>
<summary>
**Blank Subtraction:** Have blanks been subtracted?
</summary>

Possible values are:

* unknown
* not applied
* applied by instrument software
* applied by toolbox

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `not applied`.

</details>

<details open>
<summary>
**Signal Calibration:** Have arbitrary signals been converted, e.g. to Raman Units?
</summary>

Possible values are:

* unknown
* not applied
* applied by instrument software (RU)
* applied by instrument software (QSU)
* applied by toolbox (RU)
* applied by toolbox (QSU)

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `not applied`.

</details>

<details open>
<summary>
**Scatter Treatment:** Has scatter been treated in any way?
</summary>

Possible values are:

* unknown
* not applied
* applied by instrument software
* applied by toolbox

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `not applied`.

</details>

<details open>
<summary>
**Signal Scaling:** Have signals been scaled, e.g. by division with the maximum or sum of fluorescence?
</summary>

This property is not restricted to a set of possibilities since signal scaling comes in many forms.

**Default is `unknown`**, but during [`importeems`](importeems.hmtl), the default value is changed to `orignal scale`.

</details>

<details open>
<summary>
**Absorbance Unit:** In which unit is the absorbanc data stored?
</summary>
Possible values are:

* unknown
* absorbance per cm
* absorbance per 5 cm
* absorbance per 10 cm
* Napierian absorption coefficient
* Linear decadic absorption coefficient

**Default is `unknown`**, but during [`importabsorbance`](importabsorbance.html), the default value is changed to `not applied`.

</details>
