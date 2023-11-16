# Community Service Timelines
![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/f2284fea-ae37-4f08-80a6-bc2044b12bfa)

# Using the PowerBI custom visual

The PowerBI visual itself can be downloaded from the **dist/** folder.
Save the .pbix file in there to any location on your computer.

The PowerBI custom visual can then be imported into PowerBI using the
option ‘more visuals’ –&gt; ‘From my files’.

![](man/figures/README-example-powerbi-import-custom-visual.png)

At present, the input format is very restrictive and expects **all** of

TO BE COMPLETED

Example datasets are given in **sample\_datasets/**

A csv template is given in **template\_dataset/**

An example PowerBI file is available in **pbi\_example\_file/**

The visual should appear in your list of available visuals. Click on the
icon to add a blank visual to the page. With the visual selected, drag
all fields from your dataset into your ‘values’ section.


# Information for Collaborators

## Key parts of the custom PowerBI visual

| File                     | Function                                                                                                                                                                                                   |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| script.r                 | The main R script that ingests the data then creates and saves the plotly visual. Additional settings specified in settings.ts and capabilities.json will need to be referenced in here to have an effect. |
| pbiviz.json              | Version numbers are updated in here.                                                                                                                                                                       |
| capabilities.json        | Used when adding additional options to the PowerBI visualisation customisation panel                                                                                                                       |
| src/settings.ts          | Used when adding additional options to the PowerBI visualisation customisation panel                                                                                                                       |
| r\_files/flatten\_HTML.r | Helper functions generated automatically by PBI viz tools when using the RHTML template. References by script.r                                                                                            |

## Setting up development environment to build from source

A full tutorial will be written up at a later date.

In the meantime, details on setting up the required packages were
obtained from the following tutorials:

<https://medium.com/@thakurshalabh/create-dynamic-custom-visual-in-power-bi-using-r-ggplot2-and-plotly-4b15a73ef506>

It’s important to note that (as of June 2023) there is an error with the
most recent version of `powerbi-visuals-tools` has a bug that means that
compiled visuals will just render as blank.

Instead, when you reach this step in the tutorial, use the following to
get the most recent working version:

    npm i -g powerbi-visuals-tools@4.0.5

The following page should be consulted to see which versions of R
packages are currently suppported on the PowerBI service.
<https://learn.microsoft.com/en-us/power-bi/connect-data/service-r-packages-support>

## How to tweak the plotly implementation

The file `script.R` is the key file for All underlying files use the

## How to add additional PowerBI visual formatting options

A full tutorial will follow, but for now this excellent and in-depth
tutorial from Stéphane Laurent will get you started:
<https://laustep.github.io/stlahblog/posts/pbiviz.html#adding-formatting-objects>
