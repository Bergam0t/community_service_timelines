# Community Service Timelines
This custom PowerBI visual is designed to allow overlapping patient information to be represented visually.

This kind of chart is often referred to as a [Theograph](https://imperialcollegehealthpartners.com/gps-and-commissioners-are-increasingly-interested-in-using-theographs/).

It was originally designed for use in a mental health service in the UK. The visual was used to show open referrals to a mental health service, which can be ongoing for several years. These are represented as coloured boxes, with the individual grey dots representing individual contacts. Additional information about each contact can be viewed by hovering over the contact. Inpatient stays can be included and are then represented as a grey box with a dotted outline.

This was designed to 
- aid in the management of complex cases by showing patterns of engagement that have previously not worked
- improve patient experience by removing the need to explain their story as frequently
- improve clinician efficiency and reduce cognitive load by presenting large amounts of information in a single page (rather than having to read pages of client history on an electronic patient record system

It can be integrated into dashboards designed to aid interrogation of certain patient groups - for example, those with high A&E attendance, or an unusually high number of contacts, or even those with a rapidly escalating period of usage so that intervention can be better managed.

The visual is designed to use a fairly simple set of information that is routinely recorded. 
By combining this with row-based security in PowerBI, it is possible to give access to these records to only those who should be able to view them. 

## Features

### Display contacts that have taken part both as part of an ongoing referral period or as ad-hoc contacts with other services

Grey overlays also give an indicator of the time from referral to first interaction.

Contacts that do not form part of an ongoing referral journey - for example, that involve presentation to emergency departments or calls to an emergency helpline - are shown on their own line, with the relevant service name shown at the far right.

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/afee2fc9-317d-4977-a01f-86947fc28517)

### Interactively zoom in to specific periods of interest

Full interactivity allows zooming in to certain periods of interest on the timeline or by using the quick-access buttons at the top of the screen to jump to predefined time periods. 

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/02d0f825-e11a-44b5-98d7-a7b1459c14df)


### Show inpatient stays alongside community referrals

Inpatient stays have their own distinct row, so the lead-up to historical inpatient stays can be easily interrogated

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/2073c678-5526-4136-afd9-b807e6cfbf0f)


### Distinguish between face-to-face (in-person) and other kinds of contacts

An optional column allows for face-to-face contacts (circles) to be distinguished from other types of contact (crosses). 

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/00213b69-3e0f-409e-91b0-544b7f7e5076)

### Include varied information in interactive tooltips 

By avoiding prescriptiveness in how the tooltip fields need to be structured, we can enable different information to be contained in tooltips for different kinds of services. Processing can take place further upstream, meaning just the relevant information can be exposed at the end.

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/102bd7e6-9ffe-444a-b4ac-b4bcd2324cd0)

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/3959d913-8276-466c-a697-4091f00d51b7)

### Responsively resizes to fit available area

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/b0286b32-1629-4b0d-a8ce-e822e33ea7ad)

![image](https://github.com/Bergam0t/community_service_timelines/assets/29951987/de696a8f-9b77-4416-96b9-158009cd92fc)

### Fully integrated within PowerBI

Being a custom visual powered behind-the-scenes by the R programming language, this visual fully responds to the PowerBI filter visuals, allowing the displayed data to be subsetted to only include certain services of choice.

It can also be combined with features such as row-level security to ensure users can only see the data for patients they should be able to access.

### Flexible 
Due to the flexibility of the data input, it could be used to integrate data across multiple kinds of services to give a holistic feature of a patient's joruney. 

As the required dataset is simple, preprocessing could be used to anonymise the patient journey in some way - for example, 

- by simplifying the name of the service that the patient is being referred to to remove geographical details
- by adjusting start and end dates and exact contact dates
- by minimising the additional information provided within tooltips

In this way, the visual can be easily adapted for both clinical/operational and research purposes. 

### Extensible

Due to the open-source nature of the visual and the use of the common R programming language, it is possible for the visual to be adapted and extended. 

# Proposed future additions
- allowing an event date to be coded in to make exploring before/after impacts of a particular service on a pattern of care easier to do

Please use the 'issues' tab to raise additional feature requests.

# Using the PowerBI custom visual

## Downloading and importing the visual

The PowerBI visual itself can be downloaded from the **dist/** folder.
Save the .pbix file in there to any location on your computer.

The PowerBI custom visual can then be imported into PowerBI using the
option ‘more visuals’ –&gt; ‘From my files’.

![](man/figures/README-example-powerbi-import-custom-visual.png)

## Data format

Example datasets are given in **sample\_datasets/**

A csv template is given in **template\_dataset/**

**COMING SOON**: An additional breakdown of all of the features supported and possible columns will be provided

## Usage in PowerBI

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

The file `script.R` is the key file that controls the plotting logic. 
This plotly code could be extracted and reused in R markdown or an R Shiny dashboard. Alternatively, it could be ported into the Python version of Plotly with some changes to the syntax. 

## How to add additional PowerBI visual formatting options

A full tutorial will follow, but for now this excellent and in-depth
tutorial from Stéphane Laurent will get you started:
<https://laustep.github.io/stlahblog/posts/pbiviz.html#adding-formatting-objects>
